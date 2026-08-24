import 'dart:io' show Platform;

import 'package:PiliPlus/common/widgets/custom_icon.dart';
import 'package:PiliPlus/models/common/super_chat_time_type.dart';
import 'package:PiliPlus/models/common/super_chat_type.dart';
import 'package:PiliPlus/models/common/video/subtitle_pref_type.dart';
import 'package:PiliPlus/pages/main/controller.dart';
import 'package:PiliPlus/pages/setting/models/model.dart';
import 'package:PiliPlus/pages/setting/pages/fullscreen_sc_size.dart';
import 'package:PiliPlus/pages/setting/widgets/select_dialog.dart';
import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:PiliPlus/pages/setting/widgets/slider_dialog.dart';
import 'package:PiliPlus/plugin/pl_player/models/bottom_progress_behavior.dart';
import 'package:PiliPlus/plugin/pl_player/models/fullscreen_mode.dart';
import 'package:PiliPlus/plugin/pl_player/models/play_repeat.dart';
import 'package:PiliPlus/services/service_locator.dart';
import 'package:PiliPlus/utils/extension/num_ext.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

List<SettingsModel> get playSettings => [
  SwitchModel(
    title: '弹幕开关'.tr,
    subtitle: '是否展示弹幕'.tr,
    leading: Icon(CustomIcons.dm_settings),
    setKey: SettingBoxKey.enableShowDanmaku,
    defaultVal: true,
  ),
  if (PlatformUtils.isMobile)
    SwitchModel(
      title: '启用点击弹幕'.tr,
      subtitle: '点击弹幕悬停，支持点赞、复制、举报操作'.tr,
      leading: Icon(Icons.touch_app_outlined),
      setKey: SettingBoxKey.enableTapDm,
      defaultVal: true,
    ),
  NormalModel(
    onTap: (context, setState) => Get.toNamed('/playSpeedSet'),
    leading: const Icon(Icons.speed_outlined),
    title: '倍速设置'.tr,
    subtitle: '设置视频播放速度'.tr,
  ),
  if (Platform.isAndroid)
    NormalModel(
      onTap: _showAngleDegreesDialog,
      leading: const Icon(MdiIcons.angleAcute),
      title: '倾斜角度阈值'.tr,
      getSubtitle: () => '当前:「${Pref.angleDegrees}°」',
    ),
  SwitchModel(
    title: '自动播放'.tr,
    subtitle: '进入详情页自动播放'.tr,
    leading: Icon(Icons.motion_photos_auto_outlined),
    setKey: SettingBoxKey.autoPlayEnable,
    defaultVal: false,
  ),
  SwitchModel(
    title: '全屏显示锁定按钮'.tr,
    leading: Icon(Icons.lock_outline),
    setKey: SettingBoxKey.showFsLockBtn,
    defaultVal: true,
  ),
  SwitchModel(
    title: '锁定按钮显示在右侧'.tr,
    subtitle: '开启后锁定按钮移至右侧，与截图按钮一同垂直居中排列'.tr,
    leading: Icon(Icons.keyboard_double_arrow_right),
    setKey: SettingBoxKey.showFsLockBtnRight,
    defaultVal: false,
  ),
  SwitchModel(
    title: '全屏显示截图按钮'.tr,
    leading: Icon(Icons.photo_camera_outlined),
    setKey: SettingBoxKey.showFsScreenshotBtn,
    defaultVal: true,
  ),
  SwitchModel(
    title: '全屏显示电池电量'.tr,
    leading: const Icon(Icons.battery_3_bar),
    setKey: SettingBoxKey.showBatteryLevel,
    defaultVal: PlatformUtils.isMobile,
  ),
  SwitchModel(
    title: '双击快退/快进'.tr,
    subtitle: '左侧双击快退/右侧双击快进，关闭则双击均为暂停/播放'.tr,
    leading: Icon(Icons.touch_app_outlined),
    setKey: SettingBoxKey.enableQuickDouble,
    defaultVal: true,
  ),
  SwitchModel(
    title: '左右侧滑动调节亮度/音量'.tr,
    leading: Icon(MdiIcons.tuneVerticalVariant),
    setKey: SettingBoxKey.enableSlideVolumeBrightness,
    defaultVal: true,
  ),
  if (Platform.isAndroid)
    SwitchModel(
      title: '调节系统亮度'.tr,
      leading: Icon(Icons.brightness_6_outlined),
      setKey: SettingBoxKey.setSystemBrightness,
      defaultVal: false,
    ),
  if (PlatformUtils.isMobile)
    SwitchModel(
      title: '应用内音量'.tr,
      subtitle: '开启后在应用内调节音量不会改变系统音量'.tr,
      leading: const Icon(Icons.volume_up_outlined),
      setKey: SettingBoxKey.enableAppVolume,
      defaultVal: false,
      onChanged: (value) async {
        await PlPlayerController.instance?.onAppVolumeSettingChanged();
      },
    ),
  if (PlatformUtils.isMobile && Pref.enableAppVolume)
    SwitchModel(
      title: '音量增强'.tr,
      subtitle: '在应用内音量模式下允许放大至 200%'.tr,
      leading: Icon(Icons.volume_up_outlined),
      setKey: SettingBoxKey.enableVolumeBoost,
      defaultVal: false,
    ),
  if (PlatformUtils.isMobile)
    NormalModel(
      title: '播放器音量'.tr,
      leading: const Icon(Icons.volume_up),
      getSubtitle: () =>
          '当前:「${Pref.playerVolume.toStringAsFixed(0)}%」\n'
          '在系统音量基础上增益；开启应用内音量后不生效'.tr,
      onTap: showPlayerVolumeDialog,
    )
  else
    NormalModel(
      title: '最高音量'.tr,
      leading: const Icon(Icons.volume_up),
      getSubtitle: () => '当前:「${(Pref.maxVolume * 100).toStringAsFixed(0)}%」',
      onTap: _showMaxVolumeDialog,
    ),
  SwitchModel(
    title: '中间滑动进入/退出全屏'.tr,
    leading: Icon(MdiIcons.panVertical),
    setKey: SettingBoxKey.enableSlideFS,
    defaultVal: true,
  ),
  getVideoFilterSelectModel(
    title: '双击快进/快退时长'.tr,
    suffix: 's',
    key: SettingBoxKey.fastForBackwardDuration,
    values: [5, 10, 15],
    defaultValue: 10,
    isFilter: false,
  ),
  SwitchModel(
    title: '滑动快进/快退使用相对时长'.tr,
    leading: Icon(Icons.swap_horiz_outlined),
    setKey: SettingBoxKey.useRelativeSlide,
    defaultVal: false,
  ),
  getVideoFilterSelectModel(
    title: '滑动快进/快退时长'.tr,
    subtitle: '从播放器一端滑到另一端的快进/快退时长'.tr,
    suffix: Pref.useRelativeSlide ? '%' : 's',
    key: SettingBoxKey.sliderDuration,
    values: [25, 50, 90, 100],
    defaultValue: 90,
    isFilter: false,
  ),
  NormalModel(
    title: '自动启用字幕'.tr,
    leading: const Icon(Icons.closed_caption_outlined),
    getSubtitle: () => '当前选择偏好：${Pref.subtitlePreferenceV2.desc}',
    onTap: _showSubtitleDialog,
  ),
  if (PlatformUtils.isDesktop)
    SwitchModel(
      title: '最小化时暂停/还原时播放'.tr,
      leading: const Icon(Icons.pause_circle_outline),
      setKey: SettingBoxKey.pauseOnMinimize,
      defaultVal: false,
      onChanged: (value) {
        try {
          Get.find<MainController>().pauseOnMinimize = value;
        } catch (_) {}
      },
    ),
  SwitchModel(
    title: '启用键盘控制'.tr,
    leading: Icon(Icons.keyboard_alt_outlined),
    setKey: SettingBoxKey.keyboardControl,
    defaultVal: true,
  ),
  NormalModel(
    title: 'SuperChat (醒目留言) 显示类型'.tr,
    leading: const Icon(Icons.live_tv),
    getSubtitle: () => '当前:「${Pref.superChatType.title}」',
    onTap: _showSuperChatDialog,
  ),
  NormalModel(
    title: 'SuperChat 发送时间显示'.tr,
    leading: const Icon(Icons.access_time_outlined),
    getSubtitle: () => '当前:「${Pref.superChatTimeType.title}」',
    onTap: _showSuperChatTimeDialog,
  ),
  NormalModel(
    title: '全屏 SC 大小'.tr,
    subtitle: 'SuperChat (醒目留言) 大小设置'.tr,
    leading: const Icon(Icons.open_in_full),
    onTap: (_, _) => Get.to(const FullScreenScSize()),
  ),
  SwitchModel(
    title: '竖屏扩大展示'.tr,
    subtitle: '小屏竖屏视频宽高比由16:9扩大至1:1（不支持收起）；横屏适配时，扩大至9:16'.tr,
    leading: Icon(Icons.expand_outlined),
    setKey: SettingBoxKey.enableVerticalExpand,
    defaultVal: false,
  ),
  SwitchModel(
    title: '自动全屏'.tr,
    subtitle: '视频开始播放时进入全屏'.tr,
    leading: Icon(Icons.fullscreen_outlined),
    setKey: SettingBoxKey.enableAutoEnter,
    defaultVal: false,
  ),
  SwitchModel(
    title: '自动退出全屏'.tr,
    subtitle: '视频结束播放时退出全屏'.tr,
    leading: Icon(Icons.fullscreen_exit_outlined),
    setKey: SettingBoxKey.enableAutoExit,
    defaultVal: true,
  ),
  SwitchModel(
    title: '延长播放控件显示时间'.tr,
    subtitle: '开启后延长至30秒，便于屏幕阅读器滑动切换控件焦点'.tr,
    leading: Icon(Icons.timer_outlined),
    setKey: SettingBoxKey.enableLongShowControl,
    defaultVal: false,
  ),
  SwitchModel(
    title: '手动切集后显示播放控件'.tr,
    subtitle: '点击上一集、下一集或分集列表切换后保持控件显示'.tr,
    leading: Icon(Icons.touch_app_outlined),
    setKey: SettingBoxKey.showControlsOnManualEpisodeChange,
    defaultVal: false,
  ),
  if (PlatformUtils.isMobile)
    SwitchModel(
      title: '后台播放'.tr,
      subtitle: '进入后台时继续播放'.tr,
      leading: Icon(Icons.motion_photos_pause_outlined),
      setKey: SettingBoxKey.continuePlayInBackground,
      defaultVal: false,
    ),
  SwitchModel(
    title: '应用内画中画'.tr,
    subtitle: '支持在应用内以小窗形式播放视频'.tr,
    leading: Icon(Icons.picture_in_picture_alt_outlined),
    setKey: SettingBoxKey.enableInAppPip,
    defaultVal: true,
  ),
  if (Platform.isAndroid) ...[
    SwitchModel(
      title: '后台画中画'.tr,
      subtitle: '进入后台时以小窗形式（PiP）播放'.tr,
      leading: const Icon(Icons.picture_in_picture_outlined),
      setKey: SettingBoxKey.autoPiP,
      defaultVal: false,
      onChanged: (val) {
        if (val && !videoPlayerServiceHandler!.enableBackgroundPlay) {
          SmartDialog.showToast('建议开启后台音频服务'.tr);
        }
      },
    ),
    SwitchModel(
      title: '应用内小窗转后台画中画（实验性）'.tr,
      subtitle: '实验性功能：应用内小窗存在时，退到后台自动切换为系统 PiP；可能因系统差异出现异常'.tr,
      leading: Icon(Icons.science_outlined),
      setKey: SettingBoxKey.enableInAppPipToSystemPip,
      defaultVal: true,
    ),
    SwitchModel(
      title: '画中画不加载弹幕'.tr,
      subtitle: '当弹幕开关开启时，小窗屏蔽弹幕以获得较好的体验'.tr,
      leading: Icon(CustomIcons.dm_off),
      setKey: SettingBoxKey.pipNoDanmaku,
      defaultVal: false,
    ),
  ],
  SwitchModel(
    title: '全屏手势反向'.tr,
    subtitle: '默认播放器中部向上滑动进入全屏，向下退出\n开启后向下全屏，向上退出'.tr,
    leading: Icon(Icons.swap_vert),
    setKey: SettingBoxKey.fullScreenGestureReverse,
    defaultVal: false,
  ),
  SwitchModel(
    title: '全屏展示点赞/投币/收藏等操作按钮'.tr,
    leading: Icon(MdiIcons.dotsHorizontalCircleOutline),
    setKey: SettingBoxKey.showFSActionItem,
    defaultVal: true,
  ),
  SwitchModel(
    title: '观看人数'.tr,
    subtitle: '展示同时在看人数'.tr,
    leading: Icon(Icons.people_outlined),
    setKey: SettingBoxKey.enableOnlineTotal,
    defaultVal: false,
  ),
  NormalModel(
    title: '默认全屏方向'.tr,
    leading: const Icon(Icons.open_with_outlined),
    getSubtitle: () => '当前全屏方向：${Pref.fullScreenMode.desc}',
    onTap: _showFullScreenModeDialog,
  ),
  NormalModel(
    title: '底部进度条展示'.tr,
    leading: const Icon(Icons.border_bottom_outlined),
    getSubtitle: () => '当前展示方式：${Pref.btmProgressBehavior.desc}',
    onTap: _showProgressBehaviorDialog,
  ),
  if (PlatformUtils.isMobile)
    SwitchModel(
      title: '后台音频服务'.tr,
      subtitle: '避免画中画没有播放暂停功能'.tr,
      leading: const Icon(Icons.volume_up_outlined),
      setKey: SettingBoxKey.enableBackgroundPlay,
      defaultVal: true,
      onChanged: (value) =>
          videoPlayerServiceHandler!.enableBackgroundPlay = value,
    ),
  PopupModel(
    title: '播放顺序'.tr,
    leading: const Icon(Icons.repeat),
    value: () => Pref.playRepeat,
    items: PlayRepeat.values,
    onSelected: (value, setState) => GStorage.video
        .put(VideoBoxKey.playRepeat, value.index)
        .whenComplete(setState),
  ),
  SwitchModel(
    title: '播放器设置仅对当前生效'.tr,
    subtitle: '弹幕、字幕及部分设置中没有的设置除外'.tr,
    leading: Icon(Icons.video_settings_outlined),
    setKey: SettingBoxKey.tempPlayerConf,
    defaultVal: false,
  ),
];

