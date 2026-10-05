import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

@immutable
class LiquidGlassNavigationItem {
  const LiquidGlassNavigationItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// Caller-controlled navigation. Place in Scaffold.bottomNavigationBar with
/// extendBody enabled so content can be seen through the frosted surface.
class LiquidGlassBottomNavigation extends StatefulWidget {
  const LiquidGlassBottomNavigation({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    this.isCompact = false,
    this.onTapOutside,
    this.bottomSpacing = 14,
    super.key,
  }) : assert(items.length >= 2),
       assert(selectedIndex >= 0 && selectedIndex < items.length),
       assert(bottomSpacing >= 0);

  final List<LiquidGlassNavigationItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool isCompact;

  /// Called after an actual outside tap, without consuming the gesture.
  /// Drags are excluded so horizontal page swipes do not collapse navigation.
  final VoidCallback? onTapOutside;
  final double bottomSpacing;

  @override
  State<LiquidGlassBottomNavigation> createState() =>
      _LiquidGlassBottomNavigationState();
}

class _LiquidGlassBottomNavigationState
    extends State<LiquidGlassBottomNavigation> {
  final Map<int, Offset> _outsidePointers = {};

  void _trackOutsideTap(PointerDownEvent event) {
    if (widget.onTapOutside == null) return;
    // TapRegion also synthesizes pointer-zero downs for accessibility actions;
    // those are complete taps with no matching pointer-up event.
    if (event.pointer == 0) {
      widget.onTapOutside?.call();
      return;
    }
    _outsidePointers[event.pointer] = event.position;
    GestureBinding.instance.pointerRouter.addRoute(
      event.pointer,
      _handlePointer,
    );
  }

  void _stopTracking(int pointer) {
    _outsidePointers.remove(pointer);
    GestureBinding.instance.pointerRouter.removeRoute(pointer, _handlePointer);
  }

  void _handlePointer(PointerEvent event) {
    final origin = _outsidePointers[event.pointer];
    if (origin == null) return;
    if (event is PointerCancelEvent ||
        (event.position - origin).distance > kTouchSlop) {
      _stopTracking(event.pointer);
    } else if (event is PointerUpEvent) {
      _stopTracking(event.pointer);
      widget.onTapOutside?.call();
    }
  }

  @override
  void dispose() {
    for (final pointer in _outsidePointers.keys.toList()) {
      _stopTracking(pointer);
    }
    super.dispose();
  }

  Widget _animateSize({required Widget child, required Duration duration}) {
    if (duration == Duration.zero) return child;
    return AnimatedSize(
      duration: duration,
      curve: Curves.easeInOutCubic,
      alignment: Alignment.bottomCenter,
      child: child,
    );
  }

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
        padding: EdgeInsets.fromLTRB(16, 0, 16, widget.bottomSpacing),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const compactItemWidth = 48.0;
            const gap = 4.0;
            final expandedWidth = math.min(constraints.maxWidth, 440.0);
            final compactBarWidth =
                compactItemWidth * widget.items.length +
                gap * (widget.items.length - 1) +
                14;
            final label = TextPainter(
              text: TextSpan(
                text: widget.items[widget.selectedIndex].label,
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              textDirection: Directionality.of(context),
              textScaler: MediaQuery.textScalerOf(context),
            )..layout();
            // Derive button targets from the full viewport, not the animated
            // shell width, so both transitions remain synchronized.
            final available =
                expandedWidth -
                18 -
                (widget.items.length - 1) * (compactItemWidth + gap);
            final activeWidth = (label.width + 68)
                .clamp(compactItemWidth, math.max(compactItemWidth, available))
                .toDouble();
            label.dispose();

            return Align(
              heightFactor: 1,
              alignment: Alignment.bottomCenter,
              child: TapRegion(
                onTapOutside: _trackOutsideTap,
                child: _animateSize(
                  duration: duration,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      boxShadow: [
                        BoxShadow(
                          color: colors.shadow.withValues(
                            alpha: dark ? 0.16 : 0.07,
                          ),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: radius,
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                        child: AnimatedContainer(
                          duration: duration,
                          curve: Curves.easeInOutCubic,
                          width: widget.isCompact
                              ? math.min(compactBarWidth, expandedWidth)
                              : expandedWidth,
                          padding: EdgeInsets.all(widget.isCompact ? 6 : 8),
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
                                Colors.white.withValues(
                                  alpha: dark ? 0.07 : 0.28,
                                ),
                                Colors.white.withValues(alpha: 0),
                              ],
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              for (
                                var index = 0;
                                index < widget.items.length;
                                index++
                              )
                                _NavigationButton(
                                  key: ValueKey(index),
                                  item: widget.items[index],
                                  selected: widget.selectedIndex == index,
                                  isCompact: widget.isCompact,
                                  width:
                                      !widget.isCompact &&
                                          widget.selectedIndex == index
                                      ? activeWidth
                                      : compactItemWidth,
                                  duration: duration,
                                  onTap: () => widget.onSelected(index),
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
          },
        ),
      ),
    );
  }
}

class _NavigationButton extends StatefulWidget {
  const _NavigationButton({
    required this.item,
    required this.selected,
    required this.isCompact,
    required this.width,
    required this.duration,
    required this.onTap,
    super.key,
  });

  final LiquidGlassNavigationItem item;
  final bool selected;
  final bool isCompact;
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
    final showLabel = widget.selected && !widget.isCompact;
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
                alpha: widget.selected ? (widget.isCompact ? 0.06 : 0.12) : 0,
              ),
            ),
            foregroundDecoration: BoxDecoration(
              borderRadius: radius,
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
                    horizontal: showLabel ? 16 : 11,
                    vertical: widget.isCompact ? 11 : 12,
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
                          child: showLabel
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
