import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_flutter_app/app/theme.dart';
import 'package:my_first_flutter_app/shared/widgets/liquid_glass_bottom_navigation.dart';

const items = [
  LiquidGlassNavigationItem(icon: Icons.home_outlined, label: 'Home'),
  LiquidGlassNavigationItem(icon: Icons.checklist, label: 'Tasks'),
  LiquidGlassNavigationItem(icon: Icons.bar_chart, label: 'Stats'),
  LiquidGlassNavigationItem(icon: Icons.settings_outlined, label: 'Settings'),
];

void main() {
  testWidgets('selection expands and contracts without changing icon size', (
    tester,
  ) async {
    var selected = 1;
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme,
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            extendBody: true,
            bottomNavigationBar: LiquidGlassBottomNavigation(
              items: items,
              selectedIndex: selected,
              onSelected: (value) => setState(() => selected = value),
            ),
          ),
        ),
      ),
    );
    final buttons = find.descendant(
      of: find.byType(LiquidGlassBottomNavigation),
      matching: find.byType(InkWell),
    );
    final initialTaskWidth = tester.getSize(buttons.at(1)).width;
    final initialSettingsWidth = tester.getSize(buttons.at(3)).width;
    expect(initialTaskWidth, greaterThan(initialSettingsWidth));
    expect(find.text('Tasks'), findsOneWidget);
    expect(find.text('Settings'), findsNothing);

    final press = await tester.startGesture(tester.getCenter(buttons.at(3)));
    await tester.pump(const Duration(milliseconds: 120));
    expect(
      tester.widget<AnimatedScale>(find.byType(AnimatedScale).at(3)).scale,
      0.96,
    );
    await press.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 125));
    expect(tester.getSize(buttons.at(1)).width, lessThan(initialTaskWidth));
    expect(
      tester.getSize(buttons.at(1)).width,
      greaterThan(initialSettingsWidth),
    );
    expect(
      tester.getSize(buttons.at(3)).width,
      greaterThan(initialSettingsWidth),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(selected, 3);
    expect(tester.getSize(buttons.at(1)).width, initialSettingsWidth);
    expect(find.text('Tasks'), findsNothing);
    expect(find.text('Settings'), findsOneWidget);
    for (final icon in tester.widgetList<Icon>(find.byType(Icon))) {
      expect(icon.size, 24);
    }
    expect(tester.takeException(), isNull);
  });

  for (final dark in [false, true]) {
    testWidgets(
      'fits narrow screens, large Thai labels and safe area ($dark)',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var selected = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? appDarkTheme : appTheme,
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(320, 640),
                padding: EdgeInsets.only(bottom: 24),
                textScaler: TextScaler.linear(2),
              ),
              child: StatefulBuilder(
                builder: (context, setState) => Scaffold(
                  extendBody: true,
                  bottomNavigationBar: LiquidGlassBottomNavigation(
                    items: [
                      for (var index = 0; index < 4; index++)
                        LiquidGlassNavigationItem(
                          icon: items[index].icon,
                          label: ['หน้าแรก', 'งาน', 'สถิติ', 'ตั้งค่า'][index],
                        ),
                    ],
                    selectedIndex: selected,
                    onSelected: (index) => setState(() => selected = index),
                  ),
                ),
              ),
            ),
          ),
        );
        final buttons = find.descendant(
          of: find.byType(LiquidGlassBottomNavigation),
          matching: find.byType(InkWell),
        );
        final surface = find
            .descendant(
              of: find.byType(BackdropFilter),
              matching: find.byType(Container),
            )
            .first;
        expect(tester.getBottomLeft(surface).dy, closeTo(640 - 24 - 14, 0.1));
        expect(tester.getSemantics(buttons.first).label, 'หน้าแรก');
        for (var index = 1; index < 4; index++) {
          await tester.tap(buttons.at(index));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 125));
          expect(tester.takeException(), isNull);
          await tester.pumpAndSettle();
          expect(selected, index);
          expect(tester.takeException(), isNull);
        }
      },
    );
  }
}
