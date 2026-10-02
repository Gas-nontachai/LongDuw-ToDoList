import 'package:flutter/material.dart';

import '../design/app_icons.dart';

/// A sort menu whose selected value and options are owned by the caller.
class AppSortButton<T> extends StatelessWidget {
  const AppSortButton({
    required this.value,
    required this.options,
    required this.tooltip,
    required this.onChanged,
    this.isActive = false,
    super.key,
  }) : assert(options.length > 0);

  final T value;
  final Map<T, String> options;
  final String tooltip;
  final ValueChanged<T> onChanged;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return PopupMenuButton<T>(
      tooltip: '$tooltip: ${options[value]}',
      initialValue: value,
      icon: const Icon(AppIcons.sort),
      style: IconButton.styleFrom(
        foregroundColor: isActive ? colors.primary : colors.onSurfaceVariant,
        backgroundColor: colors.surfaceContainerLow,
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.outlineVariant),
        ),
      ),
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final option in options.entries)
          CheckedPopupMenuItem<T>(
            value: option.key,
            checked: value == option.key,
            child: Text(option.value),
          ),
      ],
    );
  }
}
