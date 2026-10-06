import 'package:flutter/material.dart';

/// Renders the full-color brand without applying the surrounding icon color.
class AppIcon extends StatelessWidget {
  const AppIcon.asset(this.asset, {super.key, this.size, this.semanticLabel});

  final String asset;
  final double? size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final effectiveSize = size ?? iconTheme.size ?? 24;
    return Image.asset(
      asset,
      width: effectiveSize,
      height: effectiveSize,
      fit: BoxFit.contain,
      semanticLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
    );
  }
}
