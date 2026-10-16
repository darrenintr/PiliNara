import 'package:PiliPlus/common/expressive/expressive_colors.dart';
import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/flutter/list_tile.dart';
import 'package:PiliPlus/common/widgets/scaffold/simple_scaffold.dart';
import 'package:PiliPlus/common/widgets/view_safe_area.dart';
import 'package:PiliPlus/http/login.dart';
import 'package:PiliPlus/models/common/setting_type.dart';
import 'package:PiliPlus/pages/about/view.dart';
import 'package:PiliPlus/pages/login/controller.dart';
import 'package:PiliPlus/pages/setting/common_setting.dart';
import 'package:PiliPlus/pages/setting/widgets/multi_select_dialog.dart';
import 'package:PiliPlus/pages/webdav/view.dart';
import 'package:PiliPlus/utils/accounts.dart';
import 'package:PiliPlus/utils/accounts/account.dart';
import 'package:PiliPlus/utils/extension/size_ext.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:material_ui/material_ui.dart' hide ListTile;

class _SettingsModel {
  final SettingType type;
  final String? subtitle;
  final Icon icon;

  const _SettingsModel({
    required this.type,
    this.subtitle,
    required this.icon,
  });
}

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  late SettingType _type = SettingType.privacySetting;
  final RxBool _noAccount = Accounts.account.isEmpty.obs;
  late bool _isPortrait;
  late ThemeData theme;

  static const List<_SettingsModel> _items = [
    _SettingsModel(
      type: SettingType.privacySetting,
      subtitle: '黑名单',
      icon: Icon(Icons.privacy_tip_outlined),
    ),
    _SettingsModel(
      type: SettingType.recommendSetting,
      subtitle: '推荐来源（web/app）、刷新保留内容、过滤器',
      icon: Icon(Icons.explore_outlined),
    ),
    _SettingsModel(
      type: SettingType.dynamicsSetting,
      subtitle: '关键词过滤、屏蔽用户、带货动态屏蔽',
      icon: Icon(Icons.dynamic_feed_outlined),
    ),
    _SettingsModel(
      type: SettingType.videoSetting,
      subtitle: '画质、音质、解码、缓冲、音频输出等',
      icon: Icon(Icons.video_settings_outlined),
    ),
    _SettingsModel(
      type: SettingType.playSetting,
      subtitle: '双击/长按、全屏、后台播放、弹幕、字幕、底部进度条等',
      icon: Icon(Icons.touch_app_outlined),
    ),
    _SettingsModel(
      type: SettingType.styleSetting,
      subtitle: '横屏适配（平板）、侧栏、列宽、首页、动态红点、主题、字号、图片、帧率等',
      icon: Icon(Icons.style_outlined),
    ),
    _SettingsModel(
      type: SettingType.extraSetting,
      subtitle: '震动、搜索、收藏、ai、评论、代理、更新检查等',
      icon: Icon(Icons.extension_outlined),
    ),
    _SettingsModel(
      type: SettingType.webdavSetting,
      icon: Icon(MdiIcons.databaseCogOutline),
    ),
    _SettingsModel(
      type: SettingType.about,
      icon: Icon(Icons.info_outline),
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    theme = Theme.of(context);
    _isPortrait = MediaQuery.sizeOf(context).isPortrait;
  }

  @override
  Widget build(BuildContext context) {
    return SimpleScaffold(
      appBar: AppBar(
        title: _isPortrait ? const Text('设置') : Text(_type.title),
      ),
      body: ViewSafeArea(
        child: _isPortrait
            ? _buildList(theme)
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: _buildList(theme),
                  ),
                  VerticalDivider(
                    width: 1,
                    color: theme.colorScheme.outline.withValues(alpha: 0.1),
                  ),
                  Expanded(
                    flex: 6,
                    child: switch (_type) {
                      .privacySetting ||
                      .recommendSetting ||
                      .dynamicsSetting ||
                      .videoSetting ||
                      .playSetting ||
                      .styleSetting ||
                      .extraSetting => CommonSetting(
                        settingType: _type,
                        showAppBar: false,
                      ),
                      .webdavSetting => const WebDavSettingPage(
                        showAppBar: false,
                      ),
                      .about => const AboutPage(showAppBar: false),
                    },
                  ),
                ],
              ),
      ),
    );
  }

  @override
  void dispose() {
    _noAccount.close();
    super.dispose();
  }

  void _toPage(SettingType type) {
    if (_isPortrait) {
      Get.to(
        () => switch (type) {
          .privacySetting ||
          .recommendSetting ||
          .dynamicsSetting ||
          .videoSetting ||
          .playSetting ||
          .styleSetting ||
          .extraSetting => CommonSetting(settingType: type),
          .webdavSetting => const WebDavSettingPage(),
          .about => const AboutPage(),
        },
      );
    } else {
      _type = type;
      setState(() {});
    }
  }

  Color? _getTileColor(ThemeData theme, SettingType type) {
    if (_isPortrait) {
      return null;
    } else {
      return type == _type ? theme.colorScheme.secondaryContainer : null;
    }
  }

  /// One tile of a grouped list: the group's outer corners are large,
  /// the joins between tiles stay tight.
  Widget _groupTile({
    required int index,
    required int count,
    required IconData icon,
    required int accent,
    required String title,
    String? subtitle,
    Color? tileColor,
    required VoidCallback onTap,
  }) {
    final colorScheme = theme.colorScheme;
    final colors = ExpressiveAccent.of(accent, theme.brightness);
    const outer = Radius.circular(Style.radiusXxl);
    const inner = Radius.circular(6);
    return Padding(
      padding: EdgeInsets.only(bottom: index == count - 1 ? 0 : 3),
      child: ListTile(
        onTap: onTap,
        minTileHeight: 72,
        tileColor: tileColor ?? colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: index == 0 ? outer : inner,
            bottom: index == count - 1 ? outer : inner,
          ),
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: colors.container,
            borderRadius: BorderRadius.all(
              Radius.circular(index.isEven ? Style.radiusMd : 22),
            ),
          ),
          child: Icon(icon, color: colors.onContainer),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: colorScheme.outline,
        ),
      ),
    );
  }

  Widget _buildList(ThemeData theme) {
    final padding = MediaQuery.viewPaddingOf(context);
    final settings = _items.take(_items.length - 1).toList();
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 0, 16, padding.bottom + 100),
      children: [
        _buildSearchItem(theme),
        for (final (index, item) in settings.indexed)
          _groupTile(
            index: index,
            count: settings.length,
            icon: item.icon.icon!,
            accent: index,
            title: item.type.title,
            subtitle: item.subtitle,
            tileColor: _getTileColor(theme, item.type),
            onTap: () => _toPage(item.type),
          ),
        const SizedBox(height: 18),
        Obx(() {
          final account = <Widget Function(int index, int count)>[
            (index, count) => _groupTile(
              index: index,
              count: count,
              icon: Icons.switch_account_rounded,
              accent: 2,
              title: '切换账号',
              onTap: () => LoginPageController.switchAccountDialog(context),
            ),
            if (!_noAccount.value)
              (index, count) => _groupTile(
                index: index,
                count: count,
                icon: Icons.logout_rounded,
                accent: 0,
                title: '退出登录',
                onTap: () => _logoutDialog(context),
              ),
            (index, count) => _groupTile(
              index: index,
              count: count,
              icon: _items.last.icon.icon!,
              accent: 4,
              title: _items.last.type.title,
              tileColor: _getTileColor(theme, _items.last.type),
              onTap: () => _toPage(_items.last.type),
            ),
          ];
          return Column(
            children: [
              for (final (index, build) in account.indexed)
                build(index, account.length),
            ],
          );
        }),
      ],
    );
  }

  Future<void> _removeAccounts(Set<LoginAccount> accounts) async {
    await Accounts.deleteAll(accounts);
    if (mounted) _noAccount.value = Accounts.account.isEmpty;
  }

  static Future<LoginAccount?> _logoutWrapper(LoginAccount account) async {
    try {
      final res = await LoginHttp.logout(account);
      return res.isSuccess ? account : null;
    } catch (e, s) {
      Utils.reportError(e, s);
      return null;
    }
  }

  Future<void> _logoutDialog(BuildContext context) async {
    final result = await showDialog<Set<LoginAccount>>(
      context: context,
      builder: (context) => MultiSelectDialog<LoginAccount>(
        title: '选择要登出的账号uid',
        initValues: const Iterable.empty(),
        values: {
          for (final i in Accounts.account.values) i: i.mid.toString(),
        },
      ),
    );
    if (!context.mounted || result == null || result.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('提示'),
          content: Text(
            "确认要退出以下账号登录吗\n\n${result.map((i) => i.mid).join('\n')}",
          ),
          actions: [
            TextButton(
              onPressed: Get.back,
              child: Text(
                '点错了',
                style: TextStyle(color: theme.colorScheme.outline),
              ),
            ),
            TextButton(
              onPressed: () {
                Get.back();
                _removeAccounts(result);
              },
              child: Text(
                '仅登出',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
            TextButton(
              onPressed: () async {
                SmartDialog.showLoading();
                final res = await Future.wait(result.map(_logoutWrapper));
                SmartDialog.dismiss();
                final logoutAccounts = res.nonNulls.toSet();
                if (logoutAccounts.isEmpty) {
                  SmartDialog.showToast('所选账号均退出登录失败');
                } else {
                  Get.back();
                  _removeAccounts(logoutAccounts);
                  if (logoutAccounts.length != result.length) {
                    result.removeWhere(logoutAccounts.contains);
                    SmartDialog.showToast(
                      '账号 ${result.map((i) => i.mid).join(",")} 退出登录失败',
                    );
                  }
                }
              },
              child: const Text('确认'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchItem(ThemeData theme) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: const BorderRadius.all(Radius.circular(28)),
      child: InkWell(
        onTap: () => Get.toNamed('/settingsSearch'),
        borderRadius: const BorderRadius.all(Radius.circular(28)),
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              const SizedBox(width: 20),
              Icon(
                Icons.search_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Text(
                '搜索设置项',
                style: TextStyle(
                  fontSize: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