Future<void> _showSubtitleDialog(
  BuildContext context,
  VoidCallback setState,
) async {
  final res = await showDialog<SubtitlePrefType>(
    context: context,
    builder: (context) => SelectDialog<SubtitlePrefType>(
      title: '字幕选择偏好'.tr,
      value: Pref.subtitlePreferenceV2,
      values: SubtitlePrefType.values.map((e) => (e, e.desc)).toList(),
    ),
  );
  if (res != null) {
    await GStorage.setting.put(
      SettingBoxKey.subtitlePreferenceV2,
      res.index,
    );
    setState();
  }
}

Future<void> _showSuperChatTimeDialog(
  BuildContext context,
  VoidCallback setState,
) async {
  final res = await showDialog<SuperChatTimeType>(
    context: context,
    builder: (context) => SelectDialog<SuperChatTimeType>(
      title: 'SuperChat 发送时间显示'.tr,
      value: Pref.superChatTimeType,
      values: SuperChatTimeType.values.map((e) => (e, e.title)).toList(),
    ),
  );
  if (res != null) {
    await GStorage.setting.put(SettingBoxKey.superChatTimeType, res.index);
    setState();
  }
}

Future<void> _showSuperChatDialog(
  BuildContext context,
  VoidCallback setState,
) async {
  final res = await showDialog<SuperChatType>(
    context: context,
    builder: (context) => SelectDialog<SuperChatType>(
      title: 'SuperChat (醒目留言) 显示类型'.tr,
      value: Pref.superChatType,
      values: SuperChatType.values.map((e) => (e, e.title)).toList(),
    ),
  );
  if (res != null) {
    await GStorage.setting.put(SettingBoxKey.superChatType, res.index);
    setState();
  }
}

