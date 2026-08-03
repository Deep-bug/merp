// -----------------------------------------------------------------------------
// 文件：smooth_reorderable_grid.dart
// 作用：提供支持平滑换位、边缘滚动、吸附和越界恢复的通用拖拽网格
// 维护说明：这里只处理拖拽交互，不依赖 FeatureItem、收藏状态等具体业务
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../adaptive_feature_grid.dart';

typedef SmoothReorderItemBuilder<T> =
    Widget Function(BuildContext context, T item);

typedef SmoothReorderCallback =
    Future<void> Function(List<String> originalIds, int oldIndex, int newIndex);

/// 可以横向、纵向平滑换位的通用功能方块网格。
///
/// 调用方只需要提供数据、唯一 ID 和卡片外观；网格内部统一管理拖拽状态、
/// 换位动画、边缘自动滚动、松手吸附，以及拖出网格后的顺序恢复。
class SmoothReorderableGrid<T extends Object> extends StatefulWidget {
  const SmoothReorderableGrid({
    super.key,
    required this.items,
    required this.itemId,
    required this.itemBuilder,
    required this.metrics,
    required this.onReorder,
    this.dragDelay = const Duration(milliseconds: 220),
    this.topAutoScrollInset = 93,
  });

  final List<T> items;
  final String Function(T item) itemId;
  final SmoothReorderItemBuilder<T> itemBuilder;
  final AdaptiveFeatureGridMetrics metrics;
  final SmoothReorderCallback onReorder;

  /// 长按多久后开始拖动。
  final Duration dragDelay;

  /// 屏幕顶部不会被内容覆盖的高度，例如固定导航栏高度。
  final double topAutoScrollInset;

  @override
  State<SmoothReorderableGrid<T>> createState() =>
      _SmoothReorderableGridState<T>();
}

