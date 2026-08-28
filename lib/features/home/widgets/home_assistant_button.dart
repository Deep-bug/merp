// -----------------------------------------------------------------------------
// 文件：home_assistant_button.dart
// 作用：展示首页 AI 助手悬浮入口，并使用本地双帧素材实现轻量眨眼动画
// 编写时间：2026-07-10
// 维护说明：组件只负责动画与点击反馈，不耦合权限、路由或 Vue2 服务
// -----------------------------------------------------------------------------

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 管理悬浮助手在首页可用区域内的拖动、边界限制和左右吸边。
class HomeAssistantOverlay extends StatefulWidget {
  const HomeAssistantOverlay({
    super.key,
    required this.iconColor,
    required this.semanticLabel,
    required this.onTap,
  });

  final Color iconColor;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  State<HomeAssistantOverlay> createState() => _HomeAssistantOverlayState();
}

class _HomeAssistantOverlayState extends State<HomeAssistantOverlay> {
  static const _edgeInset = 10.0;
  static const _defaultBottomInset = 24.0;
  static const _snapDuration = Duration(milliseconds: 220);

  Offset? _position;
  var _isDragging = false;
  int? _activePointer;
  Offset? _pointerOrigin;
  Offset? _positionOrigin;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableSize = Size(constraints.maxWidth, constraints.maxHeight);
        final currentPosition = _boundedPosition(
          _position ?? _defaultPosition(availableSize),
          availableSize,
        );

        return Listener(
          key: const ValueKey('home-assistant-drag-handle'),
          behavior: HitTestBehavior.deferToChild,
          onPointerDown: (event) {
            if (_activePointer != null) return;
            _activePointer = event.pointer;
            _pointerOrigin = event.position;
            _positionOrigin = currentPosition;
          },
          onPointerMove: (event) {
            if (event.pointer != _activePointer ||
                _pointerOrigin == null ||
                _positionOrigin == null) {
              return;
            }
            final dragDelta = event.position - _pointerOrigin!;
            // 小范围移动继续按点击处理，超过阈值才进入拖拽状态。
            if (!_isDragging && dragDelta.distanceSquared < 36) return;
            setState(() {
              _isDragging = true;
              _position = _boundedPosition(
                _positionOrigin! + dragDelta,
                availableSize,
              );
            });
          },
          onPointerUp: (event) {
            if (event.pointer != _activePointer) return;
            _finishPointer(availableSize);
          },
          onPointerCancel: (event) {
            if (event.pointer != _activePointer) return;
            _finishPointer(availableSize);
          },
          child: Stack(
            children: [
              AnimatedPositioned(
                left: currentPosition.dx,
                top: currentPosition.dy,
                duration: _isDragging ? Duration.zero : _snapDuration,
                curve: Curves.easeOutCubic,
                child: HomeAssistantButton(
                  iconColor: widget.iconColor,
                  semanticLabel: widget.semanticLabel,
                  onTap: widget.onTap,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Offset _defaultPosition(Size availableSize) {
    return Offset(
      availableSize.width - HomeAssistantButton.diameter - _edgeInset,
      availableSize.height - HomeAssistantButton.diameter - _defaultBottomInset,
    );
  }

  Offset _boundedPosition(Offset position, Size availableSize) {
    final maxX = math.max(
      _edgeInset,
      availableSize.width - HomeAssistantButton.diameter - _edgeInset,
    );
    final maxY = math.max(
      _edgeInset,
      availableSize.height - HomeAssistantButton.diameter - _edgeInset,
    );
    return Offset(
      position.dx.clamp(_edgeInset, maxX).toDouble(),
      position.dy.clamp(_edgeInset, maxY).toDouble(),
    );
  }

  void _snapToNearestEdge(Size availableSize) {
    final current = _boundedPosition(
      _position ?? _defaultPosition(availableSize),
      availableSize,
    );
    final maxX = math.max(
      _edgeInset,
      availableSize.width - HomeAssistantButton.diameter - _edgeInset,
    );
    final assistantCenterX = current.dx + HomeAssistantButton.diameter / 2;
    final targetX = assistantCenterX <= availableSize.width / 2
        ? _edgeInset
        : maxX;
    setState(() {
      _position = Offset(targetX, current.dy);
      _isDragging = false;
    });
  }

  void _finishPointer(Size availableSize) {
    final shouldSnap = _isDragging;
    _activePointer = null;
    _pointerOrigin = null;
    _positionOrigin = null;
    if (shouldSnap) {
      _snapToNearestEdge(availableSize);
    }
  }
}

class HomeAssistantButton extends StatefulWidget {
  const HomeAssistantButton({
    super.key,
    required this.iconColor,
    required this.semanticLabel,
    required this.onTap,
  });

  final Color iconColor;
  final String semanticLabel;
  final VoidCallback onTap;

  static const diameter = 76.0;

  @override
  State<HomeAssistantButton> createState() => _HomeAssistantButtonState();
}

class _HomeAssistantButtonState extends State<HomeAssistantButton> {
  static const _openEyesAsset = 'assets/images/assistant/robot_eye_open.png';
  static const _closedEyesAsset =
      'assets/images/assistant/robot_eye_closed.png';
  static const _timeBetweenBlinks = Duration(milliseconds: 2800);
  static const _blinkDuration = Duration(milliseconds: 160);

  Timer? _nextBlinkTimer;
  Timer? _openEyesTimer;
  var _eyesClosed = false;
  var _assetsPrecached = false;

  @override
  void initState() {
    super.initState();
    _scheduleNextBlink();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_assetsPrecached) return;
    _assetsPrecached = true;
    // 两帧提前解码，避免第一次眨眼时因读取资源产生短暂停顿。
    unawaited(precacheImage(const AssetImage(_openEyesAsset), context));
    unawaited(precacheImage(const AssetImage(_closedEyesAsset), context));
  }

  void _scheduleNextBlink() {
    _nextBlinkTimer?.cancel();
    _nextBlinkTimer = Timer(_timeBetweenBlinks, _blink);
  }

  void _blink() {
    if (!mounted) return;
    setState(() => _eyesClosed = true);
    _openEyesTimer?.cancel();
    _openEyesTimer = Timer(_blinkDuration, () {
      if (!mounted) return;
      setState(() => _eyesClosed = false);
      _scheduleNextBlink();
    });
  }

  @override
  void dispose() {
    _nextBlinkTimer?.cancel();
    _openEyesTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: Tooltip(
        message: widget.semanticLabel,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                blurRadius: 18,
                offset: const Offset(0, 8),
                color: const Color(0xFF29435C).withValues(alpha: 0.2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkResponse(
              onTap: widget.onTap,
              radius: 40,
              child: SizedBox.square(
                dimension: HomeAssistantButton.diameter,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 90),
                    reverseDuration: const Duration(milliseconds: 70),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: Image.asset(
                      _eyesClosed ? _closedEyesAsset : _openEyesAsset,
                      key: ValueKey(_eyesClosed),
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.medium,
                      gaplessPlayback: true,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.smart_toy_outlined,
                        color: widget.iconColor,
                        size: 36,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
