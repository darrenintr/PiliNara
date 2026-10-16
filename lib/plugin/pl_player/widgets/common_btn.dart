import 'package:PiliPlus/common/expressive/expressive_colors.dart';
import 'package:material_ui/material_ui.dart';

class ComBtn extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSecondaryTap;
  final double width;
  final double height;
  final String? tooltip;
  final bool expressive;

  const ComBtn({
    super.key,
    required this.icon,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTap,
    this.width = 34,
    this.height = 34,
    this.tooltip,
    this.expressive = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = SizedBox(
      width: width,
      height: height,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        onSecondaryTap: onSecondaryTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          alignment: Alignment.center,
          decoration: expressive
              ? ShapeDecoration(
                  color: ExpressiveColors.dark.surfaceContainerHigh.withValues(
                    alpha: 0.92,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(height / 2),
                    side: BorderSide(
                      color: ExpressiveColors.dark.outlineVariant.withValues(
                        alpha: 0.38,
                      ),
                    ),
                  ),
                )
              : null,
          child: icon,
        ),
      ),
    );
    if (tooltip != null) {
      return Tooltip(message: tooltip, child: child);
    }
    return child;
  }
}