Future<void> _showFullScreenModeDialog(
  BuildContext context,
  VoidCallback setState,
) async {
  final res = await showDialog<FullScreenMode>(
    context: context,
    builder: (context) => SelectDialog<FullScreenMode>(
      title: '默认全屏方向'.tr,
      value: Pref.fullScreenMode,
      values: FullScreenMode.values.map((e) => (e, e.desc)).toList(),
    ),
  );
  if (res != null) {
    await GStorage.setting.put(SettingBoxKey.fullScreenMode, res.index);
    setState();
  }
}

Future<void> _showProgressBehaviorDialog(
  BuildContext context,
  VoidCallback setState,
) async {
  final res = await showDialog<BtmProgressBehavior>(
    context: context,
    builder: (context) => SelectDialog<BtmProgressBehavior>(
      title: '底部进度条展示'.tr,
      value: Pref.btmProgressBehavior,
      values: BtmProgressBehavior.values.map((e) => (e, e.desc)).toList(),
    ),
  );
  if (res != null) {
    await GStorage.setting.put(
      SettingBoxKey.btmProgressBehavior,
      res.index,
    );
    setState();
  }
}

Future<void> _showAngleDegreesDialog(
  BuildContext context,
  VoidCallback setState,
) async {
  final res = await showDialog<double>(
    context: context,
    builder: (context) => SliderDialog(
      title: Text('倾斜角度阈值'.tr),
      min: 10.0,
      max: 90.0,
      divisions: 90,
      precise: 0,
      value: Pref.angleDegrees.toDouble(),
      suffix: '°',
    ),
  );
  if (res != null) {
    await GStorage.setting.put(SettingBoxKey.angleDegrees, res.toInt());
    setState();
  }
}

