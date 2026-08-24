import 'package:PiliPlus/common/widgets/flutter/list_tile.dart';
import 'package:PiliPlus/pages/setting/models/model.dart';
import 'package:PiliPlus/pages/setting/models/dynamics_settings.dart';
import 'package:flutter/material.dart' hide ListTile;
import 'package:get/get.dart';

class DynamicsSetting extends StatefulWidget {
  const DynamicsSetting({
    super.key,
    this.showAppBar = true,
    this.autoOpenKeywordFilter = false,
  });

  final bool showAppBar;
  final bool autoOpenKeywordFilter;

  @override
  State<DynamicsSetting> createState() => _DynamicsSettingState();
}

class _DynamicsSettingState extends State<DynamicsSetting> {
  final list = dynamicsSettings;

  @override
  void initState() {
    super.initState();
    if (widget.autoOpenKeywordFilter) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || list.isEmpty) {
          return;
        }
        final firstItem = list.first;
        if (firstItem case NormalModel(:final onTap)) {
          onTap?.call(context, () {
            if (mounted) {
              setState(() {});
            }
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final showAppBar = widget.showAppBar;
    final padding = MediaQuery.viewPaddingOf(context);
    final theme = Theme.of(context);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: widget.showAppBar ? AppBar(title: Text('动态流设置'.tr)) : null,
      body: ListView(
        padding: EdgeInsets.only(
          left: showAppBar ? padding.left : 0,
          right: showAppBar ? padding.right : 0,
          bottom: padding.bottom + 100,
        ),
        children: [
          ...list.map((item) => item.widget),
          ListTile(
            dense: true,
            subtitle: Text(
              '* 屏蔽用户后，该用户发布的动态将不会显示。\n'.tr +
              '* 动态流屏蔽用户优先于白名单生效。\n'.tr +
              '* 白名单用户与推荐流/评论区共享，白名单优先于带货屏蔽和常规过滤。\n'.tr +
              '* 关键词过滤支持正则表达式，多个关键词使用|分隔。\n'.tr +
              '* 设置立即生效，刷新动态页面即可看到过滤结果。'.tr,
              style: theme.textTheme.labelSmall!.copyWith(
                color: theme.colorScheme.outline.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
