import 'dart:ui';

import 'package:flutter/material.dart';

@immutable
class LiquidGlassNavigationItem {
  const LiquidGlassNavigationItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// Caller-controlled navigation. Place in Scaffold.bottomNavigationBar with
/// extendBody enabled so content can be seen through the frosted surface.
class LiquidGlassBottomNavigation extends StatelessWidget {
  const LiquidGlassBottomNavigation({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    this.bottomSpacing = 14,
    super.key,
  }) : assert(items.length >= 2),
       assert(selectedIndex >= 0 && selectedIndex < items.length),
       assert(bottomSpacing >= 0);

  final List<LiquidGlassNavigationItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final double bottomSpacing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(36);
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 250);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, bottomSpacing),
        child: Align(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow.withValues(alpha: dark ? 0.16 : 0.07),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: radius,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      color: dark
                          ? colors.surface.withValues(alpha: 0.78)
                          : Colors.white.withValues(alpha: 0.72),
                      border: Border.all(
                        color: Colors.white.withValues(
                          alpha: dark ? 0.14 : 0.7,
                        ),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: dark ? 0.07 : 0.28),
                          Colors.white.withValues(alpha: 0),
                        ],
                      ),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        const gap = 4.0;
                        final compactWidth =
                            (constraints.maxWidth / items.length - gap).clamp(
                              40.0,
                              48.0,
                            );
                        final label = TextPainter(
                          text: TextSpan(
                            text: items[selectedIndex].label,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          textDirection: Directionality.of(context),
                          textScaler: MediaQuery.textScalerOf(context),
                        )..layout();
                        final available =
                            constraints.maxWidth -
                            (items.length - 1) * (compactWidth + gap);
                        final activeWidth = (label.width + 68).clamp(
                          compactWidth,
                          available < compactWidth ? compactWidth : available,
                        );
                        label.dispose();
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            for (var index = 0; index < items.length; index++)
                              _NavigationButton(
                                key: ValueKey(index),
                                item: items[index],
                                selected: selectedIndex == index,
                                width: selectedIndex == index
                                    ? activeWidth
                                    : compactWidth,
                                duration: duration,
                                onTap: () => onSelected(index),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigationButton extends StatefulWidget {
  const _NavigationButton({
    required this.item,
    required this.selected,
    required this.width,
    required this.duration,
    required this.onTap,
    super.key,
  });

  final LiquidGlassNavigationItem item;
  final bool selected;
  final double width;
  final Duration duration;
  final VoidCallback onTap;

  @override
  State<_NavigationButton> createState() => _NavigationButtonState();
}

class _NavigationButtonState extends State<_NavigationButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final radius = BorderRadius.circular(28);
    final foreground = widget.selected
        ? colors.primary
        : colors.onSurfaceVariant;

    return Semantics(
      label: widget.item.label,
      selected: widget.selected,
      button: true,
      child: Tooltip(
        message: widget.item.label,
        excludeFromSemantics: true,
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1,
          duration: widget.duration == Duration.zero
              ? Duration.zero
              : const Duration(milliseconds: 100),
          curve: Curves.easeInOutCubic,
          child: AnimatedContainer(
            duration: widget.duration,
            curve: Curves.easeInOutCubic,
            width: widget.width,
            constraints: const BoxConstraints(minHeight: 48),
            decoration: BoxDecoration(
              borderRadius: radius,
              color: colors.primary.withValues(
                alpha: widget.selected ? 0.12 : 0,
              ),
              border: Border.all(
                color: colors.primary.withValues(
                  alpha: widget.selected ? 0.1 : 0,
                ),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: radius,
                onTap: widget.onTap,
                onHighlightChanged: (pressed) =>
                    setState(() => _pressed = pressed),
                child: AnimatedPadding(
                  duration: widget.duration,
                  curve: Curves.easeInOutCubic,
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.selected ? 16 : 11,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      ExcludeSemantics(
                        child: Icon(
                          widget.item.icon,
                          size: 24,
                          color: foreground,
                        ),
                      ),
                      Flexible(
                        child: AnimatedSwitcher(
                          duration: widget.duration,
                          switchInCurve: Curves.easeInOutCubic,
                          switchOutCurve: Curves.easeInOutCubic,
                          layoutBuilder: (current, previous) => Stack(
                            alignment: AlignmentDirectional.centerStart,
                            children: [...previous, ?current],
                          ),
                          child: widget.selected
                              ? Padding(
                                  key: ValueKey(widget.item.label),
                                  padding: const EdgeInsetsDirectional.only(
                                    start: 8,
                                  ),
                                  child: ExcludeSemantics(
                                    child: Text(
                                      widget.item.label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(
                                            color: foreground,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
