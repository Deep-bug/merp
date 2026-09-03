// -----------------------------------------------------------------------------
// 文件：home_banner_carousel.dart
// 作用：展示首页 PNG 横幅并以低频定时器自动轮播
// 编写时间：2026-07-10
// 维护说明：图片固定放在 assets/images/home_banners，缺图时回退旧横幅
// -----------------------------------------------------------------------------

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/resources/runtime_resource_manifest.dart';
import '../../../l10n/l10n.dart';

const _defaultHomeBannerAssets = <String>[
  'assets/images/home_banners/banner_01.png',
  'assets/images/home_banners/banner_02.png',
  'assets/images/home_banners/banner_03.png',
];

class HomeBannerCarousel extends StatefulWidget {
  const HomeBannerCarousel({
    super.key,
    required this.manifest,
    this.bannerAssets = _defaultHomeBannerAssets,
  });

  final RuntimeResourceManifest manifest;
  final List<String> bannerAssets;

  @override
  State<HomeBannerCarousel> createState() => _HomeBannerCarouselState();
}

class _HomeBannerCarouselState extends State<HomeBannerCarousel> {
  final PageController _controller = PageController();
  Timer? _timer;
  var _index = 0;
  var _didResolveAssets = false;
  List<String> _availableBannerAssets = const [];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _nextBanner());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didResolveAssets) return;
    _didResolveAssets = true;
    _resolveBannerAssets();
  }

  Future<void> _resolveBannerAssets() async {
    final manifest = await AssetManifest.loadFromAssetBundle(
      DefaultAssetBundle.of(context),
    );
    final available = widget.bannerAssets
        .where(manifest.listAssets().contains)
        .toList(growable: false);
    if (!mounted) return;
    setState(() => _availableBannerAssets = available);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _nextBanner() {
    if (!mounted || !_controller.hasClients) {
      return;
    }
    final itemCount = _availableBannerAssets.isEmpty
        ? 3
        : _availableBannerAssets.length;
    if (itemCount < 2) return;
    _controller.animateToPage(
      (_index + 1) % itemCount,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final slides = <_BannerData>[
      _BannerData(
        title: widget.manifest.bannerTitle,
        subtitle: widget.manifest.bannerSubtitle,
        color: widget.manifest.bannerColor,
        darkColor: widget.manifest.bannerDarkColor,
        icon: Icons.qr_code_2,
      ),
      _BannerData(
        title: context.l10n.fieldWork,
        subtitle: context.l10n.fieldWorkSubtitle,
        color: const Color(0xFF5BA2E6),
        darkColor: const Color(0xFF4489C7),
        icon: Icons.location_on_outlined,
      ),
      _BannerData(
        title: context.l10n.dataAssets,
        subtitle: context.l10n.dataAssetsSubtitle,
        color: const Color(0xFF43B7C7),
        darkColor: const Color(0xFF3594B8),
        icon: Icons.analytics_outlined,
      ),
    ];
    final itemCount = _availableBannerAssets.isEmpty
        ? slides.length
        : _availableBannerAssets.length;

    return SizedBox(
      height: 178,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: itemCount,
            onPageChanged: (value) => setState(() => _index = value),
            itemBuilder: (context, index) => _availableBannerAssets.isEmpty
                ? _BannerSlide(data: slides[index])
                : _PngBannerSlide(assetPath: _availableBannerAssets[index]),
          ),
          Positioned(
            bottom: 14,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(itemCount, (index) {
                final active = index == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: active ? 18 : 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: active ? 1 : 0.55),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _PngBannerSlide extends StatelessWidget {
  const _PngBannerSlide({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: double.infinity,
      height: double.infinity,
      // 产品要求保持现有轮播高度并完全铺满，因此不裁剪图片。
      fit: BoxFit.fill,
      filterQuality: FilterQuality.medium,
      excludeFromSemantics: true,
    );
  }
}

class _BannerSlide extends StatelessWidget {
  const _BannerSlide({required this.data});

  final _BannerData data;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: data.color,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 48,
            child: ColoredBox(color: data.darkColor),
          ),
          Positioned(
            left: 28,
            top: 22,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  data.subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.84),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: const Alignment(0.38, 0.06),
            child: _DeviceIllustration(icon: data.icon),
          ),
          const Positioned(
            left: 20,
            bottom: 36,
            child: _RoundBannerIcon(
              icon: Icons.groups,
              color: Color(0xFFFFB32C),
            ),
          ),
          const Positioned(
            right: 34,
            bottom: 50,
            child: _RoundBannerIcon(
              icon: Icons.work_outline,
              color: Color(0xFFFF7A2F),
            ),
          ),
          const Positioned(
            right: 74,
            top: 46,
            child: _RoundBannerIcon(
              icon: Icons.language,
              color: Color(0xFF8ED1D1),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceIllustration extends StatelessWidget {
  const _DeviceIllustration({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 154,
      height: 112,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 0,
            child: Container(
              width: 150,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFFE9EEF3),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          Container(
            width: 104,
            height: 82,
            decoration: BoxDecoration(
              color: const Color(0xFF1E242B),
              border: Border.all(color: const Color(0xFFCBD5DF), width: 8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 48),
          ),
        ],
      ),
    );
  }
}

class _RoundBannerIcon extends StatelessWidget {
  const _RoundBannerIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: color,
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }
}

class _BannerData {
  const _BannerData({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.darkColor,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final Color color;
  final Color darkColor;
  final IconData icon;
}
