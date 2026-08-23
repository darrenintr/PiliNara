import 'package:flutter/material.dart';

/// 应用语言选项
///
/// `system` 表示跟随系统；其余为显式指定的语言。
/// 使用与 bilibili API 一致的 `xx_YY` 形式以便直接拼到 `c_locale`/`s_locale`。
enum AppLocaleType {
  system('跟随系统', 'sys'),
  zhCN('简体中文', 'zh_CN'),
  zhTW('繁體中文', 'zh_TW'),
  enUS('English', 'en_US');

  final String label;
  final String apiCode;
  const AppLocaleType(this.label, this.apiCode);

  /// 转为 Flutter [Locale]
  Locale? get locale => switch (this) {
        AppLocaleType.system => null,
        AppLocaleType.zhCN => const Locale('zh', 'CN'),
        AppLocaleType.zhTW => const Locale('zh', 'TW'),
        AppLocaleType.enUS => const Locale('en', 'US'),
      };

  /// 当前选项对应的 bilibili API `c_locale`/`s_locale` 字符串
  ///
  /// `system` 时回退到简体中文，避免传入无法识别的 `sys`。
  String get effectiveApiCode => switch (this) {
        AppLocaleType.system => AppLocaleType.zhCN.apiCode,
        AppLocaleType.zhCN => AppCode.zhCN,
        AppLocaleType.zhTW => AppCode.zhTW,
        AppLocaleType.enUS => AppCode.enUS,
      };

  /// 给定当前 Flutter [Locale]，解析出对应的 API locale 字符串
  ///
  /// 已知 `zh_*` 都归到 zh_CN/zh_TW，其它（如 en_*、空值、null）回退到 zh_CN。
  static String resolveApiCode(Locale? locale) {
    final language = locale?.languageCode.toLowerCase();
    final country = locale?.countryCode?.toUpperCase();
    if (language == 'zh') {
      if (country == 'TW' || country == 'HK' || country == 'MO') {
        return AppCode.zhTW;
      }
      return AppCode.zhCN;
    }
    if (language == 'en') {
      return AppCode.enUS;
    }
    return AppCode.zhCN;
  }
}

/// 统一的 API locale 字符串常量
class AppCode {
  static const String zhCN = 'zh_CN';
  static const String zhTW = 'zh_TW';
  static const String enUS = 'en_US';
}
