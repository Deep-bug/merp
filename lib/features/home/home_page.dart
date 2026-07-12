// -----------------------------------------------------------------------------
// 文件：home_page.dart
// 作用：编排首页数据状态、头部、横幅、功能区、抽屉和悬浮入口
// 编写时间：2026-07-10
// 维护说明：具体视觉组件放在 widgets 目录，避免首页成为多人修改热点
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../l10n/l10n.dart';
import '../../routing/app_routes.dart';
import 'widgets/home_assistant_button.dart';
import 'widgets/home_banner_carousel.dart';
import 'widgets/home_drawer.dart';
import 'widgets/home_feature_area.dart';
import 'widgets/home_header.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final auth = scope.authController;
    final permissions = scope.permissionRepository;
    final resources = scope.resourceUpdateController;

    return AnimatedBuilder(
      animation: Listenable.merge([auth, permissions, resources]),
      builder: (context, _) {
        final userName = auth.session?.userName ?? context.l10n.currentUser;
        final manifest = resources.manifest;

        return Scaffold(
          drawer: HomeDrawer(
            userName: userName,
            brandColor: manifest.brandColor,
          ),
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
                        child: HomeHeader(
                          brandColor: manifest.brandColor,
                          onProfile: () => context.go(AppRoute.profile),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: HomeBannerCarousel(manifest: manifest),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 22, 18, 34),
                          child: HomeFeatureArea(
                            features: permissions.features,
                            hasAnyFeature: permissions.allFeatures.isNotEmpty,
                            iconColor: manifest.iconColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 18,
                  bottom: 18,
                  child: HomeAssistantButton(iconColor: manifest.iconColor),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
