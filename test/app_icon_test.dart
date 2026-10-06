import 'package:flutter/material.dart';

import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:longdow_todo_list/app/theme.dart';
import 'package:longdow_todo_list/features/todo/models/todo.dart';
import 'package:longdow_todo_list/features/todo/widgets/todo_detail.dart';
import 'package:longdow_todo_list/l10n/app_localizations.dart';
import 'package:longdow_todo_list/shared/design/app_icon_assets.dart';
import 'package:longdow_todo_list/shared/design/app_icons.dart';
import 'package:longdow_todo_list/shared/widgets/app_icon.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled logo decodes with a transparent background', () async {
    final bytes = await rootBundle.load(AppIconAssets.logo);
    final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
    addTearDown(codec.dispose);
    final frame = await codec.getNextFrame();
    addTearDown(frame.image.dispose);
    expect(frame.image.width, frame.image.height);
    final pixels = await frame.image.toByteData();
    expect(pixels!.getUint8(3), 0);
  });

  for (final language in ['en', 'th']) {
    testWidgets(
      'brand icon preserves the localized detail dialog ($language)',
      (tester) async {
        // Keep the header wide enough for full badges in both languages.
        await tester.binding.setSurfaceSize(const Size(1024, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final theme = language == 'en' ? appTheme : appDarkTheme;
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            locale: Locale(language),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showTodoDetail(
                    context,
                    todo: const Todo(
                      id: '1',
                      title: 'Task title',
                      details: 'Task details',
                      completed: false,
                      priority: 'high',
                    ),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        final iconContext = tester.element(find.byType(AppIcon));
        final l10n = AppLocalizations.of(iconContext)!;
        expect(find.text('Task title'), findsOneWidget);
        expect(find.text('Task details'), findsOneWidget);
        expect(find.text(l10n.priorityHigh), findsOneWidget);
        expect(find.byIcon(AppIcons.priority), findsOneWidget);
        expect(find.text(l10n.incomplete), findsOneWidget);
        final image = tester.widget<Image>(find.byType(Image));
        expect((image.image as AssetImage).assetName, AppIconAssets.logo);
        expect(image.color, isNull);
        expect(image.width, 28);
        expect(tester.takeException(), isNull);

        await tester.tap(
          find.text(MaterialLocalizations.of(iconContext).closeButtonLabel),
        );
        await tester.pumpAndSettle();
        expect(find.byType(TodoDetailSheet), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
