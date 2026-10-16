import 'dart:async';

import 'package:PiliPlus/common/assets.dart';
import 'package:PiliPlus/common/expressive/expressive_colors.dart';
import 'package:PiliPlus/common/expressive/expressive_shapes.dart';
import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models/common/mine_card_type.dart';
import 'package:PiliPlus/models/common/nav_bar_config.dart';
import 'package:PiliPlus/models_new/fav/fav_folder/list.dart';
import 'package:PiliPlus/models_new/later/list.dart';
import 'package:PiliPlus/pages/common/common_page.dart';
import 'package:PiliPlus/pages/home/view.dart';
import 'package:PiliPlus/pages/login/controller.dart';
import 'package:PiliPlus/pages/main/controller.dart';
import 'package:PiliPlus/pages/mine/controller.dart';
import 'package:PiliPlus/pages/mine/widgets/history_card_item.dart';
import 'package:PiliPlus/pages/mine/widgets/item.dart';
import 'package:PiliPlus/pages/mine/widgets/to_view_card_item.dart';
import 'package:PiliPlus/utils/bili_utils.dart';
import 'package:PiliPlus/utils/extension/get_ext.dart';
import 'package:PiliPlus/utils/extension/num_ext.dart';
import 'package:PiliPlus/utils/extension/theme_ext.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:material_ui/material_ui.dart';

class MinePage extends StatefulWidget {
  const MinePage({super.key, this.showBackBtn = false});

  final bool showBackBtn;

  @override
  State<MinePage> createState() => _MediaPageState();
}