class _SmoothReorderableGridState<T extends Object>
    extends State<SmoothReorderableGrid<T>>
    with TickerProviderStateMixin {
  static const _positionAnimationDuration = Duration(milliseconds: 190);
  static const _positionAnimationCurve = Curves.easeOutCubic;
  static const _dropAnimationDuration = Duration(milliseconds: 180);
  static const _reorderHysteresis = 12.0;
  static const _dropBoundaryPadding = 36.0;
  static const _edgeAutoScrollExtent = 72.0;
  static const _minAutoScrollVelocity = 120.0;
  static const _maxAutoScrollVelocity = 720.0;

  final GlobalKey _gridKey = GlobalKey();
  late List<T> _displayItems;
  late final Ticker _autoScrollTicker;
  List<String> _originalIds = const [];
  String? _draggedId;
  String? _droppingId;
  Offset? _lastReorderLocalPosition;
  Offset? _latestDragGlobalPosition;
  double? _activeDragWidth;
  Duration? _lastAutoScrollElapsed;
  double _autoScrollVelocity = 0;
  AnimationController? _dropAnimationController;
  OverlayEntry? _dropOverlayEntry;

  @override
  void initState() {
    super.initState();
    _displayItems = List.of(widget.items);
    _autoScrollTicker = createTicker(_handleAutoScrollTick);
  }

  @override
  void dispose() {
    _autoScrollTicker.dispose();
    _dropOverlayEntry?.remove();
    _dropOverlayEntry = null;
    _dropAnimationController?.dispose();
    _dropAnimationController = null;
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SmoothReorderableGrid<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_draggedId == null) {
      _displayItems = List.of(widget.items);
    }
  }

  void _startDrag(String id) {
    setState(() {
      _draggedId = id;
      _originalIds = widget.items.map(widget.itemId).toList(growable: false);
      _displayItems = List.of(widget.items);
      _lastReorderLocalPosition = null;
      _latestDragGlobalPosition = null;
    });
  }

  void _updateDragPosition(DragUpdateDetails details, double availableWidth) {
    _latestDragGlobalPosition = details.globalPosition;
    _activeDragWidth = availableWidth;
    _updateReorderForGlobalPosition(details.globalPosition, availableWidth);
    _updateAutoScrollVelocity(details.globalPosition);
  }

  void _updateReorderForGlobalPosition(
    Offset globalPosition,
    double availableWidth,
  ) {
    final draggedId = _draggedId;
    final gridContext = _gridKey.currentContext;
    if (draggedId == null || gridContext == null) return;
    final renderObject = gridContext.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;

    final localPosition = renderObject.globalToLocal(globalPosition);
    final targetIndex = widget.metrics.nearestIndexForPosition(
      localPosition: localPosition,
      availableWidth: availableWidth,
      itemCount: _displayItems.length,
    );
    final oldIndex = _displayItems.indexWhere(
      (item) => widget.itemId(item) == draggedId,
    );
    if (oldIndex < 0 || targetIndex < 0 || oldIndex == targetIndex) return;

    final lastPosition = _lastReorderLocalPosition;
    if (lastPosition != null &&
        (localPosition - lastPosition).distance < _reorderHysteresis) {
      return;
    }

    setState(() {
      final movedItem = _displayItems.removeAt(oldIndex);
      _displayItems.insert(targetIndex, movedItem);
      _lastReorderLocalPosition = localPosition;
    });
  }

  void _updateAutoScrollVelocity(Offset globalPosition) {
    if (!mounted || _draggedId == null) return;
    final mediaQuery = MediaQuery.of(context);
    final topBoundary =
        mediaQuery.padding.top +
        widget.topAutoScrollInset +
        _edgeAutoScrollExtent;
    final bottomBoundary =
        mediaQuery.size.height -
        mediaQuery.padding.bottom -
        _edgeAutoScrollExtent;

    var velocity = 0.0;
    if (globalPosition.dy < topBoundary) {
      final intensity =
          ((topBoundary - globalPosition.dy) / _edgeAutoScrollExtent).clamp(
            0.0,
            1.0,
          );
      velocity =
          -(_minAutoScrollVelocity +
              (_maxAutoScrollVelocity - _minAutoScrollVelocity) * intensity);
    } else if (globalPosition.dy > bottomBoundary) {
      final intensity =
          ((globalPosition.dy - bottomBoundary) / _edgeAutoScrollExtent).clamp(
            0.0,
            1.0,
          );
      velocity =
          _minAutoScrollVelocity +
          (_maxAutoScrollVelocity - _minAutoScrollVelocity) * intensity;
    }

    _autoScrollVelocity = velocity;
    if (velocity == 0) {
      _stopAutoScroll();
    } else if (!_autoScrollTicker.isActive) {
      _lastAutoScrollElapsed = null;
      _autoScrollTicker.start();
    }
  }

  void _handleAutoScrollTick(Duration elapsed) {
    if (!mounted || _draggedId == null || _autoScrollVelocity == 0) {
      _stopAutoScroll();
      return;
    }

    final previousElapsed = _lastAutoScrollElapsed;
    _lastAutoScrollElapsed = elapsed;
    if (previousElapsed == null) return;

    final scrollable = Scrollable.maybeOf(context);
    if (scrollable == null || !scrollable.position.hasContentDimensions) {
      _stopAutoScroll();
      return;
    }

    final elapsedSeconds =
        ((elapsed - previousElapsed).inMicroseconds /
                Duration.microsecondsPerSecond)
            .clamp(0.0, 0.05);
    final position = scrollable.position;
    final targetPixels =
        (position.pixels + _autoScrollVelocity * elapsedSeconds)
            .clamp(position.minScrollExtent, position.maxScrollExtent)
            .toDouble();
    if ((targetPixels - position.pixels).abs() < 0.01) {
      _stopAutoScroll();
      return;
    }

    position.jumpTo(targetPixels);

    // 页面滚动时，即使手指保持不动，手指在网格内对应的位置也在变化。
    final pointer = _latestDragGlobalPosition;
    final width = _activeDragWidth;
    if (pointer != null && width != null) {
      _updateReorderForGlobalPosition(pointer, width);
    }
  }

  void _stopAutoScroll() {
    _autoScrollVelocity = 0;
    _lastAutoScrollElapsed = null;
    if (_autoScrollTicker.isActive) {
      _autoScrollTicker.stop();
    }
  }

  bool _isDropInsideGrid(Offset globalPosition) {
    final gridContext = _gridKey.currentContext;
    if (gridContext == null) return false;
    final renderObject = gridContext.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return false;
    final localPosition = renderObject.globalToLocal(globalPosition);
    final acceptedBounds = (Offset.zero & renderObject.size).inflate(
      _dropBoundaryPadding,
    );
    return acceptedBounds.contains(localPosition);
  }

  List<T> _itemsInOriginalOrder() {
    final itemsById = {
      for (final item in _displayItems) widget.itemId(item): item,
    };
    final restored = <T>[for (final id in _originalIds) ?itemsById[id]];
    final originalIdSet = _originalIds.toSet();
    restored.addAll(
      _displayItems.where(
        (item) => !originalIdSet.contains(widget.itemId(item)),
      ),
    );
    return restored;
  }

  Offset? _targetGlobalOffset({
    required int index,
    required double availableWidth,
  }) {
    final gridContext = _gridKey.currentContext;
    if (gridContext == null || index < 0) return null;
    final renderObject = gridContext.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;
    final metrics = widget.metrics;
    final tileWidth =
        (availableWidth - metrics.spacing * (metrics.crossAxisCount - 1)) /
        metrics.crossAxisCount;
    final column = index % metrics.crossAxisCount;
    final row = index ~/ metrics.crossAxisCount;
    return renderObject.localToGlobal(
      Offset(
        column * (tileWidth + metrics.spacing),
        row * (metrics.mainAxisExtent + metrics.spacing),
      ),
    );
  }

  Future<void> _finishDrag(
    DraggableDetails details,
    T item,
    double availableWidth,
  ) async {
    final draggedId = _draggedId;
    if (draggedId == null) return;
    _stopAutoScroll();

    final metrics = widget.metrics;
    final tileWidth =
        (availableWidth - metrics.spacing * (metrics.crossAxisCount - 1)) /
        metrics.crossAxisCount;
    final pointerPosition =
        _latestDragGlobalPosition ??
        details.offset + Offset(tileWidth / 2, metrics.mainAxisExtent / 2);
    final shouldRestore = !_isDropInsideGrid(pointerPosition);
    final oldIndex = _originalIds.indexOf(draggedId);
    if (shouldRestore) {
      _displayItems = _itemsInOriginalOrder();
    }
    final newIndex = _displayItems.indexWhere(
      (displayItem) => widget.itemId(displayItem) == draggedId,
    );
    final shouldSave =
        !shouldRestore &&
        oldIndex >= 0 &&
        newIndex >= 0 &&
        oldIndex != newIndex;
    final targetOffset = _targetGlobalOffset(
      index: newIndex,
      availableWidth: availableWidth,
    );

    if (mounted) {
      setState(() {
        _draggedId = null;
        _droppingId = draggedId;
        _lastReorderLocalPosition = null;
        _latestDragGlobalPosition = null;
        _activeDragWidth = null;
      });
    } else {
      _draggedId = null;
      return;
    }

    if (targetOffset != null) {
      await _animateDrop(
        item: item,
        beginGlobalOffset: details.offset,
        endGlobalOffset: targetOffset,
        width: tileWidth,
        height: metrics.mainAxisExtent,
      );
    }

    if (mounted && _droppingId == draggedId) {
      setState(() => _droppingId = null);
    }
    if (shouldSave) {
      await widget.onReorder(_originalIds, oldIndex, newIndex);
    }
  }

  Future<void> _animateDrop({
    required T item,
    required Offset beginGlobalOffset,
    required Offset endGlobalOffset,
    required double width,
    required double height,
  }) async {
    if (!mounted) return;
    _dropOverlayEntry?.remove();
    _dropOverlayEntry = null;
    _dropAnimationController?.dispose();
    _dropAnimationController = null;

    final overlay = Overlay.of(context, rootOverlay: true);
    final overlayRenderObject = overlay.context.findRenderObject();
    if (overlayRenderObject is! RenderBox) return;

    final begin = overlayRenderObject.globalToLocal(beginGlobalOffset);
    final end = overlayRenderObject.globalToLocal(endGlobalOffset);
    final theme = Theme.of(context);
    final controller = AnimationController(
      vsync: this,
      duration: _dropAnimationDuration,
    );
    final animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutCubic,
    );
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final offset = Offset.lerp(begin, end, animation.value)!;
          return Positioned(
            left: offset.dx,
            top: offset.dy,
            width: width,
            height: height,
            child: IgnorePointer(
              child: Transform.scale(
                scale: 1.06 - 0.06 * animation.value,
                child: Material(
                  color: Colors.transparent,
                  elevation: 16 * (1 - animation.value),
                  shadowColor: Colors.black.withValues(alpha: 0.24),
                  borderRadius: BorderRadius.circular(8),
                  child: Theme(data: theme, child: child!),
                ),
              ),
            ),
          );
        },
        child: widget.itemBuilder(context, item),
      ),
    );
    _dropAnimationController = controller;
    _dropOverlayEntry = entry;
    overlay.insert(entry);

    try {
      await controller.forward().orCancel;
    } on TickerCanceled {
      // 页面退出或下一次拖动开始时，旧吸附动画可以安全结束。
    } finally {
      if (_dropOverlayEntry == entry) {
        entry.remove();
        _dropOverlayEntry = null;
      }
      if (_dropAnimationController == controller) {
        controller.dispose();
        _dropAnimationController = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_displayItems.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = widget.metrics;
        final tileWidth =
            (constraints.maxWidth -
                metrics.spacing * (metrics.crossAxisCount - 1)) /
            metrics.crossAxisCount;
        final rowCount =
            (_displayItems.length + metrics.crossAxisCount - 1) ~/
            metrics.crossAxisCount;
        final gridHeight =
            rowCount * metrics.mainAxisExtent +
            (rowCount - 1) * metrics.spacing;

        return SizedBox(
          key: _gridKey,
          width: constraints.maxWidth,
          height: gridHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: List.generate(_displayItems.length, (index) {
              final item = _displayItems[index];
              final itemId = widget.itemId(item);
              final isDragging = itemId == _draggedId;
              final isDropping = itemId == _droppingId;
              final column = index % metrics.crossAxisCount;
              final row = index ~/ metrics.crossAxisCount;
              final left = column * (tileWidth + metrics.spacing);
              final top = row * (metrics.mainAxisExtent + metrics.spacing);
              final card = widget.itemBuilder(context, item);

              return AnimatedPositioned(
                key: ValueKey(itemId),
                left: left,
                top: top,
                width: tileWidth,
                height: metrics.mainAxisExtent,
                duration: _positionAnimationDuration,
                curve: _positionAnimationCurve,
                child: RepaintBoundary(
                  child: AnimatedOpacity(
                    opacity: isDropping ? 0 : 1,
                    duration: const Duration(milliseconds: 60),
                    child: LongPressDraggable<String>(
                      data: itemId,
                      delay: widget.dragDelay,
                      maxSimultaneousDrags: _droppingId == null ? 1 : 0,
                      hapticFeedbackOnStart: true,
                      onDragStarted: () => _startDrag(itemId),
                      onDragUpdate: (details) =>
                          _updateDragPosition(details, constraints.maxWidth),
                      onDragEnd: (details) {
                        _finishDrag(details, item, constraints.maxWidth);
                      },
                      feedback: Theme(
                        data: Theme.of(context),
                        child: Material(
                          color: Colors.transparent,
                          elevation: 16,
                          shadowColor: Colors.black.withValues(alpha: 0.24),
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: tileWidth,
                            height: metrics.mainAxisExtent,
                            child: Transform.scale(scale: 1.06, child: card),
                          ),
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.16,
                        child: Transform.scale(scale: 0.96, child: card),
                      ),
                      child: AnimatedScale(
                        scale: isDragging ? 0.96 : 1,
                        duration: const Duration(milliseconds: 120),
                        child: card,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
