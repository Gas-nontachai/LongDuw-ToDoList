import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'update_controller.dart';

class FirebaseUpdateSource {
  FirebaseRemoteConfig? _config;

  Future<String> fetch() async {
    if (_config == null) {
      if (Firebase.apps.isEmpty) {
        const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
        const appId = String.fromEnvironment('FIREBASE_APP_ID');
        const senderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
        const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
        if ([
          apiKey,
          appId,
          senderId,
          projectId,
        ].any((value) => value.isEmpty)) {
          throw StateError('Firebase build configuration is missing');
        }
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: apiKey,
            appId: appId,
            messagingSenderId: senderId,
            projectId: projectId,
          ),
        );
      }
      final config = FirebaseRemoteConfig.instance;
      await config.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 5),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );
      _config = config;
    }
    await _config!.fetchAndActivate();
    return _config!.getString('app_update_policy');
  }
}

UpdateController? createUpdateController() {
  if (kIsWeb ||
      ![
        TargetPlatform.android,
        TargetPlatform.iOS,
      ].contains(defaultTargetPlatform)) {
    return null;
  }
  final platform = defaultTargetPlatform == TargetPlatform.android
      ? 'android'
      : 'ios';
  final preferences = SharedPreferencesAsync();
  final source = FirebaseUpdateSource();
  final cacheKey = 'validated_app_update_policy_$platform';
  return UpdateController(
    platform: platform,
    installedVersion: () async => (await PackageInfo.fromPlatform()).version,
    fetch: source.fetch,
    readCache: () => preferences.getString(cacheKey),
    writeCache: (value) => preferences.setString(cacheKey, value),
  );
}