class _MediaPageState extends CommonPageState<MinePage>
    with AutomaticKeepAliveClientMixin {
  final MineController controller = Get.putOrFind(MineController.new);
  late final MainController _mainController = Get.find<MainController>();
  late final List<MineCardType> _mineCards = _loadMineCards();

  static List<MineCardType> _loadMineCards() {
    final List? cache = GStorage.setting.get(SettingBoxKey.mineCardSort);
    if (cache == null || cache.isEmpty) {
      const defaults = [MineCardType.history, MineCardType.fav];
      GStorage.setting.put(
        SettingBoxKey.mineCardSort,
        defaults.map((e) => e.index).toList(),
      );
      return defaults;
    }
    return cache
        .whereType<int>()
        .where((i) => i < MineCardType.values.length)
        .map((i) => MineCardType.values[i])
        .toList();
  }

  @override
  bool get wantKeepAlive => true;

  bool get checkPage =>
      _mainController.navigationBars[0] != NavigationBarType.mine &&
      _mainController.selectedIndex.value == 0;

  @override
  bool onNotificationType1(UserScrollNotification notification) {
    if (checkPage) {
      return false;
    }
    return super.onNotificationType1(notification);
  }

  @override
  bool onNotificationType2(ScrollNotification notification) {
    if (checkPage) {
      return false;
    }
    return super.onNotificationType2(notification);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final secondary = theme.colorScheme.secondary;
    return Material(
      type: .transparency,
      child: refreshIndicator(
        key: controller.refreshKey,
        onRefresh: controller.onRefresh,
        child: onBuild(
          ListView(
            padding: const .only(bottom: 100),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              _buildProfilePanel(theme, secondary),
              const SizedBox(height: 20),
              _buildActions(theme),
              for (final card in _mineCards)
                switch (card) {
                  MineCardType.history => Obx(
                    () => controller.historyLoadingState.value is Loading
                        ? const SizedBox.shrink()
                        : _buildHistory(theme, secondary),
                  ),
                  MineCardType.fav => Obx(
                    () => controller.loadingState.value is Loading
                        ? const SizedBox.shrink()
                        : _buildFav(theme, secondary),
                  ),
                  MineCardType.toView => Obx(
                    () => controller.toViewLoadingState.value is Loading
                        ? const SizedBox.shrink()
                        : _buildToView(theme, secondary),
                  ),
                },
            ],
          ),
        ),
      ),
    );
  }

  /// Rose panel holding the header actions, avatar, name and stats.
  Widget _buildProfilePanel(ThemeData theme, Color secondary) {
    final colorScheme = theme.colorScheme;
    return ClipRRect(
      borderRadius: const .vertical(bottom: .circular(48)),
      child: ColoredBox(
        color: colorScheme.primaryContainer,
        child: Stack(
          children: [
            CornerBlob(
              shape: ExpressiveShape.sunny8,
              color: colorScheme.inversePrimary.withValues(alpha: 0.45),
              size: 280,
              right: -70,
              top: -60,
            ),
            Padding(
              padding: const .only(top: 10, bottom: 20),
              child: Column(
                mainAxisSize: .min,
                children: [
                  _buildHeaderActions,
                  _buildUserInfo(theme, secondary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(
    ThemeData theme, {
    required String title,
    int? count,
    required VoidCallback onTap,
    required VoidCallback onRefresh,
  }) {
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const .fromLTRB(20, 20, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: title),
                  if (count != null)
                    TextSpan(
                      text: '  $count',
                      style: TextStyle(color: colorScheme.primary),
                    ),
                ],
              ),
              style: const TextStyle(fontSize: 18, fontWeight: .w800),
            ),
          ),
          IconButton(
            tooltip: '刷新',
            onPressed: onRefresh,
            icon: Icon(
              Icons.refresh_rounded,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              padding: const .only(left: 12, right: 4),
            ),
            child: const Row(
              mainAxisSize: .min,
              children: [
                Text('全部'),
                Icon(Icons.chevron_right_rounded, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(ThemeData theme) {
    return Padding(
      padding: const .symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: .spaceEvenly,
        children: controller.list.indexed.map((e) {
          final (index, item) = e;
          final accent = ExpressiveAccent.of(index + 1, theme.brightness);
          final shape = ExpressiveShape.of(index);
          return Flexible(
            child: InkWell(
              onTap: item.onTap,
              borderRadius: const .all(.circular(Style.radiusLg)),
              child: Padding(
                padding: const .symmetric(vertical: 6, horizontal: 4),
                child: Column(
                  spacing: 8,
                  mainAxisSize: .min,
                  children: [
                    ShapeBlob(
                      shape: shape,
                      color: accent.container,
                      size: 64,
                      child: Icon(item.icon, color: accent.onContainer),
                    ),
                    Text(
                      item.title,
                      maxLines: 1,
                      style: const TextStyle(fontSize: 12, fontWeight: .w600),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget get _buildHeaderActions {
    const iconSize = 22.0;
    const padding = EdgeInsets.all(12);
    final colorScheme = ColorScheme.of(context);
    final style = ButtonStyle(
      tapTargetSize: .shrinkWrap,
      foregroundColor: WidgetStatePropertyAll(colorScheme.onPrimaryContainer),
      backgroundColor: WidgetStatePropertyAll(
        colorScheme.surface.withValues(alpha: 0.55),
      ),
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: .all(.circular(Style.radiusMd))),
      ),
    );
    return Row(
      spacing: 8,
      mainAxisAlignment: .end,
      children: [
        if (widget.showBackBtn)
          const Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 8),
                child: BackButton(),
              ),
            ),
          ),
        if (!_mainController.hasHome) ...[
          IconButton(
            iconSize: iconSize,
            padding: padding,
            style: style,
            tooltip: '搜索',
            onPressed: () => Get.toNamed('/search'),
            icon: const Icon(Icons.search),
          ),
          msgBadge(_mainController),
        ],
        if (GStorage.reply != null)
          IconButton(
            iconSize: iconSize,
            padding: padding,
            style: style,
            tooltip: '评论记录',
            onPressed: () => Get.toNamed('/myReply'),
            icon: const Icon(Icons.message_outlined),
          ),
        Obx(
          () {
            final anonymity = MineController.anonymity.value;
            return IconButton(
              iconSize: iconSize,
              padding: padding,
              style: style,
              tooltip: "${anonymity ? '退出' : '进入'}无痕模式",
              onPressed: MineController.onChangeAnonymity,
              icon: anonymity
                  ? const Icon(MdiIcons.incognito)
                  : const Icon(MdiIcons.incognitoOff),
            );
          },
        ),
        IconButton(
          iconSize: iconSize,
          padding: padding,
          style: style,
          tooltip: '切换账号',
          onPressed: () => LoginPageController.switchAccountDialog(context),
          icon: const Icon(Icons.switch_account_outlined),
        ),
        Obx(
          () {
            return IconButton(
              iconSize: iconSize,
              padding: padding,
              style: style,
              tooltip: '切换至${controller.nextThemeType.label}主题',
              onPressed: controller.onChangeTheme,
              icon: controller.themeType.value.icon,
            );
          },
        ),
        IconButton(
          iconSize: iconSize,
          padding: padding,
          style: style,
          tooltip: '设置',
          onPressed: () => Get.toNamed('/setting', preventDuplicates: false),
          icon: const Icon(Icons.settings_outlined),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildUserInfo(ThemeData theme, Color secondary) {
    final colorScheme = theme.colorScheme;
    const style = TextStyle(fontSize: 24, fontWeight: FontWeight.w900);
    final labelStyle = TextStyle(
      fontSize: 12,
      color: colorScheme.onSurfaceVariant,
    );
    final coinLabelStyle = TextStyle(
      fontSize: theme.textTheme.labelMedium!.fontSize,
      color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
    );
    final coinValStyle = TextStyle(
      fontSize: theme.textTheme.labelMedium!.fontSize,
      fontWeight: FontWeight.w800,
      color: colorScheme.onPrimaryContainer,
    );
    return Obx(() {
      final userInfo = controller.userInfo.value;
      final levelInfo = userInfo.levelInfo;
      final hasLevel = levelInfo != null;
      final isVip = userInfo.vipStatus != null && userInfo.vipStatus! > 0;
      final userStat = controller.userStat.value;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            behavior: .opaque,
            onTap: controller.onLogin,
            onLongPress: () {
              Feedback.forLongPress(context);
              controller.onLogin(true);
            },
            onSecondaryTap: PlatformUtils.isMobile
                ? null
                : () => controller.onLogin(true),
            child: Row(
              mainAxisSize: .min,
              children: [
                const SizedBox(width: 20),
                userInfo.face != null
                    ? Stack(
                        clipBehavior: .none,
                        children: [
                          ShapeBlob(
                            shape: ExpressiveShape.cookie9,
                            color: colorScheme.primary,
                            size: 88,
                            child: NetworkImgLayer(
                              src: userInfo.face,
                              type: .avatar,
                              width: 64,
                              height: 64,
                            ),
                          ),
                          if (isVip)
                            Positioned(
                              right: -1,
                              bottom: -2,
                              child: SvgPicture.asset(
                                Assets.vipIcon,
                                height: 19,
                                semanticsLabel: "大会员",
                              ),
                            ),
                        ],
                      )
                    : ShapeBlob(
                        shape: ExpressiveShape.cookie9,
                        color: colorScheme.primary,
                        size: 88,
                        child: ClipOval(
                          child: Image.asset(
                            width: 64,
                            height: 64,
                            cacheHeight: 64.cacheSize(context),
                            Assets.avatarPlaceHolder,
                            semanticLabel: "默认头像",
                          ),
                        ),
                      ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: .min,
                    mainAxisAlignment: .center,
                    crossAxisAlignment: .start,
                    children: [
                      Row(
                        spacing: 6,
                        children: [
                          Flexible(
                            child: Text(
                              userInfo.uname ?? '点击登录',
                              style: TextStyle(
                                height: 1.1,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: isVip && userInfo.vipType == 2
                                    ? colorScheme.vipColor
                                    : colorScheme.onPrimaryContainer,
                              ),
                              maxLines: 1,
                              overflow: .ellipsis,
                            ),
                          ),
                          BiliUtils.levelPicture(
                            levelInfo?.currentLevel ?? 0,
                            isSeniorMember: userInfo.isSeniorMember == 1,
                            height: 10,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '硬币 ',
                              style: coinLabelStyle,
                            ),
                            TextSpan(
                              text: userInfo.money?.toString() ?? '-',
                              style: coinValStyle,
                            ),
                            TextSpan(
                              text: "      经验 ",
                              style: coinLabelStyle,
                            ),
                            TextSpan(
                              text: levelInfo?.currentExp?.toString() ?? '-',
                              style: coinValStyle,
                            ),
                            TextSpan(
                              text: "/${levelInfo?.nextExp ?? '-'}",
                              style: coinLabelStyle,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 225),
                        child: LinearProgressIndicator(
                          minHeight: 4,
                          borderRadius: const .all(.circular(2)),
                          value: hasLevel
                              ? levelInfo.currentExp! / levelInfo.nextExp!
                              : 0,
                          backgroundColor: colorScheme.surface.withValues(
                            alpha: 0.6,
                          ),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.primary,
                          ),
                          stopIndicatorColor: Colors.transparent,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            spacing: 4,
            children: [
              const SizedBox(width: 12),
              _btn(
                index: 0,
                count: userStat.dynamicCount,
                countStyle: style,
                name: '动态',
                labelStyle: labelStyle,
                onTap: () => controller.push('memberDynamics'),
              ),
              _btn(
                index: 1,
                count: userStat.following,
                countStyle: style,
                name: '关注',
                labelStyle: labelStyle,
                onTap: () => controller.push('follow'),
              ),
              _btn(
                index: 2,
                count: userStat.follower,
                countStyle: style,
                name: '粉丝',
                labelStyle: labelStyle,
                onTap: () => controller.push('fan'),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ],
      );
    });
  }

  /// One tile of the connected stats group.
  Widget _btn({
    required int index,
    required int? count,
    required TextStyle countStyle,
    required String name,
    required TextStyle? labelStyle,
    required VoidCallback onTap,
  }) {
    final borderRadius = Style.connectedRadius(
      first: index == 0,
      last: index == 2,
      outer: Style.radiusXl,
    );
    return Expanded(
      child: Material(
        color: ColorScheme.of(context).surface,
        borderRadius: borderRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: SizedBox(
            height: 72,
            child: Column(
              spacing: 2,
              mainAxisAlignment: .center,
              children: [
                Text(
                  count?.toString() ?? '-',
                  style: countStyle,
                ),
                Text(
                  name,
                  style: labelStyle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _autoRefresh() => Future.delayed(
    const Duration(milliseconds: 150),
    () => controller.onRefresh(isManual: false),
  );

  Widget _buildToView(ThemeData theme, Color secondary) {
    return Column(
      children: [
        _sectionHeader(
          theme,
          title: '稍后再看',
          onTap: () => Get.toNamed('/later'),
          onRefresh: controller.queryToView,
        ),
        _buildToViewBody(theme, secondary, controller.toViewLoadingState.value),
      ],
    );
  }

  Widget _buildToViewBody(
    ThemeData theme,
    Color secondary,
    LoadingState loadingState,
  ) {
    return switch (loadingState) {
      Loading() => const SizedBox.shrink(),
      Success(:final response) => Builder(
        builder: (context) {
          final list = response as List?;
          if (list == null || list.isEmpty) {
            return const SizedBox.shrink();
          }
          return SizedBox(
            height: 173,
            child: ListView.separated(
              padding: const EdgeInsets.only(left: 20, top: 10, right: 20),
              itemCount: list.length + 1,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                if (index == list.length) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 46),
                    child: Center(
                      child: IconButton(
                        tooltip: '查看更多',
                        style: ButtonStyle(
                          padding: const WidgetStatePropertyAll(
                            EdgeInsets.zero,
                          ),
                          backgroundColor: WidgetStatePropertyAll(
                            theme.colorScheme.secondaryContainer.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        onPressed: () => Get.toNamed('/later'),
                        icon: Icon(
                          Icons.arrow_forward_ios,
                          size: 18,
                          color: secondary,
                        ),
                      ),
                    ),
                  );
                }
                return ToViewCardItem(item: list[index] as LaterItemModel);
              },
              separatorBuilder: (_, _) => const SizedBox(width: 14),
            ),
          );
        },
      ),
      Error(:final errMsg) => SizedBox(
        height: 80,
        child: Center(
          child: Text(
            errMsg ?? '',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    };
  }

  Widget _buildHistory(ThemeData theme, Color secondary) {
    return Column(
      children: [
        _sectionHeader(
          theme,
          title: '观看记录',
          onTap: () => Get.toNamed('/history'),
          onRefresh: controller.queryHistory,
        ),
        _buildHistoryBody(
          theme,
          secondary,
          controller.historyLoadingState.value,
        ),
      ],
    );
  }

  Widget _buildHistoryBody(
    ThemeData theme,
    Color secondary,
    LoadingState loadingState,
  ) {
    return switch (loadingState) {
      Loading() => const SizedBox.shrink(),
      Success(:final response) => Builder(
        builder: (context) {
          final list = response as List?;
          if (list == null || list.isEmpty) {
            return const SizedBox.shrink();
          }
          return SizedBox(
            height: 173,
            child: ListView.separated(
              padding: const EdgeInsets.only(left: 20, top: 10, right: 20),
              itemCount: list.length + 1,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                if (index == list.length) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 46),
                    child: Center(
                      child: IconButton(
                        tooltip: '查看更多',
                        style: ButtonStyle(
                          padding: const WidgetStatePropertyAll(
                            EdgeInsets.zero,
                          ),
                          backgroundColor: WidgetStatePropertyAll(
                            theme.colorScheme.secondaryContainer.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        onPressed: () => Get.toNamed('/history'),
                        icon: Icon(
                          Icons.arrow_forward_ios,
                          size: 18,
                          color: secondary,
                        ),
                      ),
                    ),
                  );
                }
                return HistoryCardItem(item: list[index]);
              },
              separatorBuilder: (_, _) => const SizedBox(width: 14),
            ),
          );
        },
      ),
      Error(:final errMsg) => SizedBox(
        height: 80,
        child: Center(
          child: Text(
            errMsg ?? '',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    };
  }

  Widget _buildFav(ThemeData theme, Color secondary) {
    return Column(
      children: [
        _sectionHeader(
          theme,
          title: '我的收藏',
          count: controller.favFolderCount,
          onTap: () => Get.toNamed('/fav')?.whenComplete(_autoRefresh),
          onRefresh: controller.onRefresh,
        ),
        _buildFavBody(theme, secondary, controller.loadingState.value),
      ],
    );
  }

  Widget _buildFavBody(
    ThemeData theme,
    Color secondary,
    LoadingState loadingState,
  ) {
    return switch (loadingState) {
      Loading() => const SizedBox.shrink(),
      Success(:final response) => Builder(
        builder: (context) {
          List<FavFolderInfo>? favFolderList = response.list;
          if (favFolderList == null || favFolderList.isEmpty) {
            return const SizedBox.shrink();
          }
          bool flag = (controller.favFolderCount ?? 0) > favFolderList.length;
          return SizedBox(
            height: 173,
            child: ListView.separated(
              controller: controller.scrollController,
              padding: const .only(left: 20, top: 10, right: 20),
              itemCount: response.list.length + (flag ? 1 : 0),
              itemBuilder: (context, index) {
                if (flag && index == favFolderList.length) {
                  return Padding(
                    padding: const .only(bottom: 46),
                    child: Center(
                      child: IconButton(
                        tooltip: '查看更多',
                        style: ButtonStyle(
                          padding: const WidgetStatePropertyAll(.zero),
                          backgroundColor: WidgetStatePropertyAll(
                            theme.colorScheme.secondaryContainer.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        onPressed: () =>
                            Get.toNamed('/fav')?.whenComplete(_autoRefresh),
                        icon: Icon(
                          Icons.arrow_forward_ios,
                          size: 18,
                          color: secondary,
                        ),
                      ),
                    ),
                  );
                } else {
                  return FavFolderItem(
                    heroTag: Utils.generateRandomString(8),
                    item: response.list[index],
                    onPop: _autoRefresh,
                  );
                }
              },
              scrollDirection: .horizontal,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
            ),
          );
        },
      ),
      Error(:final errMsg) => SizedBox(
        height: 160,
        child: Center(
          child: Text(
            errMsg ?? '',
            textAlign: .center,
          ),
        ),
      ),
    };
  }
}
