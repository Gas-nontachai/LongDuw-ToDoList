import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_flutter_app/app/theme.dart';
import 'package:my_first_flutter_app/features/todo/models/todo.dart';
import 'package:my_first_flutter_app/features/todo/providers/todo_provider.dart';
import 'package:my_first_flutter_app/features/todo/screens/todo_screen.dart';
import 'package:my_first_flutter_app/l10n/app_localizations.dart';
import 'package:my_first_flutter_app/shared/widgets/liquid_glass_bottom_navigation.dart';

const items = [
  LiquidGlassNavigationItem(icon: Icons.home_outlined, label: 'Home'),
  LiquidGlassNavigationItem(icon: Icons.checklist, label: 'Tasks'),
  LiquidGlassNavigationItem(icon: Icons.bar_chart, label: 'Stats'),
  LiquidGlassNavigationItem(icon: Icons.settings_outlined, label: 'Settings'),
];

class _TestTodos extends TodoNotifier {
  @override
  Future<List<Todo>> build() async => [
    for (var index = 0; index < 30; index++)
      Todo(id: '$index', title: 'Task $index', details: '', completed: false),
  ];
}

void main() {
  testWidgets(
    'outside taps collapse without consuming taps; same tab expands',
    (tester) async {
      var compact = false;
      var selected = 1;
      var outsideTaps = 0;
      var bodyTaps = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          home: StatefulBuilder(
            builder: (context, setState) => Scaffold(
              extendBody: true,
              body: Center(
                child: TextButton(
                  onPressed: () => bodyTaps++,
                  child: const Text('Outside button'),
                ),
              ),
              bottomNavigationBar: LiquidGlassBottomNavigation(
                items: items,
                selectedIndex: selected,
                isCompact: compact,
                onTapOutside: () {
                  outsideTaps++;
                  setState(() => compact = true);
                },
                onSelected: (index) => setState(() {
                  selected = index;
                  compact = false;
                }),
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
            matching: find.byType(AnimatedContainer),
          )
          .first;
      final expandedSize = tester.getSize(surface);
      final bottom = tester.getBottomLeft(surface).dy;
      await tester.tap(find.text('Outside button'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 125));
      expect(tester.getSize(surface).width, lessThan(expandedSize.width));
      expect(tester.getSize(surface).width, greaterThan(218));
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(bodyTaps, 1);
      expect(outsideTaps, 1);
      expect(selected, 1);
      expect(find.text('Tasks'), findsNothing);
      expect(tester.getSize(surface).width, 218);
      expect(tester.getSize(surface).height, lessThan(expandedSize.height));
      expect(tester.getBottomLeft(surface).dy, bottom);
      for (var index = 0; index < 4; index++) {
        final size = tester.getSize(buttons.at(index));
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
      }
      expect(
        tester
            .getSemantics(buttons.at(1))
            .flagsCollection
            .isSelected
            .toBoolOrNull(),
        isTrue,
      );
      final decoration =
          tester
                  .widget<AnimatedContainer>(
                    find.byType(AnimatedContainer).at(2),
                  )
                  .decoration!
              as BoxDecoration;
      expect(
        decoration.color,
        appTheme.colorScheme.primary.withValues(alpha: 0.06),
      );
      // Padding beside the compact glass is outside its TapRegion.
      await tester.tapAt(Offset(20, bottom - 25));
      await tester.pumpAndSettle();
      expect(outsideTaps, 2);
      await tester.tap(buttons.at(1));
      await tester.pumpAndSettle();
      expect(compact, isFalse);
      expect(selected, 1);
      expect(find.text('Tasks'), findsOneWidget);
      expect(tester.getSize(surface), expandedSize);
      expect(outsideTaps, 2);
      await tester.tap(find.text('Outside button'));
      await tester.pumpAndSettle();
      await tester.tap(buttons.at(3));
      await tester.pumpAndSettle();
      expect(selected, 3);
      expect(compact, isFalse);
      expect(find.text('Settings'), findsOneWidget);
      final region = tester.widget<TapRegion>(
        find
            .descendant(
              of: find.byType(LiquidGlassBottomNavigation),
              matching: find.byType(TapRegion),
            )
            .first,
      );
      region.onTapOutside!(const PointerDownEvent());
      await tester.pumpAndSettle();
      expect(compact, isTrue);
      expect(find.text('Settings'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'screen collapses on vertical scroll, retains state and ignores horizontal swipes',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var themeChanges = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [todoProvider.overrideWith(_TestTodos.new)],
          child: MaterialApp(
            theme: appTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: TodoScreen(
              onLocaleChanged: (_) {},
              onThemeModeChanged: (_) => themeChanges++,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      LiquidGlassBottomNavigation nav() =>
          tester.widget(find.byType(LiquidGlassBottomNavigation));
      final buttons = find.descendant(
        of: find.byType(LiquidGlassBottomNavigation),
        matching: find.byType(InkWell),
      );
      expect(nav().isCompact, isFalse);
      await tester.drag(find.byType(TabBarView), const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(nav().isCompact, isTrue);
      expect(nav().selectedIndex, 1);
      await tester.pump(const Duration(seconds: 4));
      expect(nav().isCompact, isTrue);
      await tester.tap(buttons.at(1));
      await tester.pumpAndSettle();
      expect(nav().isCompact, isFalse);
      await tester.drag(find.byType(TabBarView), const Offset(-300, 0));
      await tester.pumpAndSettle();
      expect(nav().isCompact, isFalse);
      expect(
        tester.widget<TabBarView>(find.byType(TabBarView)).controller!.index,
        1,
      );
      await tester.tap(find.byTooltip('Switch to dark mode'));
      await tester.pumpAndSettle();
      expect(themeChanges, 1);
      expect(nav().isCompact, isTrue);
      await tester.tap(buttons.at(3));
      await tester.pumpAndSettle();
      expect(nav().selectedIndex, 3);
      expect(nav().isCompact, isFalse);
      await tester.tap(buttons.at(1));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TabBarView>(find.byType(TabBarView)).controller!.index,
        1,
      );
      expect(tester.takeException(), isNull);
      // Dispose with an outside pointer still down: tracking must be cleaned up.
      final gesture = await tester.startGesture(const Offset(10, 10));
      await tester.pumpWidget(const SizedBox.shrink());
      await gesture.up();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('compact mode respects disabled animations', (tester) async {
    var compact = false;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: StatefulBuilder(
            builder: (context, setState) => Scaffold(
              body: const Center(child: Text('Outside')),
              bottomNavigationBar: LiquidGlassBottomNavigation(
                items: items,
                selectedIndex: 1,
                isCompact: compact,
                onTapOutside: () => setState(() => compact = true),
                onSelected: (_) => setState(() => compact = false),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Outside'));
    await tester.pump();
    expect(compact, isTrue);
    expect(find.text('Tasks'), findsNothing);
    for (final container in tester.widgetList<AnimatedContainer>(
      find.byType(AnimatedContainer),
    )) {
      expect(container.duration, Duration.zero);
    }
    expect(tester.takeException(), isNull);
  });

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
        var compact = false;
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
                    isCompact: compact,
                    onTapOutside: () => setState(() => compact = true),
                    onSelected: (index) => setState(() {
                      selected = index;
                      compact = false;
                    }),
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
              matching: find.byType(AnimatedContainer),
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
          await tester.tapAt(const Offset(20, 100));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 125));
          expect(tester.takeException(), isNull);
          await tester.pumpAndSettle();
          expect(compact, isTrue);
          expect(tester.getBottomLeft(surface).dy, closeTo(640 - 24 - 14, 0.1));
          expect(tester.takeException(), isNull);
        }
      },
    );
  }
}
