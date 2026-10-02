import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/design/app_icons.dart';

/// Shared actions and styling for todo menus, with an optional custom anchor.
class TodoActionsMenu extends StatefulWidget {
  const TodoActionsMenu({
    required this.onEdit,
    required this.onDelete,
    this.onView,
    this.enabled = true,
    this.animated = true,
    this.alignment = Alignment.topRight,
    this.alignmentOffset = Offset.zero,
    this.onOpen,
    this.onClose,
    this.onAnimationStatusChanged,
    this.builder,
    super.key,
  });

  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onView;
  final bool enabled;

  /// Animates both opening and closing using Flutter's Material menu motion.
  /// System reduced-motion settings take precedence.
  final bool animated;

  /// Preferred menu alignment relative to the anchor. Flutter adjusts the
  /// position when necessary to keep the menu within the viewport.
  final AlignmentGeometry alignment;

  /// Fine-tunes placement; positive dy moves the menu downward.
  final Offset alignmentOffset;
  final VoidCallback? onOpen;
  final VoidCallback? onClose;
  final ValueChanged<AnimationStatus>? onAnimationStatusChanged;

  /// [toggleMenu] is null while actions are disabled.
  final Widget Function(BuildContext context, VoidCallback? toggleMenu)?
  builder;

  @override
  State<TodoActionsMenu> createState() => _TodoActionsMenuState();
}

class _TodoActionsMenuState extends State<TodoActionsMenu> {
  AnimationStatus _animationStatus = AnimationStatus.dismissed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    return MenuAnchor(
      consumeOutsideTap: true,
      animated: widget.animated && !MediaQuery.disableAnimationsOf(context),
      alignmentOffset: widget.alignmentOffset,
      onOpen: widget.onOpen,
      onClose: widget.onClose,
      onAnimationStatusChanged: (status) {
        _animationStatus = status;
        widget.onAnimationStatusChanged?.call(status);
      },
      style: MenuStyle(
        alignment: widget.alignment,
        backgroundColor: WidgetStatePropertyAll(colors.surface),
        elevation: const WidgetStatePropertyAll(12),
        padding: const WidgetStatePropertyAll(EdgeInsets.all(8)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
      menuChildren: [
        if (widget.onView != null) ...[
          MenuItemButton(
            leadingIcon: const Icon(CupertinoIcons.eye),
            onPressed: widget.enabled ? widget.onView : null,
            child: Text(l10n.viewTodo),
          ),
          const Divider(height: 1),
        ],
        MenuItemButton(
          leadingIcon: const Icon(AppIcons.edit),
          onPressed: widget.enabled ? widget.onEdit : null,
          child: Text(l10n.editTooltip),
        ),
        const Divider(height: 1),
        MenuItemButton(
          leadingIcon: Icon(AppIcons.delete, color: colors.error),
          onPressed: widget.enabled ? widget.onDelete : null,
          child: Text(
            l10n.deleteTooltip,
            style: TextStyle(color: colors.error),
          ),
        ),
      ],
      builder: (context, controller, child) {
        final VoidCallback? toggleMenu = widget.enabled
            ? () {
                if (_animationStatus.isForwardOrCompleted) {
                  controller.close();
                } else {
                  controller.open();
                }
              }
            : null;

        final anchor =
            widget.builder?.call(context, toggleMenu) ??
            IconButton(
              tooltip: l10n.moreActions,
              icon: const Icon(Icons.more_vert),
              style: IconButton.styleFrom(
                minimumSize: const Size(48, 48),
                foregroundColor: colors.onSurfaceVariant,
              ),
              onPressed: toggleMenu,
            );

        // A custom anchor can be the entire todo row. It belongs to the menu's
        // tap region, so outside-tap consumption alone cannot block its actions.
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: controller.isOpen ? controller.close : null,
          child: AbsorbPointer(absorbing: controller.isOpen, child: anchor),
        );
      },
    );
  }
}
