import 'package:PiliPlus/models/common/enum_with_label.dart';
import 'package:get/get.dart';

enum ArchiveOrderTypeApp with EnumWithLabel {
  pubdate('最新发布'),
  click('最多播放'),
  ;

  @override
  final String label;
  const ArchiveOrderTypeApp(this.label);
}
