import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

String themeModeLabel(AppLocalizations l10n, ThemeMode mode) => switch (mode) {
  ThemeMode.system => l10n.appThemeSystem,
  ThemeMode.light => l10n.appThemeLight,
  ThemeMode.dark => l10n.appThemeDark,
};

IconData themeModeIcon(ThemeMode mode) => switch (mode) {
  ThemeMode.system => Icons.devices_outlined,
  ThemeMode.light => Icons.light_mode_outlined,
  ThemeMode.dark => Icons.dark_mode_outlined,
};

/// Shared options for onboarding and Settings, wrapping at large text sizes.
class AppThemeSelector extends StatelessWidget {
  const AppThemeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });
  final ThemeMode value;
  final ValueChanged<ThemeMode>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final labelStyle = theme.textTheme.labelLarge!.copyWith(
      fontWeight: FontWeight.w600,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        var minimumWidth = 96.0;
        for (final mode in ThemeMode.values) {
          final painter = TextPainter(
            text: TextSpan(text: themeModeLabel(l10n, mode), style: labelStyle),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
          )..layout();
          final requiredWidth = painter.width + 32;
          if (requiredWidth > minimumWidth) minimumWidth = requiredWidth;
          painter.dispose();
        }
        final availableWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : minimumWidth * 3 + 16;
        final columns = ((availableWidth + 8) / (minimumWidth + 8))
            .floor()
            .clamp(1, 3);
        final width = (availableWidth - 8 * (columns - 1)) / columns;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final mode in ThemeMode.values)
              SizedBox(
                width: width,
                child: ChoiceChip(
                  // Material's default selected check replaces/overlays avatars.
                  // Keep the mode icon visible and place the check separately.
                  showCheckmark: false,
                  labelPadding: EdgeInsets.zero,
                  padding: const EdgeInsets.all(12),
                  backgroundColor: colors.surface,
                  selectedColor: colors.primaryContainer,
                  side: BorderSide(
                    color: value == mode
                        ? colors.primary
                        : colors.outlineVariant,
                    width: 1.5,
                  ),
                  label: SizedBox(
                    width: (width - 24).clamp(0, double.infinity),
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              themeModeIcon(mode),
                              size: 24,
                              color: value == mode
                                  ? colors.primary
                                  : colors.onSurfaceVariant,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              themeModeLabel(l10n, mode),
                              textAlign: TextAlign.center,
                              style: labelStyle.copyWith(
                                color: value == mode
                                    ? colors.onPrimaryContainer
                                    : colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        if (value == mode)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Icon(
                              Icons.check_circle,
                              size: 16,
                              color: colors.primary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  selected: value == mode,
                  onSelected: onChanged == null
                      ? null
                      : (_) => onChanged!(mode),
                ),
              ),
          ],
        );
      },
    );
  }
}
