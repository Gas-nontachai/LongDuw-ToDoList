import 'package:flutter/material.dart';

/// An evenly spaced segmented selector. The caller owns the selected index.
class AppTabBar extends StatelessWidget {
  const AppTabBar({
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
    super.key,
  }) : assert(tabs.length > 0),
       assert(selectedIndex >= 0 && selectedIndex < tabs.length);

  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    const duration = Duration(milliseconds: 200);
    final tabRadius = BorderRadius.circular(18);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          for (var index = 0; index < tabs.length; index++)
            Expanded(
              child: Semantics(
                selected: index == selectedIndex,
                button: true,
                child: AnimatedContainer(
                  duration: duration,
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    color: index == selectedIndex
                        ? colors.surface
                        : colors.surface.withValues(alpha: 0),
                    borderRadius: tabRadius,
                    boxShadow: index == selectedIndex
                        ? [
                            BoxShadow(
                              color: colors.shadow.withValues(alpha: 0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : const [],
                  ),
                  child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      borderRadius: tabRadius,
                      onTap: () => onChanged(index),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 32),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          child: Center(
                            heightFactor: 1,
                            child: AnimatedDefaultTextStyle(
                              duration: duration,
                              curve: Curves.easeInOut,
                              style:
                                  (theme.textTheme.labelLarge ??
                                          const TextStyle())
                                      .copyWith(
                                        color: index == selectedIndex
                                            ? colors.onSurface
                                            : colors.onSurfaceVariant,
                                        fontWeight: index == selectedIndex
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                      ),
                              child: Text(
                                tabs[index],
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
