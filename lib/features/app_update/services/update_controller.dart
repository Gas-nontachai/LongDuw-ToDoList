import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/update_policy.dart';

/// The cache contains only policies validated for this platform, never defaults.
class UpdateController extends ChangeNotifier {
  UpdateController({
    required this.platform,
    required this.installedVersion,
    required this.fetch,
    required this.readCache,
    required this.writeCache,
    this.timeout = const Duration(seconds: 8),
  });

  final String platform;
  final Future<String> Function() installedVersion;
  final Future<String> Function() fetch;
  final Future<String?> Function() readCache;
  final Future<void> Function(String) writeCache;
  final Duration timeout;
  UpdatePolicy? policy;
  String? version;
  bool ready = false;
  bool _disposed = false;
  Future<void>? _pending;

  bool get updateRequired {
    if (version == null || policy == null) return false;
    try {
      return policy!.requiresUpdate(version!);
    } on FormatException {
      return false;
    }
  }

  Future<void> check() =>
      _pending ??= _check().whenComplete(() => _pending = null);

  Future<void> _check() async {
    try {
      version ??= await installedVersion().timeout(timeout);
      if (!ready) {
        try {
          final cached = await readCache().timeout(timeout);
          if (cached != null) policy = UpdatePolicy.parse(cached, platform);
        } catch (error) {
          debugPrint('Update policy cache unavailable: $error');
        }
      }
      // Cached enforcement is visible while a fresh policy is being fetched.
      ready = policy != null;
      _notify();
      try {
        final source = await fetch().timeout(timeout);
        final validated = UpdatePolicy.parse(source, platform);
        policy = validated;
        _notify();
        await writeCache(source).timeout(timeout);
      } catch (error) {
        // Keep the last validated policy; with no policy, allow offline access.
        debugPrint('Update policy refresh unavailable: $error');
      }
    } catch (error) {
      debugPrint('Installed app version unavailable: $error');
    } finally {
      ready = true;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
