import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:longdow_todo_list/app/app_licenses.dart';
import 'package:longdow_todo_list/features/settings/screens/settings_screen.dart';
import 'package:longdow_todo_list/features/settings/screens/software_licenses_screen.dart';
import 'package:longdow_todo_list/l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('bundled licenses include Kanit and MPL source', (tester) async {
    registerAppLicenses();
    registerAppLicenses();
    final entries = await tester.runAsync(
      () => LicenseRegistry.licenses.toList(),
    );
    final kanit = entries!.where((entry) => entry.packages.contains('Kanit'));
    expect(kanit, hasLength(1));
    String contents(LicenseEntry entry) =>
        entry.paragraphs.map((paragraph) => paragraph.text).join('\n');
    expect(
      contents(kanit.single),
      contains('Copyright 2020 The Kanit Project Authors'),
    );
    expect(
      contents(kanit.single),
      contains('SIL OPEN FONT LICENSE Version 1.1'),
    );
    final dbus = entries.firstWhere(
      (entry) => entry.packages.contains('dbus (source availability)'),
    );
    expect(
      contents(dbus),
      contains('https://pub.dev/api/archives/dbus-0.7.15.tar.gz'),
    );
  });

  for (final locale in ['th', 'en']) {
    testWidgets('Settings opens software licenses in $locale', (tester) async {
      PackageInfo.setMockInitialValues(
        appName: 'Todo',
        packageName: 'todo',
        version: '1.0.0',
        buildNumber: '1',
        buildSignature: '',
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(locale),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: SettingsScreen(
              onLocaleChanged: (_) {},
              onThemeModeChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('settings-licenses')),
        200,
      );
      expect(
        find.text(locale == 'th' ? 'ใบอนุญาตซอฟต์แวร์' : 'Software licenses'),
        findsOneWidget,
      );
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const ValueKey('settings-licenses')));
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(find.byType(SoftwareLicensesScreen), findsOneWidget);
      expect(find.text('Powered by Flutter'), findsNothing);
      await tester.scrollUntilVisible(find.text('Kanit'), 200);
      await tester.tap(find.text('Kanit'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Copyright 2020 The Kanit Project Authors'),
        findsOneWidget,
      );
      expect(find.text('Powered by Flutter'), findsNothing);
    });
  }
}
