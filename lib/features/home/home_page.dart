// -----------------------------------------------------------------------------
// 文件：home_page.dart
// 作用：编排首页数据状态、头部、横幅、功能区、抽屉和悬浮入口
// 编写时间：2026-07-10
// 维护说明：具体视觉组件放在 widgets 目录，避免首页成为多人修改热点
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/resources/runtime_resource_manifest.dart';
import '../../routing/app_navigator.dart';
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
    final manifest = RuntimeResourceManifest.defaults();

    return AnimatedBuilder(
      animation: Listenable.merge([
        auth,
        permissions,
        scope.favoriteFeatureController,
      ]),
      builder: (context, _) {
        return Scaffold(
          drawer: HomeDrawer(
            profile: auth.session?.profile,
            brandColor: manifest.brandColor,
          ),
          body: SafeArea(
            child: Stack(
              children: [
                RefreshIndicator(
                  onRefresh: () async {
                    await auth.reloadSessionData();
                  },
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: HomeHeader(
                          brandColor: manifest.brandColor,
                          onProfile: () => AppNavigator.openSecondary(
                            context,
                            AppRoute.profile,
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: HomeBannerCarousel(manifest: manifest),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 22, 18, 34),
                          child: HomeFeatureArea(
                            features: scope.favoriteFeatureController
                                .favoritesFrom(permissions.authorizedFeatures),
                            hasAnyFeature: permissions.allFeatures.isNotEmpty,
                            hasAuthorizedFeature:
                                permissions.authorizedFeatures.isNotEmpty,
                            loadStatus: permissions.status,
                            onRetry: auth.reloadSessionData,
                            iconColor: manifest.iconColor,
                            badgeCountFor:
                                scope.featureBadgeController.countFor,
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
