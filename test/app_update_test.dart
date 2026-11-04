import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:longdow_todo_list/features/app_update/models/update_policy.dart';
import 'package:longdow_todo_list/features/app_update/services/update_controller.dart';
import 'package:longdow_todo_list/features/app_update/widgets/update_host.dart';
import 'package:longdow_todo_list/l10n/app_localizations.dart';
import 'package:longdow_todo_list/app/theme.dart';

String policy({
  String minimum = '1.0.5',
  String latest = '1.0.5',
  String url = '',
}) => jsonEncode({
  'android': {
    'minimum_version': minimum,
    'latest_version': latest,
    'store_url': url,
  },
  'ios': {
    'minimum_version': '1.0.3',
    'latest_version': '1.0.4',
    'store_url': '',
  },
});

void main() {
  for (final entry in {
    '1.0.3': true,
    '1.0.4': true,
    '1.0.5': false,
    '1.0.6': false,
    '1.0.10': false,
  }.entries) {
    test('${entry.key} compared numerically to 1.0.5', () {
      expect(
        UpdatePolicy.parse(policy(), 'android').hasUpdate(entry.key),
        entry.value,
      );
    });
  }
  test('platform latest versions are independent and prerelease sorts before release', () {
    expect(UpdatePolicy.parse(policy(), 'ios').hasUpdate('1.0.4'), false);
    expect(
      UpdatePolicy.parse(policy(), 'android').hasUpdate('1.0.5-beta.1'),
      true,
    );
  });
  test('build metadata does not affect precedence', () {
    expect(
      UpdatePolicy.parse(
        policy(minimum: '1.0.5+99', latest: '1.0.5+1'),
        'android',
      ).hasUpdate('1.0.5+2'),
      false,
    );
  });
  test('invalid policy values are rejected', () {
    for (final value in [
      '',
      '{}',
      '[]',
      policy(latest: 'garbage'),
      policy(latest: '1.0.5-01'),
      policy(latest: '1.0'),
      policy(url: 'https://example.com'),
      policy(url: 'javascript:alert(1)'),
    ]) {
      expect(() => UpdatePolicy.parse(value, 'android'), throwsFormatException);
    }
  });
  test('real Store links are accepted', () {
    expect(
      UpdatePolicy.parse(
        policy(
          url: 'https://play.google.com/store/apps/details?id=com.example',
        ),
        'android',
      ).storeUrl,
      isNotNull,
    );
    final source = jsonEncode({
      'ios': {
        'minimum_version': '1.0.3',
        'latest_version': '1.0.4',
        'store_url': 'https://apps.apple.com/th/app/example/id123456',
      },
    });
    expect(UpdatePolicy.parse(source, 'ios').storeUrl, isNotNull);
  });

  UpdateController controller({
    String? cached,
    Future<String> Function()? fetch,
    Future<void> Function(String)? save,
    Duration timeout = const Duration(seconds: 8),
  }) => UpdateController(
    platform: 'android',
    installedVersion: () async => '1.0.4',
    readCache: () async => cached,
    writeCache: save ?? (_) async {},
    fetch: fetch ?? () async => throw StateError('offline'),
    timeout: timeout,
  );

  test('offline first launch allows access without a policy', () async {
    final c = controller();
    addTearDown(c.dispose);
    await c.check();
    expect(c.updateAvailable, false);
  });
  test('offline startup retains cached update information', () async {
    final c = controller(cached: policy());
    addTearDown(c.dispose);
    await c.check();
    expect(c.updateAvailable, true);
  });
  test('invalid remote policy never replaces validated cache', () async {
    var writes = 0;
    final c = controller(
      cached: policy(),
      fetch: () async => '{}',
      save: (_) async {
        writes++;
      },
    );
    addTearDown(c.dispose);
    await c.check();
    expect(c.updateAvailable, true);
    expect(writes, 0);
  });
  test('invalid cache and failed remote allow access', () async {
    final c = controller(cached: 'invalid');
    addTearDown(c.dispose);
    await c.check();
    expect(c.updateAvailable, false);
  });
  test(
    'validated remote is persisted and can remove an obsolete notice',
    () async {
      String? saved;
      final source = policy(latest: '1.0.4');
      final c = controller(
        cached: policy(),
        fetch: () async => source,
        save: (value) async {
          saved = value;
        },
      );
      addTearDown(c.dispose);
      await c.check();
      expect(saved, source);
      expect(c.updateAvailable, false);
    },
  );
  test('timeout retains cache and concurrent checks share a fetch', () async {
    var calls = 0;
    final c = controller(
      cached: policy(),
      timeout: const Duration(milliseconds: 10),
      fetch: () {
        calls++;
        return Completer<String>().future;
      },
    );
    addTearDown(c.dispose);
    await Future.wait([c.check(), c.check()]);
    expect(calls, 1);
    expect(c.updateAvailable, true);
  });
  for (final dark in [false, true]) {
    testWidgets(
      'update notice supports large Thai text and Store failure (dark=$dark)',
      (tester) async {
        const launcher = MethodChannel('plugins.flutter.io/url_launcher');
        String? launchedUrl;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          launcher,
          (call) async {
            launchedUrl = (call.arguments as Map)['url'] as String;
            return false;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            launcher,
            null,
          ),
        );
        tester.view.physicalSize = dark
            ? const Size(667, 375)
            : const Size(375, 667);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final c = controller(
          fetch: () async => policy(
            url: 'https://play.google.com/store/apps/details?id=com.example',
          ),
        );
        addTearDown(c.dispose);
        await c.check();
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? appDarkTheme : appTheme,
            locale: const Locale('th'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(2)),
              child: child!,
            ),
            home: Scaffold(
              body: SingleChildScrollView(child: UpdateNotice(controller: c)),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('มีอัปเดตใหม่'), findsOneWidget);
        await tester.ensureVisible(
          find.widgetWithText(TextButton, 'อัปเดตตอนนี้'),
        );
        await tester.tap(find.widgetWithText(TextButton, 'อัปเดตตอนนี้'));
        await tester.pumpAndSettle();
        expect(
          launchedUrl,
          'https://play.google.com/store/apps/details?id=com.example',
        );
        expect(
          find.text('เปิด Store ไม่สำเร็จ กรุณาลองอีกครั้ง'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
  test('legacy minimum version is ignored, including invalid values', () {
    expect(
      UpdatePolicy.parse(
        policy(minimum: '9.0.0', latest: '1.0.4'),
        'android',
      ).hasUpdate('1.0.4'),
      false,
    );
    expect(
      UpdatePolicy.parse(
        policy(minimum: 'invalid'),
        'android',
      ).hasUpdate('1.0.4'),
      true,
    );
  });
  testWidgets(
    'startup and links stay usable; Later survives refresh and resume',
    (tester) async {
      var calls = 0;
      var source = policy(latest: '1.0.4');
      final pending = Completer<String>();
      final c = controller(
        fetch: () {
          calls++;
          return calls == 1 ? pending.future : Future.value(source);
        },
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: (settings) => MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const Scaffold(body: Text('Deep link destination')),
          ),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (_, child) => UpdateHost(controller: c, child: child!),
          home: Scaffold(
            body: TextButton(
              onPressed: () {},
              child: const Text('App content'),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('App content'), findsOneWidget);
      await tester.tap(find.text('App content'));
      pending.complete(source);
      await tester.pumpAndSettle();
      expect(find.text('Update available'), findsNothing);
      source = policy();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(find.text('Update available'), findsOneWidget);
      expect(find.text('App content'), findsOneWidget);
      await tester.binding.handlePushRoute('/deep-link');
      await tester.pumpAndSettle();
      expect(find.text('Deep link destination'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('App content'), findsOneWidget);
      await tester.tap(find.text('Later'));
      await tester.pumpAndSettle();
      expect(find.text('Update available'), findsNothing);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(calls, 3);
      expect(find.text('Update available'), findsNothing);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(calls, 3);
      source = policy(latest: '1.0.6');
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('Update available'), findsOneWidget);
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Update Now'))
            .onPressed,
        isNull,
      );
    },
  );
}
