import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

enum AppToastType { success, error, loading }

// รูปแบบ animation ที่ toast รองรับ
enum AppToastAnimation { fade, slide, scale, slideAndFade }

AppToastHandle showAppToast(
  BuildContext context,
  String message, {
  AppToastType type = AppToastType.success,
  // ใช้กำหนดตำแหน่งของ toast บนหน้าจอ เช่น topRight หรือ bottomCenter
  Alignment alignment = Alignment.topCenter,
  // กำหนดความกว้างของ toast โดยไม่ต้องให้เต็มหน้าจอ
  double width = 360,
  // เลือก animation ตอน toast แสดงเข้าและถูก dismiss ออกแยกกันได้
  AppToastAnimation animationIn = AppToastAnimation.slideAndFade,
  AppToastAnimation animationOut = AppToastAnimation.slideAndFade,
  Duration inDuration = const Duration(milliseconds: 240),
  Duration outDuration = const Duration(milliseconds: 180),
  Curve inCurve = Curves.easeOut,
  Curve outCurve = Curves.easeIn,
  // ส่ง null สำหรับ toast ที่ต้องค้างไว้จนกว่าจะสั่ง dismiss เอง
  Duration? duration = const Duration(seconds: 3),
}) {
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return AppToastHandle._empty();

  final handle = AppToastHandle._();

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _AppToastOverlay(
      message: message,
      type: type,
      onDismissed: entry.remove,
      alignment: alignment,
      width: width,
      animationIn: animationIn,
      animationOut: animationOut,
      inDuration: inDuration,
      outDuration: outDuration,
      inCurve: inCurve,
      outCurve: outCurve,
      duration: duration,
    ),
  );
  handle._entry = entry;
  overlay.insert(entry);
  return handle;
}

/// Handle สำหรับสั่งปิด toast จากภายนอก เช่น เมื่อ loading เสร็จแล้ว
class AppToastHandle {
  AppToastHandle._();
  AppToastHandle._empty();

  OverlayEntry? _entry;

  void dismiss() {
    final entry = _entry;
    _entry = null;
    // เรียก remove ได้แม้ toast ยังไม่ทัน render frame แรก
    entry?.remove();
  }
}

class _AppToastOverlay extends StatefulWidget {
  const _AppToastOverlay({
    required this.message,
    required this.type,
    required this.onDismissed,
    required this.alignment,
    required this.width,
    required this.animationIn,
    required this.animationOut,
    required this.inDuration,
    required this.outDuration,
    required this.inCurve,
    required this.outCurve,
    required this.duration,
  });

  final String message;
  final AppToastType type;
  final VoidCallback onDismissed;
  final Alignment alignment;
  final double width;
  final AppToastAnimation animationIn;
  final AppToastAnimation animationOut;
  final Duration inDuration;
  final Duration outDuration;
  final Curve inCurve;
  final Curve outCurve;
  final Duration? duration;

  @override
  State<_AppToastOverlay> createState() => _AppToastOverlayState();
}

class _AppToastOverlayState extends State<_AppToastOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.inDuration,
    reverseDuration: widget.outDuration,
  )..forward();
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    // loading toast จะส่ง duration เป็น null เพื่อไม่ให้หายเอง
    if (widget.duration != null) {
      _dismissTimer = Timer(widget.duration!, _dismiss);
    }
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    _dismissTimer?.cancel();
    await _controller.reverse();
    if (mounted) widget.onDismissed();
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isError = widget.type == AppToastType.error;
    final isLoading = widget.type == AppToastType.loading;
    final accentColor = isError ? colorScheme.error : colorScheme.primary;

    // Positioned.fill ทำให้เราครอบคลุมพื้นที่ของ Overlay ทั้งจอ
    // แล้วใช้ Align เลือกตำแหน่งแทนการกำหนด left/right แบบเดิม
    return Positioned.fill(
      child: SafeArea(
        child: Align(
          alignment: widget.alignment,
          child: Padding(
            padding: const EdgeInsets.all(16),
            // ป้องกัน toast ล้นจอบนมือถือจอแคบ
            child: SizedBox(
              width: math.min(
                widget.width,
                MediaQuery.sizeOf(context).width - 32,
              ),
              child: Dismissible(
                key: const ValueKey('app-toast'),
                direction: DismissDirection.up,
                onDismissed: (_) => widget.onDismissed(),
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final isExiting =
                        _controller.status == AnimationStatus.reverse;
                    final animation = isExiting
                        ? widget.animationOut
                        : widget.animationIn;
                    final curve = isExiting ? widget.outCurve : widget.inCurve;
                    final progress = curve.transform(_controller.value);

                    // ตอนเข้า value จะวิ่ง 0 -> 1 และตอนออกจะวิ่ง 1 -> 0
                    final slideProgress = 1 - progress;
                    final opacity =
                        animation == AppToastAnimation.slide ||
                            animation == AppToastAnimation.scale
                        ? 1.0
                        : progress;
                    final scale = animation == AppToastAnimation.scale
                        ? 0.92 + (0.08 * progress)
                        : 1.0;
                    final offset =
                        animation == AppToastAnimation.slide ||
                            animation == AppToastAnimation.slideAndFade
                        ? Offset(0, -0.35 * slideProgress)
                        : Offset.zero;

                    return Opacity(
                      opacity: opacity,
                      child: Transform.translate(
                        offset: Offset(
                          offset.dx * MediaQuery.sizeOf(context).width,
                          offset.dy * 80,
                        ),
                        child: Transform.scale(scale: scale, child: child),
                      ),
                    );
                  },
                  child: Material(
                    color: colorScheme.surface,
                    elevation: 6,
                    shadowColor: colorScheme.shadow.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(14),
                    clipBehavior: Clip.antiAlias,
                    child: Semantics(
                      liveRegion: true,
                      label: widget.message,
                      child: IntrinsicHeight(
                        child: Row(
                          children: [
                            Container(width: 5, color: accentColor),
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: isLoading
                                  ? SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: accentColor,
                                      ),
                                    )
                                  : Icon(
                                      isError
                                          ? Icons.error_outline_rounded
                                          : Icons.check_circle_outline_rounded,
                                      color: accentColor,
                                    ),
                            ),
                            Expanded(
                              child: Text(
                                widget.message,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _dismiss,
                              tooltip: AppLocalizations.of(context)!
                                  .dismissTooltip,
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
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
    );
  }
}
