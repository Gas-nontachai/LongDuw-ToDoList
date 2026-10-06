import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_flutter_app/app/app_shell.dart';
import 'package:my_first_flutter_app/app/theme.dart';
import 'package:my_first_flutter_app/features/stats/screens/stats_screen.dart';
import 'package:my_first_flutter_app/features/todo/models/todo.dart';
import 'package:my_first_flutter_app/features/todo/providers/todo_provider.dart';
import 'package:my_first_flutter_app/l10n/app_localizations.dart';
import 'package:my_first_flutter_app/shared/widgets/app_error.dart';
import 'package:my_first_flutter_app/shared/widgets/app_loading.dart';

class _Todos extends TodoNotifier {
  _Todos(this.items);
  final List<Todo> items;
  bool fail = false;
  Completer<List<Todo>>? pending;
  int retries = 0;

  @override
  Future<List<Todo>> build() async {
    if (pending != null) return pending!.future;
    if (fail) throw StateError('Load failed');
    return items;
  }

  void replace(List<Todo> items) => state = AsyncData(items);

  @override
  Future<void> refreshTodos() async {
    retries++;
    replace(items);
  }
}

List<Todo> _tasks() {
  final now = DateTime.now();
  return [
    for (var i = 0; i < 12; i++)
      Todo(
        id: '$i',
        title: 'Task $i',
        details: '',
        completed: i < 7,
        priority: i < 3
            ? 'high'
            : i < 8
            ? 'medium'
            : 'low',
        dueDate: switch (i) {
          7 => DateTime(now.year, now.month, now.day - 1),
          8 => now,
          9 => DateTime(now.year, now.month, now.day + 7),
          10 => DateTime(now.year, now.month, now.day + 8),
          _ => null,
        },
      ),
  ];
}

final _captureKey = GlobalKey();

Future<void> _pump(
  WidgetTester tester,
  _Todos todos, {
  String language = 'en',
  bool dark = false,
  double scale = 1,
  bool shell = false,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [todoProvider.overrideWith(() => todos)],
      child: MaterialApp(
        locale: Locale(language),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: dark ? appDarkTheme : appTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: RepaintBoundary(key: _captureKey, child: child!),
        ),
        home: shell
            ? AppShell(onLocaleChanged: (_) {}, onThemeModeChanged: (_) {})
            : const Scaffold(body: StatsScreen()),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _dispose(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
}

void main() {
  setUpAll(() async {
    final font = FontLoader('Kanit');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      font.addFont(rootBundle.load('assets/fonts/Kanit-$weight.ttf'));
    }
    await font.load();
    final icons = FontLoader('packages/cupertino_icons/CupertinoIcons')
      ..addFont(
        rootBundle.load('packages/cupertino_icons/assets/CupertinoIcons.ttf'),
      );
    await icons.load();
  });
  testWidgets('reference progress, conditional rows and live data changes', (
    tester,
  ) async {
    final todos = _Todos(_tasks());
    await _pump(tester, todos);
    expect(find.text('58%'), findsOneWidget);
    expect(find.text('7 of 12 completed'), findsOneWidget);
    double? progress(String label) => tester
        .widget<LinearProgressIndicator>(
          find.byWidgetPredicate(
            (widget) =>
                widget is LinearProgressIndicator &&
                widget.semanticsLabel == label,
          ),
        )
        .value;
    expect(progress('High'), 3 / 12);
    expect(progress('Medium'), 5 / 12);
    expect(progress('Low'), 4 / 12);
    await tester.scrollUntilVisible(find.text('Later (over 7 days)'), 200);
    expect(find.text('Remaining tasks only'), findsOneWidget);
    expect(progress('Due today'), 1 / 5);
    expect(progress('Later (over 7 days)'), 1 / 5);
    expect(find.text('Not specified'), findsNothing);
    final updated = [
      ...todos.items,
      const Todo(id: 'new', title: '', details: '', completed: false),
    ];
    todos.replace(updated);
    await tester.pump();
    await tester.scrollUntilVisible(find.text('Not specified'), -200);
    expect(find.text('Not specified'), findsOneWidget);
    todos.replace([for (final task in updated) task.copyWith(completed: true)]);
    await tester.pump();
    await tester.scrollUntilVisible(find.text('100%'), -200);
    expect(find.text('13 of 13 completed'), findsOneWidget);
    todos.replace([]);
    await tester.pump();
    expect(find.text('0%'), findsOneWidget);
    expect(find.text('0 of 0 completed'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _dispose(tester);
  });

  testWidgets('loading, error and retry do not show empty statistics', (
    tester,
  ) async {
    final pending = _Todos([])..pending = Completer<List<Todo>>();
    await _pump(tester, pending);
    expect(find.byType(AppLoading), findsOneWidget);
    expect(find.text('0%'), findsNothing);
    pending.pending!.completeError(StateError('Load failed'));
    await tester.pump();
    await tester.pump();
    expect(find.byType(AppError), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(pending.retries, 1);
    expect(find.text('0%'), findsOneWidget);
    await _dispose(tester);
  });

  for (final language in ['en', 'th']) {
    for (final dark in [false, true]) {
      testWidgets('$language dark=$dark fits narrow width and large text', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await _pump(
          tester,
          _Todos(_tasks()),
          language: language,
          dark: dark,
          scale: 2,
        );
        expect(tester.takeException(), isNull);
        await tester.drag(find.byType(ListView), const Offset(0, -2200));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await _dispose(tester);
      });
    }
  }

  for (final language in ['en', 'th']) {
    testWidgets('Stats shell supports large text ($language)', (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _pump(
        tester,
        _Todos(_tasks()),
        shell: true,
        language: language,
        scale: 2,
      );
      await tester.tap(find.byTooltip(language == 'en' ? 'Stats' : 'สถิติ'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(tester.takeException(), isNull);
      await _dispose(tester);
    });
  }

  for (final language in ['en', 'th']) {
    for (final dark in [false, true]) {
      testWidgets('shell shows Stats subtitle ($language, dark=$dark)', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(430, 932);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await _pump(
          tester,
          _Todos(_tasks()),
          shell: true,
          language: language,
          dark: dark,
        );
        await tester.tap(find.byTooltip(language == 'en' ? 'Stats' : 'สถิติ'));
        await tester.pumpAndSettle();
        final l10n = AppLocalizations.of(
          tester.element(find.byType(StatsScreen)),
        )!;
        expect(find.text(l10n.statsSubtitle), findsOneWidget);
        expect(find.text('58%'), findsOneWidget);
        expect(tester.takeException(), isNull);
        if (const bool.fromEnvironment('STATS_SCREENSHOT')) {
          await tester.runAsync(() async {
            final boundary =
                _captureKey.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final image = await boundary.toImage(pixelRatio: 2);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await File(
              '/private/tmp/stats-preview-$language-${dark ? 'dark' : 'light'}.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        await _dispose(tester);
      });
    }
  }
}
