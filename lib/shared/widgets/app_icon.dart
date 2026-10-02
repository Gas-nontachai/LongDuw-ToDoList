import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Renders a monochrome app asset using the surrounding icon theme by default.
class AppIcon extends StatelessWidget {
  const AppIcon.asset(
    this.asset, {
    super.key,
    this.size,
    this.color,
    this.semanticLabel,
  });

  final String asset;
  final double? size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final effectiveSize = size ?? iconTheme.size ?? 24;
    final effectiveColor =
        color ?? iconTheme.color ?? Theme.of(context).colorScheme.onSurface;
    final opacity = iconTheme.opacity ?? 1;

    return SvgPicture.asset(
      asset,
      width: effectiveSize,
      height: effectiveSize,
      colorFilter: ColorFilter.mode(
        effectiveColor.withValues(alpha: effectiveColor.a * opacity),
        BlendMode.srcIn,
      ),
      semanticsLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
    );
  }
}
