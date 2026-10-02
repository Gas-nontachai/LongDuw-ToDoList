import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_flutter_app/app/app_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('unset preferences follow the system', () async {
    final preferences = await AppPreferences.load();
    expect(preferences.themeMode, ThemeMode.system);
    expect(preferences.locale, isNull);
  });

  test('theme and language survive creating a new preferences cache', () async {
    final preferences = await AppPreferences.load();
    for (final mode in ThemeMode.values) {
      for (final language in ['en', 'th']) {
        await preferences.saveThemeMode(mode);
        await preferences.saveLocale(Locale(language));

        final restored = await AppPreferences.load();
        expect(restored.themeMode, mode);
        expect(restored.locale, Locale(language));
      }
    }
  });

  test('invalid or unsupported saved values fall back to the system', () async {
    for (final values in [
      {
        AppPreferences.themeModeKey: 'unknown',
        AppPreferences.languageCodeKey: 'fr',
      },
      {AppPreferences.themeModeKey: 42, AppPreferences.languageCodeKey: true},
    ]) {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.withData(values);
      final preferences = await AppPreferences.load();
      expect(preferences.themeMode, ThemeMode.system);
      expect(preferences.locale, isNull);
    }
  });
}
