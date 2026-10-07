import 'package:flutter/material.dart';

/// Decorative vector artwork, drawn with Flutter shapes and icons.
class BackupIllustration extends StatelessWidget {
  const BackupIllustration({super.key, this.overview = false});

  final bool overview;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: SizedBox(
        height: 200,
        child: Center(
          child: SizedBox(
            width: 280,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 30,
                  child: Icon(
                    Icons.cloud_rounded,
                    size: 210,
                    color: colors.primary.withValues(alpha: .07),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  child: Container(
                    width: 240,
                    height: 24,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: .06),
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
                if (overview) ...[
                  Positioned(
                    left: 30,
                    bottom: 30,
                    child: Transform.rotate(
                      angle: -.25,
                      child: _Document(colors: colors, small: true),
                    ),
                  ),
                  Positioned(
                    right: 30,
                    bottom: 30,
                    child: Transform.rotate(
                      angle: .25,
                      child: _Document(colors: colors, small: true),
                    ),
                  ),
                  Positioned(
                    bottom: 25,
                    child: Icon(
                      Icons.storage_rounded,
                      size: 80,
                      color: colors.onSurfaceVariant.withValues(alpha: .7),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.cloud_rounded,
                          size: 125,
                          color: colors.primary,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Icon(
                            Icons.swap_vert_rounded,
                            size: 40,
                            color: colors.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  _Document(colors: colors),
                  Positioned(
                    right: 38,
                    bottom: 22,
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colors.primary,
                            colors.primary.withValues(alpha: .8),
                          ],
                        ),
                        border: Border.all(color: colors.surface, width: 3),
                      ),
                      child: Icon(
                        Icons.arrow_upward_rounded,
                        size: 38,
                        color: colors.onPrimary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Document extends StatelessWidget {
  const _Document({required this.colors, this.small = false});

  final ColorScheme colors;
  final bool small;

  @override
  Widget build(BuildContext context) => Container(
    width: small ? 46 : 112,
    height: small ? 60 : 140,
    padding: EdgeInsets.all(small ? 8 : 18),
    decoration: BoxDecoration(
      color: colors.surface,
      borderRadius: BorderRadius.circular(small ? 8 : 22),
      border: Border.all(color: colors.outlineVariant),
      boxShadow: [
        BoxShadow(
          color: colors.primary.withValues(alpha: .08),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        3,
        (_) => Row(
          children: [
            if (!small) ...[
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.onSurfaceVariant.withValues(alpha: .35),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Container(
                height: small ? 4 : 8,
                decoration: BoxDecoration(
                  color: colors.onSurfaceVariant.withValues(alpha: .25),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
