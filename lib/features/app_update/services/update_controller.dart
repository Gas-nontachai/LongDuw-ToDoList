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
  bool _cacheLoaded = false;
  bool _disposed = false;
  Future<void>? _pending;

  String? _dismissedVersion;

  void dismiss() {
    _dismissedVersion = policy?.latest.toString();
    _notify();
  }

  bool get updateAvailable {
    if (version == null ||
        policy == null ||
        _dismissedVersion == policy!.latest.toString()) {
      return false;
    }
    try {
      return policy!.hasUpdate(version!);
    } on FormatException {
      return false;
    }
  }

  Future<void> check() =>
      _pending ??= _check().whenComplete(() => _pending = null);

  Future<void> _check() async {
    try {
      version ??= await installedVersion().timeout(timeout);
      if (!_cacheLoaded) {
        try {
          final cached = await readCache().timeout(timeout);
          if (cached != null) policy = UpdatePolicy.parse(cached, platform);
        } catch (error) {
          debugPrint('Update policy cache unavailable: $error');
        }
      }
      // Show cached update information while refreshing in the background.
      _cacheLoaded = true;
      _notify();
      try {
        final source = await fetch().timeout(timeout);
        final validated = UpdatePolicy.parse(source, platform);
        policy = validated;
        _notify();
        await writeCache(source).timeout(timeout);
      } catch (error) {
        // Retain the last validated update information when offline.
        debugPrint('Update policy refresh unavailable: $error');
      }
    } catch (error) {
      debugPrint('Installed app version unavailable: $error');
    } finally {
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
