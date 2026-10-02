import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_flutter_app/app/theme.dart';
import 'package:my_first_flutter_app/features/todo/models/todo.dart';
import 'package:my_first_flutter_app/features/todo/widgets/todo_detail.dart';
import 'package:my_first_flutter_app/l10n/app_localizations.dart';
import 'package:my_first_flutter_app/shared/design/app_icon_assets.dart';
import 'package:my_first_flutter_app/shared/widgets/app_icon.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled task SVG can be loaded and decoded', () async {
    final picture = await vg.loadPicture(
      const SvgAssetLoader(AppIconAssets.task),
      null,
    );
    addTearDown(picture.picture.dispose);
    expect(picture.size, const Size(24, 24));
  });

  for (final language in ['en', 'th']) {
    testWidgets('task icon preserves the localized detail dialog ($language)', (
      tester,
    ) async {
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
      expect(find.text('${l10n.status}: ${l10n.incomplete}'), findsOneWidget);
      final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(
        svg.colorFilter,
        ColorFilter.mode(IconTheme.of(iconContext).color!, BlendMode.srcIn),
      );
      expect(tester.takeException(), isNull);

      await tester.tap(
        find.text(MaterialLocalizations.of(iconContext).closeButtonLabel),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TodoDetailDialog), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
