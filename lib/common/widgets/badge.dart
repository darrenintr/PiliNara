import 'package:PiliPlus/common/expressive/expressive_colors.dart';
import 'package:PiliPlus/models/common/badge_type.dart';
import 'package:PiliPlus/utils/extension/string_ext.dart';
import 'package:PiliPlus/utils/extension/theme_ext.dart';
import 'package:material_ui/material_ui.dart';

class PBadge extends StatelessWidget {
  final String? text;

  final bool isStack;
  final double? top;
  final double? right;
  final double? bottom;
  final double? left;
  final EdgeInsets? padding;

  final PBadgeType type;
  final PBadgeSize size;

  final double fontSize;
  final bool isBold;
  final double? textScaleFactor;

  const PBadge({
    super.key,
    required this.text,
    this.top,
    this.right,
    this.bottom,
    this.left,
    this.type = PBadgeType.primary,
    this.size = PBadgeSize.medium,
    this.isStack = true,
    this.fontSize = 11,
    this.isBold = true,
    this.textScaleFactor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    if (text.isNullOrEmpty) {
      return const SizedBox.shrink();
    }

    ColorScheme theme = Theme.of(context).colorScheme;

    Color bgColor;
    Color color;
    Color borderColor = Colors.transparent;

    switch (type) {
      case PBadgeType.primary:
        bgColor = theme.primary;
        color = theme.onPrimary;
      case PBadgeType.secondary:
        bgColor = theme.tertiaryContainer;
        color = theme.onTertiaryContainer;
      case PBadgeType.gray:
        bgColor = ExpressiveColors.thumbScrim;
        color = Colors.white;
      case PBadgeType.error:
        if (theme.isDark) {
          bgColor = theme.errorContainer;
          color = theme.onErrorContainer;
        } else {
          bgColor = theme.error;
          color = theme.onError;
        }
      case PBadgeType.line_primary:
        color = theme.primary;
        bgColor = Colors.transparent;
        borderColor = theme.primary;
      case PBadgeType.line_secondary:
        color = theme.secondary;
        bgColor = Colors.transparent;
        borderColor = theme.secondary;
      case PBadgeType.free:
        bgColor = theme.freeColor;
        color = Colors.white;
      case PBadgeType.shop:
        bgColor = theme.secondaryContainer.withValues(alpha: 0.5);
        color = theme.onSurfaceVariant;
    }

    // Overlay badges on thumbnails are pills, inline tags are soft squares.
    final isPill =
        type == PBadgeType.gray || (isStack && type == PBadgeType.primary);
    late EdgeInsets paddingStyle = isPill
        ? const .symmetric(vertical: 3, horizontal: 7)
        : const .symmetric(vertical: 2, horizontal: 5);
    final BorderRadius br = isPill
        ? const .all(.circular(11))
        : size == .small
        ? const .all(.circular(5))
        : const .all(.circular(6));

    Widget content = Container(
      padding: padding ?? paddingStyle,
      decoration: BoxDecoration(
        borderRadius: br,
        color: bgColor,
        border: .all(color: borderColor),
      ),
      child: Text(
        text!,
        textScaler: textScaleFactor != null ? .linear(textScaleFactor!) : null,
        style: TextStyle(
          height: 1,
          fontSize: fontSize,
          color: color,
          fontWeight: isBold ? FontWeight.bold : null,
        ),
        strutStyle: StrutStyle(
          leading: 0,
          height: 1,
          fontSize: fontSize,
          fontWeight: isBold ? FontWeight.bold : null,
        ),
      ),
    );
    if (isStack) {
      return Positioned(
        top: top,
        left: left,
        right: right,
        bottom: bottom,
        child: content,
      );
    } else {
      return content;
    }
  }
}
