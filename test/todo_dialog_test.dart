import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_flutter_app/app/app.dart';
import 'package:my_first_flutter_app/app/theme.dart';
import 'package:my_first_flutter_app/core/api/api_client.dart';
import 'package:my_first_flutter_app/features/todo/models/todo.dart';
import 'package:my_first_flutter_app/features/todo/providers/todo_provider.dart';
import 'package:my_first_flutter_app/features/todo/services/todo_service.dart';
import 'package:my_first_flutter_app/features/todo/widgets/todo_form.dart';
import 'package:my_first_flutter_app/l10n/app_localizations.dart';

class FakeTodoService extends TodoService {
  FakeTodoService() : super(ApiClient(dio: Dio()));

  @override
  Future<List<Todo>> getTodos() async => const [];

  @override
  Future<Todo> createTodo(String title, String details) async =>
      Todo(id: '1', title: title, details: details, completed: false);
}

void main() {
  testWidgets('theme follows the system and can switch beside language', (
    tester,
  ) async {
    final platform = tester.binding.platformDispatcher;
    platform.platformBrightnessTestValue = Brightness.dark;
    addTearDown(platform.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [todoServiceProvider.overrideWithValue(FakeTodoService())],
        child: const TodoApp(),
      ),
    );
    await tester.pumpAndSettle();

    Brightness screenBrightness() =>
        Theme.of(tester.element(find.byType(Scaffold))).brightness;

    expect(screenBrightness(), Brightness.dark);
    platform.platformBrightnessTestValue = Brightness.light;
    await tester.pumpAndSettle();
    expect(screenBrightness(), Brightness.light);

    await tester.enterText(find.byType(TextField), 'draft');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.byTooltip('Switch to dark mode'));
    await tester.pumpAndSettle();
    expect(screenBrightness(), Brightness.dark);
    expect(find.text('draft'), findsOneWidget);

    await tester.tap(find.byTooltip('Change language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ไทย'));
    await tester.pumpAndSettle();
    expect(screenBrightness(), Brightness.dark);
    expect(find.text('draft'), findsOneWidget);
    expect(find.byTooltip('เปลี่ยนเป็นโหมดสว่าง'), findsOneWidget);

    await tester.tap(find.byTooltip('เปลี่ยนเป็นโหมดสว่าง'));
    await tester.pumpAndSettle();
    expect(screenBrightness(), Brightness.light);
    platform.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpAndSettle();
    expect(screenBrightness(), Brightness.light);

    await tester.tap(find.byTooltip('เปลี่ยนเป็นโหมดมืด'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('เพิ่มรายการ'));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(TodoFormDialog))).brightness,
      Brightness.dark,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'เพิ่มรายการ'));
    await tester.pumpAndSettle();
    expect(find.text('กรุณาใส่ชื่อรายการ'), findsOneWidget);
    expect(find.text('กรุณาใส่รายละเอียด'), findsOneWidget);
    await tester.tap(find.text('ยกเลิก'));
    await tester.pumpAndSettle();
    expect(find.text('draft'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final language in ['en', 'th']) {
    testWidgets(
      'edit form validates and submits with the keyboard ($language)',
      (tester) async {
        TodoFormData? result;
        await tester.pumpWidget(
          MaterialApp(
            theme: appTheme,
            locale: Locale(language),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () async {
                    result = await showTodoForm(
                      context,
                      todo: const Todo(
                        id: '1',
                        title: 'Original title',
                        details: ' Original details ',
                        completed: false,
                      ),
                    );
                  },
                  child: const Text('Edit'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Edit'));
        await tester.pumpAndSettle();

        final fields = find.byType(TextFormField);
        final l10n = AppLocalizations.of(tester.element(fields.first))!;
        expect(find.text('Original title'), findsOneWidget);
        expect(find.text(' Original details '), findsOneWidget);

        await tester.enterText(fields.first, '   ');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
        expect(find.text(l10n.enterTitle), findsOneWidget);
        expect(find.byType(TodoFormDialog), findsOneWidget);
        expect(result, isNull);

        await tester.enterText(fields.first, ' Updated title ');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
        expect(find.byType(TodoFormDialog), findsNothing);
        expect(result?.title, 'Updated title');
        expect(result?.details, 'Original details');
      },
    );
  }

  testWidgets('saving the add dialog keeps the widget tree valid', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [todoServiceProvider.overrideWithValue(FakeTodoService())],
        child: TodoApp(),
      ),
    );
    await tester.pump();
    await tester.tap(find.byTooltip('Add todo'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Test todo');
    await tester.enterText(fields.at(1), 'Test details');
    await tester.tap(find.widgetWithText(FilledButton, 'Add todo'));
    await tester.pumpAndSettle();

    expect(find.text('Test todo'), findsOneWidget);
  });
}
