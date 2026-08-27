import 'package:PiliPlus/models/common/app_locale_type.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

/// 根据当前应用语言推导的 bilibili API locale 字符串（用于 `c_locale`/`s_locale`）。
///
/// 读取顺序：
/// 1. 用户在设置中显式选定的语言（[Pref.appLocale]）
/// 2. 当前生效的 [Get.locale]（即 `GetMaterialApp.locale`）
/// 3. [Get.deviceLocale]
/// 4. 回退到简体中文 `zh_CN`
String currentApiLocaleCode() {
  final explicit = Pref.appLocale;
  if (explicit != AppLocaleType.system) {
    return explicit.effectiveApiCode;
  }
  final fromGet = Get.locale;
  if (fromGet != null) {
    return AppLocaleType.resolveApiCode(fromGet);
  }
  return AppLocaleType.resolveApiCode(Get.deviceLocale);
}

/// 取当前生效的 [Locale]（用户设置 → Get.locale → Get.deviceLocale → zh_CN）
Locale currentAppLocale() {
  final type = Pref.appLocale;
  final explicit = type.locale;
  if (explicit != null) return explicit;
  final fromGet = Get.locale;
  if (fromGet != null) return fromGet;
  final device = Get.deviceLocale;
  if (device != null) return device;
  return const Locale('zh', 'CN');
}
