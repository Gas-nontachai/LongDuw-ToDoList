import 'support/test_preferences.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:longdow_todo_list/app/app_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TestPreferences preferencesFixture;
  tearDown(() => preferencesFixture.close());
  setUp(() {
    preferencesFixture = TestPreferences();
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('new installations default to system mode and Thai', () async {
    final preferences = await preferencesFixture.load();
    expect(preferences.themeMode, ThemeMode.system);
    expect(preferences.locale, const Locale('th'));
  });

  test('theme and language survive creating a new preferences cache', () async {
    final preferences = await preferencesFixture.load();
    for (final mode in ThemeMode.values) {
      for (final language in ['en', 'th']) {
        await preferences.saveThemeMode(mode);
        await preferences.saveLocale(Locale(language));

        final restored = await preferencesFixture.load();
        expect(restored.themeMode, mode);
        expect(restored.locale, Locale(language));
      }
    }
  });

  test(
    'invalid or unsupported saved values fall back to light and Thai',
    () async {
      for (final values in [
        {
          AppPreferences.themeModeKey: 'unknown',
          AppPreferences.languageCodeKey: 'fr',
        },
        {AppPreferences.themeModeKey: 42, AppPreferences.languageCodeKey: true},
      ]) {
        await preferencesFixture.close();
        preferencesFixture = TestPreferences();
        SharedPreferencesAsyncPlatform.instance =
            InMemorySharedPreferencesAsync.withData(values);
        final preferences = await preferencesFixture.load();
        expect(preferences.themeMode, ThemeMode.light);
        expect(preferences.locale, const Locale('th'));
      }
    },
  );
}
