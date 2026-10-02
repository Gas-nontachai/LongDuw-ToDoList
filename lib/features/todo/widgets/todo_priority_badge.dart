import 'package:flutter/material.dart';

import '../../../core/config/priority_config.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/design/app_icons.dart';

class TodoPriorityBadge extends StatelessWidget {
  const TodoPriorityBadge({
    required this.priority,
    this.compact = false,
    super.key,
  });

  final String priority;
  final bool compact;

  static const _colors = {
    PriorityConfig.low: (
      background: Color(0xFFE1F4EB),
      foreground: Color(0xFF316D55),
      darkBackground: Color(0xFF263E34),
      darkForeground: Color(0xFFB4E3CD),
    ),
    PriorityConfig.medium: (
      background: Color(0xFFFFF0D6),
      foreground: Color(0xFF856020),
      darkBackground: Color(0xFF443A28),
      darkForeground: Color(0xFFF2D59E),
    ),
    PriorityConfig.high: (
      background: Color(0xFFFBE3E9),
      foreground: Color(0xFF99475C),
      darkBackground: Color(0xFF462E37),
      darkForeground: Color(0xFFF1BBCA),
    ),
  };

  @override
  Widget build(BuildContext context) {
    final colors = _colors[priority];
    if (colors == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final label = PriorityConfig.options(l10n)[priority]!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = isDark ? colors.darkForeground : colors.foreground;

    if (compact) {
      return Tooltip(
        message: '${l10n.priority}: $label',
        child: Semantics(
          label: '${l10n.priority}: $label',
          excludeSemantics: true,
          child: Icon(AppIcons.priority, size: 18, color: foreground),
        ),
      );
    }

    return Semantics(
      label: '${l10n.priority}: $label',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? colors.darkBackground : colors.background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.priority, size: 15, color: foreground),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: foreground, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
