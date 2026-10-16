import 'package:PiliPlus/common/widgets/custom_arc.dart';
import 'package:PiliPlus/utils/extension/theme_ext.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:material_ui/material_ui.dart';

class ActionItem extends StatelessWidget {
  const ActionItem({
    super.key,
    required this.icon,
    this.selectIcon,
    this.onTap,
    this.onLongPress,
    this.text,
    this.selectStatus = false,
    required this.semanticsLabel,
    this.expand = true,
    this.animation,
    this.onStartTriple,
    this.onCancelTriple,
  }) : assert(!selectStatus || selectIcon != null),
       _isThumbsUp = onStartTriple != null;

  final Icon icon;
  final Icon? selectIcon;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? text;
  final bool selectStatus;
  final String semanticsLabel;
  final bool expand;
  final Animation<double>? animation;
  final VoidCallback? onStartTriple;
  final void Function([bool])? onCancelTriple;
  final bool _isThumbsUp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    late final primary = !expand && colorScheme.isLight
        ? colorScheme.inversePrimary
        : colorScheme.primary;
    // Inside a group the selected tile is filled with primary.
    final selectedFg = expand ? colorScheme.onPrimary : primary;
    Widget child = Icon(
      selectStatus ? selectIcon!.icon! : icon.icon,
      size: expand ? 20 : 18,
      color: selectStatus
          ? selectedFg
          : icon.color ??
                (expand ? colorScheme.onSurfaceVariant : colorScheme.outline),
      semanticLabel: semanticsLabel,
    );

    if (animation != null) {
      child = Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: animation!,
            builder: (context, child) =>
                Arc(size: 28, color: primary, progress: -animation!.value),
          ),
          child,
        ],
      );
    } else {
      child = SizedBox.square(dimension: 28, child: child);
    }

    child = Material(
      type: expand ? .canvas : .transparency,
      color: expand
          ? selectStatus
                ? colorScheme.primary
                : colorScheme.surfaceContainerHighest
          : null,
      borderRadius: expand ? const .all(.circular(10)) : null,
      clipBehavior: expand ? .antiAlias : .none,
      child: InkWell(
        borderRadius: expand ? null : const .all(.circular(6)),
        onTap: _isThumbsUp ? null : onTap,
        onLongPress: _isThumbsUp ? null : onLongPress,
        onSecondaryTap: PlatformUtils.isMobile || _isThumbsUp
            ? null
            : onLongPress,
        onTapDown: _isThumbsUp ? (_) => onStartTriple!() : null,
        onTapUp: _isThumbsUp ? (_) => onCancelTriple!(true) : null,
        onTapCancel: _isThumbsUp ? onCancelTriple : null,
        child: expand
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [child, _buildText(theme)],
              )
            : child,
      ),
    );
    return expand ? Expanded(child: child) : child;
  }

  Widget _buildText(ThemeData theme) {
    final hasText = text != null;
    final child = Text(
      hasText ? text! : '-',
      key: hasText ? ValueKey(text!) : null,
      style: TextStyle(
        color: selectStatus
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onSurfaceVariant,
        fontSize: 12,
        fontWeight: selectStatus ? FontWeight.w700 : null,
      ),
    );
    if (hasText) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) =>
            ScaleTransition(scale: animation, child: child),
        child: child,
      );
    }
    return child;
  }
}

/// Connected button group: tiles keep tight inner corners while the group
/// is clipped to a pill, so only the outer ends are fully rounded.
class ActionGroup extends StatelessWidget {
  const ActionGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: ClipRRect(
        borderRadius: const .all(.circular(32)),
        child: Row(spacing: 3, children: children),
      ),
    );
  }
}
