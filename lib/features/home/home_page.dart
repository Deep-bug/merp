import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../shared/app_error_view.dart';
import 'domain/feature_item.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const brandBlue = Color(0xFF5E93E5);
  static const iconBlue = Color(0xFF16A3DE);
  static const inkText = Color(0xFF2E2F33);

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final auth = scope.authController;
    final permissions = scope.permissionRepository;

    return AnimatedBuilder(
      animation: Listenable.merge([auth, permissions]),
      builder: (context, _) {
        final userName = auth.session?.userName ?? '当前用户';

        return Scaffold(
          drawer: _HomeDrawer(userName: userName),
          body: SafeArea(
            child: Stack(
              children: [
                RefreshIndicator(
                  onRefresh: () async {
                    final session = auth.session;
                    if (session != null) {
                      await permissions.loadForSession(session);
                    }
                  },
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: _HomeHeader(userName: userName),
                      ),
                      const SliverToBoxAdapter(child: _HomeBannerCarousel()),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 22, 18, 34),
                          child: _HomeFeatureArea(
                            features: permissions.features,
                            hasAnyFeature: permissions.allFeatures.isNotEmpty,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Positioned(
                  right: 18,
                  bottom: 18,
                  child: _FloatingAssistantButton(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      color: Colors.white,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 18,
            child: IconButton(
              tooltip: '菜单',
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const Icon(Icons.menu, size: 34),
              color: HomePage.brandBlue,
            ),
          ),
          Text(
            'MERP 2025',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: HomePage.brandBlue,
              fontWeight: FontWeight.w800,
            ),
          ),
          Positioned(
            right: 18,
            child: IconButton(
              tooltip: '个人中心',
              onPressed: () => context.go('/profile'),
              icon: const Icon(Icons.person, size: 34),
              color: HomePage.brandBlue,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeBannerCarousel extends StatefulWidget {
  const _HomeBannerCarousel();

  @override
  State<_HomeBannerCarousel> createState() => _HomeBannerCarouselState();
}

class _HomeBannerCarouselState extends State<_HomeBannerCarousel> {
  static const _slides = [
    _BannerData(
      title: 'MERP 移动工作台',
      subtitle: '旧系统与 Flutter 原生能力并行升级',
      color: Color(0xFF4DA9D7),
      darkColor: Color(0xFF439BC7),
      icon: Icons.qr_code_2,
    ),
    _BannerData(
      title: '外勤管理',
      subtitle: '任务、定位、工单一站处理',
      color: Color(0xFF5BA2E6),
      darkColor: Color(0xFF4489C7),
      icon: Icons.location_on_outlined,
    ),
    _BannerData(
      title: '数据资产',
      subtitle: '客户、设备、盘点统一入口',
      color: Color(0xFF43B7C7),
      darkColor: Color(0xFF3594B8),
      icon: Icons.analytics_outlined,
    ),
  ];

  final _controller = PageController();
  Timer? _timer;
  var _index = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _nextBanner());
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
    _controller.animateToPage(
      (_index + 1) % _slides.length,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 178,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Banner 按真实图片轮播位设计。上线后可以把 _BannerSlide 换成 Image.asset/network。
          PageView.builder(
            controller: _controller,
            itemCount: _slides.length,
            onPageChanged: (value) => setState(() => _index = value),
            itemBuilder: (context, index) => _BannerSlide(data: _slides[index]),
          ),
          Positioned(
            bottom: 14,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(_slides.length, (index) {
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

class _BannerSlide extends StatelessWidget {
  const _BannerSlide({required this.data});

  final _BannerData data;

  @override
  Widget build(BuildContext context) {
    return Container(
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

class _HomeFeatureArea extends StatelessWidget {
  const _HomeFeatureArea({required this.features, required this.hasAnyFeature});

  final List<FeatureItem> features;
  final bool hasAnyFeature;

  @override
  Widget build(BuildContext context) {
    if (features.isEmpty && !hasAnyFeature) {
      return const AppErrorView(
        icon: Icons.apps_outlined,
        title: '暂无可用功能',
        message: '后端没有返回任何功能清单，请确认菜单接口或刷新后重试。',
      );
    }

    // 首页固定 3 列，前 9 个常用功能占前三行，第四行只放“更多”入口。
    final tiles = <Widget>[
      for (final feature in features.take(9)) _FeatureTile(item: feature),
      const _MoreFeatureTile(),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (features.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: AppErrorView(
              icon: Icons.lock_outline,
              tone: AppErrorTone.warning,
              title: '暂无授权功能',
              message: '当前账号暂时没有可打开的常用功能，可进入更多查看全部功能授权状态。',
            ),
          ),
        GridView.builder(
          itemCount: tiles.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 18,
            crossAxisSpacing: 18,
            childAspectRatio: 0.92,
          ),
          itemBuilder: (context, index) => tiles[index],
        ),
      ],
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({required this.item});

  final FeatureItem item;

  void _open(BuildContext context) {
    final permissions = AppScope.of(context).permissionRepository;

    // 点击入口时再次校验权限，避免用户通过缓存页面或伪造菜单直接跳转。
    if (!permissions.canOpen(item)) {
      context.go('/forbidden');
      return;
    }

    if (item.route.trim().isEmpty) {
      _showMissingRouteDialog(context, item.title);
      return;
    }

    context.go(item.route);
  }

  @override
  Widget build(BuildContext context) {
    return _FeatureCard(
      icon: item.icon,
      label: item.title,
      iconColor: HomePage.iconBlue,
      textColor: HomePage.inkText,
      onTap: () => _open(context),
    );
  }
}

class _MoreFeatureTile extends StatelessWidget {
  const _MoreFeatureTile();

  @override
  Widget build(BuildContext context) {
    return _FeatureCard(
      icon: Icons.grid_view_rounded,
      label: '更多',
      iconColor: HomePage.iconBlue,
      textColor: HomePage.inkText,
      onTap: () => context.go('/features'),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.textColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF2F5F8)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF29435C).withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.80),
            blurRadius: 2,
            offset: const Offset(-1, -1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 36, color: iconColor),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _showMissingRouteDialog(BuildContext context, String title) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('功能路由未配置'),
      content: Text('功能“$title”没有配置 route，请联系管理员检查菜单配置。'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('知道了'),
        ),
      ],
    ),
  );
}

class _HomeDrawer extends StatelessWidget {
  const _HomeDrawer({required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    final auth = AppScope.of(context).authController;

    return Drawer(
      width: MediaQuery.sizeOf(context).width * 0.62,
      shape: const RoundedRectangleBorder(),
      backgroundColor: HomePage.brandBlue,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 50, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Align(alignment: Alignment.center, child: _DrawerLogo()),
              const SizedBox(height: 28),
              Text(
                userName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              const _DrawerProfileText('50636863'),
              const SizedBox(height: 10),
              const _DrawerProfileText('资讯部-系统开发II'),
              const SizedBox(height: 8),
              const _DrawerProfileText('finn.lai'),
              const SizedBox(height: 26),
              const _VersionBadge(version: '3.0.2'),
              const SizedBox(height: 72),
              _DrawerAction(
                label: '系统设置',
                icon: Icons.settings_outlined,
                onTap: () {
                  Navigator.of(context).pop();
                  context.go('/settings');
                },
              ),
              const SizedBox(height: 26),
              _DrawerAction(
                label: '登出',
                icon: Icons.logout,
                onTap: () async {
                  await auth.logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerLogo extends StatelessWidget {
  const _DrawerLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 86,
      height: 86,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            color: Colors.black.withValues(alpha: 0.16),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'MERP',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: const Color(0xFF4E5B67),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Icon(Icons.cloud_queue, color: HomePage.iconBlue, size: 30),
        ],
      ),
    );
  }
}

class _DrawerProfileText extends StatelessWidget {
  const _DrawerProfileText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: Colors.white.withValues(alpha: 0.86),
        fontWeight: FontWeight.w400,
      ),
    );
  }
}

class _VersionBadge extends StatelessWidget {
  const _VersionBadge({required this.version});

  final String version;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text.rich(
        TextSpan(
          text: 'Version : ',
          children: [
            TextSpan(
              text: version,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(color: const Color(0xFF30333A)),
      ),
    );
  }
}

class _DrawerAction extends StatelessWidget {
  const _DrawerAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 26),
          const SizedBox(width: 14),
          Text(
            label,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingAssistantButton extends StatelessWidget {
  const _FloatingAssistantButton();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            blurRadius: 16,
            offset: const Offset(0, 8),
            color: Colors.black.withValues(alpha: 0.16),
          ),
        ],
      ),
      child: const Padding(
        padding: EdgeInsets.all(12),
        child: Icon(Icons.smart_toy_outlined, color: HomePage.iconBlue),
      ),
    );
  }
}
