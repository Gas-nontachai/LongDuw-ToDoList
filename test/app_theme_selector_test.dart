import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:longdow_todo_list/app/theme.dart';
import 'package:longdow_todo_list/l10n/app_localizations.dart';
import 'package:longdow_todo_list/shared/widgets/app_theme_selector.dart';

void main() {
  testWidgets('equal options keep mode icons visible and update selection', (
    tester,
  ) async {
    var selected = ThemeMode.system;
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme,
        locale: const Locale('th'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 480,
              child: StatefulBuilder(
                builder: (context, setState) => AppThemeSelector(
                  value: selected,
                  onChanged: (mode) => setState(() => selected = mode),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final chips = find.byType(ChoiceChip);
    expect(chips, findsNWidgets(3));
    final sizes = [for (var i = 0; i < 3; i++) tester.getSize(chips.at(i))];
    expect(sizes[1], sizes[0]);
    expect(sizes[2], sizes[0]);
    for (final chip in tester.widgetList<ChoiceChip>(chips)) {
      expect(chip.showCheckmark, isFalse);
      expect(chip.avatar, isNull);
    }
    expect(find.byIcon(Icons.devices_outlined), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'มืด'));
    await tester.pumpAndSettle();
    expect(selected, ThemeMode.dark);
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'มืด'))
          .selected,
      isTrue,
    );
    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow layout with large Thai text wraps without overlap', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: appDarkTheme,
        locale: const Locale('th'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: const Center(
              child: SizedBox(
                width: 220,
                child: AppThemeSelector(
                  value: ThemeMode.system,
                  onChanged: null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final chips = find.byType(ChoiceChip);
    expect(
      tester.getTopLeft(chips.at(1)).dy,
      greaterThan(tester.getTopLeft(chips.at(0)).dy),
    );
    expect(find.text('ตามระบบ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
