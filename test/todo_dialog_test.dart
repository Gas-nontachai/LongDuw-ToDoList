import 'package:my_first_flutter_app/app/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_flutter_app/app/app.dart';
import 'package:my_first_flutter_app/app/app_preferences.dart';
import 'package:my_first_flutter_app/app/theme.dart';
import 'package:my_first_flutter_app/core/database/app_database.dart';
import 'package:my_first_flutter_app/features/todo/models/todo.dart';
import 'package:my_first_flutter_app/features/todo/providers/todo_provider.dart';
import 'package:my_first_flutter_app/features/todo/services/todo_service.dart';
import 'package:my_first_flutter_app/features/todo/widgets/todo_form.dart';
import 'package:my_first_flutter_app/l10n/app_localizations.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class FakeTodoService extends TodoService {
  FakeTodoService() : super(AppDatabase());

  Todo? createdTodo;

  @override
  Future<List<Todo>> getTodos() async => const [];

  @override
  Future<Todo> createTodo(
    String title,
    String details, {
    String priority = 'medium',
    DateTime? dueDate,
  }) async => createdTodo = Todo(
    id: '1',
    title: title,
    details: details,
    completed: false,
    priority: priority,
    dueDate: dueDate,
  );
}

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('theme follows the system and can switch beside language', (
    tester,
  ) async {
    final platform = tester.binding.platformDispatcher;
    platform.platformBrightnessTestValue = Brightness.dark;
    addTearDown(platform.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [todoServiceProvider.overrideWithValue(FakeTodoService())],
        child: TodoApp(preferences: await AppPreferences.load()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('home-view-all')));
    await tester.pumpAndSettle();

    Brightness screenBrightness() =>
        Theme.of(tester.element(find.byType(AppShell))).brightness;

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

    expect(find.text('EN'), findsOneWidget);
    await tester.tap(find.byTooltip('Change language'));
    await tester.pumpAndSettle();
    expect(find.text('TH'), findsOneWidget);
    expect(screenBrightness(), Brightness.dark);
    expect(find.text('draft'), findsOneWidget);
    expect(find.byTooltip('เปลี่ยนเป็นโหมดสว่าง'), findsOneWidget);

    await tester.tap(find.byTooltip('เปลี่ยนภาษา'));
    await tester.pumpAndSettle();
    expect(find.text('EN'), findsOneWidget);
    expect(find.byTooltip('Switch to light mode'), findsOneWidget);
    expect((await AppPreferences.load()).locale, const Locale('en'));

    await tester.tap(find.byTooltip('Change language'));
    await tester.pumpAndSettle();
    expect(find.text('TH'), findsOneWidget);

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
      Theme.of(tester.element(find.byType(TodoFormSheet))).brightness,
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

    // Recreate the app and its preferences cache to simulate a fresh launch.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [todoServiceProvider.overrideWithValue(FakeTodoService())],
        child: TodoApp(preferences: await AppPreferences.load()),
      ),
    );
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
    expect(app.locale, const Locale('th'));
    await tester.pumpAndSettle();
    expect(screenBrightness(), Brightness.dark);
    expect(find.byTooltip('เปลี่ยนเป็นโหมดสว่าง'), findsOneWidget);
    expect(find.text('TH'), findsOneWidget);
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
                      todo: Todo(
                        id: '1',
                        title: 'Original title',
                        details: ' Original details ',
                        completed: false,
                        priority: 'low',
                        dueDate: DateTime.utc(2026, 10, 5, 10, 30),
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
        final priority = tester.widget<DropdownButtonFormField<String>>(
          find.byType(DropdownButtonFormField<String>),
        );
        expect(priority.initialValue, 'low');
        final dueDateField = tester.widget<TextFormField>(fields.last);
        expect(
          dueDateField.controller!.text,
          MaterialLocalizations.of(tester.element(fields.last))
              .formatMediumDate(DateTime.utc(2026, 10, 5)),
        );

        await tester.enterText(fields.first, '   ');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
        expect(find.text(l10n.enterTitle), findsOneWidget);
        expect(find.byType(TodoFormSheet), findsOneWidget);
        expect(result, isNull);

        await tester.tap(find.byType(DropdownButtonFormField<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.priorityHigh).last);
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip(l10n.clearDueDate));
        await tester.pumpAndSettle();
        await tester.enterText(fields.first, ' Updated title ');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
        expect(find.byType(TodoFormSheet), findsNothing);
        expect(result?.title, 'Updated title');
        expect(result?.details, 'Original details');
        expect(result?.priority, 'high');
        expect(result?.dueDate, isNull);
      },
    );
  }

  for (final width in [320.0, 800.0]) {
    testWidgets(
      'form fills sheet width and preserves drafts when expanded ($width)',
      (tester) async {
        await tester.binding.setSurfaceSize(Size(width, 700));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        TodoFormData? result;
        await tester.pumpWidget(
          MaterialApp(
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
                        title: 'Short title',
                        details: 'Details',
                        completed: false,
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        final dialog = find.byKey(const ValueKey('expandable-sheet'));
        final initialRect = tester.getRect(dialog);
        expect(initialRect.width, closeTo(width, 1));
        final titleField = find.byType(TextFormField).first;
        final initialFieldWidth = tester.getSize(titleField).width;
        final longTitle = List.filled(100, 'Long title ชื่อยาว').join(' ');
        await tester.enterText(titleField, longTitle);
        await tester.pumpAndSettle();
        expect(tester.getRect(dialog), initialRect);
        expect(tester.getSize(titleField).width, initialFieldWidth);
        await tester.tap(find.byTooltip('Expand to full screen'));
        await tester.pumpAndSettle();
        expect(tester.getSize(dialog).height, closeTo(700, 1));
        expect(find.text(longTitle), findsOneWidget);
        await tester.tap(find.byTooltip('Collapse sheet'));
        await tester.pumpAndSettle();
        expect(tester.getRect(dialog), initialRect);
        final editable = tester.widget<EditableText>(
          find.descendant(of: titleField, matching: find.byType(EditableText)),
        );
        expect(editable.maxLines, 1);
        expect(editable.controller.text, longTitle);
        expect(tester.takeException(), isNull);
        await tester.tap(find.widgetWithText(FilledButton, 'Save'));
        await tester.pumpAndSettle();
        expect(result?.title, longTitle);
      },
    );
  }

  testWidgets('form keeps save visible above keyboard and preserves draft', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    addTearDown(tester.view.resetViewInsets);
    TodoFormData? result;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async => result = await showTodoForm(context),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.first, 'Draft title');
    await tester.enterText(fields.at(1), 'Draft details');
    tester.view.viewInsets = FakeViewPadding(
      bottom: 300 * tester.view.devicePixelRatio,
    );
    await tester.pumpAndSettle();
    final save = find.widgetWithText(FilledButton, 'Add todo');
    expect(tester.getRect(save).bottom, lessThanOrEqualTo(400));
    await tester.tap(find.byTooltip('Expand to full screen'));
    await tester.pumpAndSettle();
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    expect(find.text('Draft title'), findsOneWidget);
    expect(find.text('Draft details'), findsOneWidget);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(result?.title, 'Draft title');
    expect(result?.details, 'Draft details');
    expect(tester.takeException(), isNull);
  });

  testWidgets('saving the add dialog keeps the widget tree valid', (
    tester,
  ) async {
    final service = FakeTodoService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [todoServiceProvider.overrideWithValue(service)],
        child: TodoApp(preferences: await AppPreferences.load()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('home-view-all')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add todo'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Test todo');
    await tester.enterText(fields.at(1), 'Test details');
    expect(
      tester
          .widget<DropdownButtonFormField<String>>(
            find.byType(DropdownButtonFormField<String>),
          )
          .initialValue,
      'medium',
    );
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('High').last);
    await tester.pumpAndSettle();
    await tester.tap(fields.last);
    await tester.pumpAndSettle();
    final selectedDate = tester
        .widget<DatePickerDialog>(find.byType(DatePickerDialog))
        .initialDate!;
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Add todo'));
    await tester.pumpAndSettle();

    expect(find.text('Test todo'), findsOneWidget);
    expect(service.createdTodo?.priority, 'high');
    expect(service.createdTodo?.dueDate, selectedDate);
    expect(tester.takeException(), isNull);
  });
}
