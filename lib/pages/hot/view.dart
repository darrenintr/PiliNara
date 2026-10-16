import 'package:PiliPlus/common/expressive/expressive_colors.dart';
import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/common/widgets/scaffold/simple_scaffold.dart';
import 'package:PiliPlus/common/widgets/video_card/video_card_h.dart';
import 'package:PiliPlus/common/widgets/view_safe_area.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models/common/home_tab_type.dart';
import 'package:PiliPlus/models/model_hot_video_item.dart';
import 'package:PiliPlus/pages/home/controller.dart';
import 'package:PiliPlus/pages/hot/controller.dart';
import 'package:PiliPlus/pages/home/home_preview_scope.dart';
import 'package:PiliPlus/pages/rank/view.dart';
import 'package:PiliPlus/utils/grid.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class HotPage extends StatefulWidget {
  const HotPage({super.key});

  @override
  State<HotPage> createState() => _HotPageState();
}

class _HotPageState extends State<HotPage>
    with AutomaticKeepAliveClientMixin, GridMixin {
  final HotController controller = Get.put(HotController());

  @override
  bool get wantKeepAlive => true;

  /// Tonal shortcut tile; [accent] picks one of the Expressive accents.
  Widget _buildEntranceItem({
    required IconData icon,
    required String title,
    required int accent,
    required VoidCallback onTap,
  }) {
    final colors = ExpressiveAccent.of(accent, Theme.brightnessOf(context));
    return Expanded(
      child: Material(
        color: colors.container,
        borderRadius: const .all(.circular(Style.radiusXl)),
        child: InkWell(
          onTap: onTap,
          borderRadius: const .all(.circular(Style.radiusXl)),
          child: SizedBox(
            height: 76,
            child: Column(
              spacing: 4,
              mainAxisAlignment: .center,
              children: [
                Icon(icon, color: colors.onContainer),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colors.onContainer,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return refreshIndicator(
      key: HomePreviewScope.of(context) ? null : controller.refreshKey,
      onRefresh: controller.onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        controller: controller.scrollController,
        slivers: [
          if (Pref.showHotRcmd)
            SliverToBoxAdapter(
              child: Padding(
                padding: const .only(left: 16, top: 12, right: 16),
                child: Row(
                  spacing: 8,
                  children: [
                    _buildEntranceItem(
                      icon: Icons.leaderboard_rounded,
                      accent: 1,
                      title: '排行榜',
                      onTap: () {
                        try {
                          final homeController = Get.find<HomeController>();
                          final index = homeController.tabs.indexOf(
                            HomeTabType.rank,
                          );
                          if (index != -1) {
                            homeController.tabController.animateTo(index);
                          } else {
                            Get.to(
                              SimpleScaffold(
                                appBar: AppBar(title: const Text('排行榜')),
                                body: const ViewSafeArea(child: RankPage()),
                              ),
                            );
                          }
                        } catch (_) {}
                      },
                    ),
                    _buildEntranceItem(
                      icon: Icons.calendar_month_rounded,
                      accent: 2,
                      title: '每周必看',
                      onTap: () => Get.toNamed('/popularSeries'),
                    ),
                    _buildEntranceItem(
                      icon: Icons.workspace_premium_rounded,
                      accent: 3,
                      title: '入站必刷',
                      onTap: () => Get.toNamed('/popularPrecious'),
                    ),
                  ],
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.only(top: 7, bottom: 100),
            sliver: Obx(
              () => _buildBody(controller.loadingState.value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(LoadingState<List<HotVideoItemModel>?> loadingState) {
    return switch (loadingState) {
      Loading() => gridSkeleton,
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? SliverGrid.builder(
                gridDelegate: gridDelegate,
                itemBuilder: (context, index) {
                  if (index == response.length - 1) {
                    controller.onLoadMore();
                  }
                  return VideoCardH(
                    videoItem: response[index],
                    onRemove: () => controller.loadingState
                      ..value.data!.removeAt(index)
                      ..refresh(),
                  );
                },
                itemCount: response.length,
              )
            : HttpError(onReload: controller.onReload),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: controller.onReload,
      ),
    };
  }
}
