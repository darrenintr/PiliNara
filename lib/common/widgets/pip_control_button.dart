import 'package:PiliPlus/common/expressive/expressive_colors.dart';
import 'package:PiliPlus/common/style.dart';
import 'package:material_ui/material_ui.dart';

/// 小窗控制按钮:固定触控目标 + hover 高亮。
///
/// 参照安卓系统 PiP 的按键触控设计:
/// - 主操作(底部播放/暂停/±10秒)用 [targetSize] 默认 48dp 的触控目标,
///   图标居中四周留白——与 AOSP `pip_action_size=48dp` 一致,便于手指盲操;
/// - 次要操作(关闭/还原)传小 [targetSize],仅比图标大一圈,降低误触。
///
/// 触控目标由外层布局约束自适应:小窗较窄(竖屏视频/最小缩放)时会被
/// 约束收缩,不会溢出。桌面鼠标 hover 时使用 Expressive 主色回馈,
/// 同时直观展示触控范围。
///
/// 注意:GestureDetector 默认 deferToChild 下,Padding 空白区不参与命中,
/// 因此必须 [HitTestBehavior.opaque] 让整个盒子可点——否则触控目标会
/// 缩回图标本身大小。
class PipControlButton extends StatefulWidget {
  final Widget icon;
  final VoidCallback? onTap;
  final double targetSize;
  final bool isPrimary;

  const PipControlButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.targetSize = 48,
    this.isPrimary = false,
  });

  @override
  State<PipControlButton> createState() => _PipControlButtonState();
}

class _PipControlButtonState extends State<PipControlButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    const colors = ExpressiveColors.dark;
    final surface = widget.isPrimary
        ? colors.primaryContainer
        : colors.surfaceContainerHigh.withValues(alpha: 0.94);
    final foreground = widget.isPrimary
        ? _hovering
              ? colors.onPrimary
              : colors.onPrimaryContainer
        : colors.onSurface;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: SizedBox.square(
          dimension: widget.targetSize,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            decoration: ShapeDecoration(
              color: _hovering
                  ? widget.isPrimary
                        ? colors.primary
                        : colors.primary.withValues(alpha: 0.24)
                  : surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  widget.targetSize >= 40 ? Style.radiusLg : Style.radiusSm,
                ),
                side: BorderSide(
                  color: widget.isPrimary
                      ? colors.primary.withValues(alpha: 0.46)
                      : colors.outlineVariant.withValues(alpha: 0.46),
                ),
              ),
            ),
            child: Center(
              child: IconTheme.merge(
                data: IconThemeData(color: foreground),
                child: widget.icon,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