Future<void> showPlayerVolumeDialog(
  BuildContext context,
  VoidCallback setState, {
  ValueChanged<double>? onChanged,
}) {
  if (Pref.enableAppVolume) {
    SmartDialog.showToast('应用内音量开启时，播放器音量设置不生效'.tr);
    return Future.value();
  }
  return showVolumeDialog(
    context,
    title: Text('播放器音量'.tr),
    value: Pref.playerVolume,
    onChanged: (value) => GStorage.setting
        .put(SettingBoxKey.playerVolume, value)
        .whenComplete(() {
          setState();
          onChanged?.call(value);
        }),
  );
}

Future<void> _showMaxVolumeDialog(
  BuildContext context,
  VoidCallback setState,
) {
  return showVolumeDialog(
    context,
    title: Text('最高音量'.tr),
    value: Pref.maxVolume * 100,
    onChanged: (rawValue) {
      final maxVolume = (rawValue / 100).toPrecision(2);
      if (Pref.desktopVolume > maxVolume) {
        GStorage.setting.put(SettingBoxKey.desktopVolume, maxVolume);
      }
      GStorage.setting
          .put(SettingBoxKey.maxVolume, maxVolume)
          .whenComplete(setState);
    },
  );
}

const kMinVolume = 100.0;
const kMaxVolume = 300.0;

Future<void> showVolumeDialog(
  BuildContext context, {
  required Widget title,
  required double value,
  required ValueChanged<double> onChanged,
}) async {
  final res = await showDialog<double>(
    context: context,
    builder: (context) => SliderDialog(
      title: title,
      min: kMinVolume,
      max: kMaxVolume,
      divisions: 40,
      precise: 0,
      value: value,
      suffix: '%',
    ),
  );
  if (res != null) {
    onChanged(res);
  }
}
