import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:spiral_notebook/app_state.dart';
import 'package:spiral_notebook/theme/app_palette.dart';
import 'package:spiral_notebook/widgets/tutorial_overlay.dart';

/// Returns the global rect of the golden spotlight border drawn by the overlay.
Rect _spotlightRect(WidgetTester tester) {
  final Finder finder = find.byWidgetPredicate((Widget widget) {
    if (widget is DecoratedBox) {
      final Decoration decoration = widget.decoration;
      if (decoration is BoxDecoration && decoration.border is Border) {
        return (decoration.border! as Border).top.color == AppPalette.sun;
      }
    }
    return false;
  });
  expect(finder, findsOneWidget);
  return tester.getRect(finder);
}

void main() {
  testWidgets('spotlight centers on the target and follows step changes', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final SpiralAppState appState = SpiralAppState();
    addTearDown(appState.dispose);
    final TutorialTargetKeys targetKeys = TutorialTargetKeys();

    appState.startTutorial(); // active, step = inventoryWelcome

    await tester.pumpWidget(
      MaterialApp(
        home: AnimatedBuilder(
          animation: appState,
          builder: (BuildContext context, Widget? _) {
            return Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Scaffold(
                  // A real app bar offsets the body; the spotlight must still
                  // line up with the target in global/screen coordinates.
                  appBar: AppBar(title: const Text('Header')),
                  body: Column(
                    children: <Widget>[
                      const SizedBox(height: 40),
                      Container(
                        key: targetKeys.inventoryHero,
                        height: 80,
                        width: 240,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 300),
                      Container(
                        key: targetKeys.bits,
                        height: 60,
                        width: 240,
                        color: Colors.blue,
                      ),
                    ],
                  ),
                ),
                TutorialOverlay(
                  appState: appState,
                  targetKeys: targetKeys,
                  onPrimary: () {},
                  onSkip: () {},
                ),
              ],
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Step 1 -> inventoryHero. The spotlight must be centered on the target
    // (not shifted down by the app bar height: that was the bug).
    final Rect heroRect = tester.getRect(find.byKey(targetKeys.inventoryHero));
    final Rect spotlight1 = _spotlightRect(tester);
    expect((spotlight1.center - heroRect.center).distance, lessThan(2));

    // Step 2 -> bits. The spotlight must move to the new target rather than
    // staying frozen on the first one.
    appState.setTutorialStep(TutorialStep.bitsBalance);
    await tester.pumpAndSettle();

    final Rect bitsRect = tester.getRect(find.byKey(targetKeys.bits));
    final Rect spotlight2 = _spotlightRect(tester);
    expect((spotlight2.center - bitsRect.center).distance, lessThan(2));
    expect(
      (spotlight2.center.dy - spotlight1.center.dy).abs(),
      greaterThan(100),
    );
  });

  testWidgets('spotlight highlights a bottom NavigationBar destination', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final SpiralAppState appState = SpiralAppState();
    addTearDown(appState.dispose);
    final TutorialTargetKeys targetKeys = TutorialTargetKeys();

    appState.startTutorial();
    appState.setTutorialStep(TutorialStep.openFocus); // step -> focusTab

    await tester.pumpWidget(
      MaterialApp(
        home: AnimatedBuilder(
          animation: appState,
          builder: (BuildContext context, Widget? _) {
            return Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Scaffold(
                  appBar: AppBar(title: const Text('Header')),
                  body: const SizedBox.expand(),
                  bottomNavigationBar: NavigationBar(
                    selectedIndex: 1,
                    destinations: <Widget>[
                      const NavigationDestination(
                        icon: Icon(Icons.auto_awesome),
                        label: 'Gacha',
                      ),
                      const NavigationDestination(
                        icon: Icon(Icons.home_rounded),
                        label: 'Inventory',
                      ),
                      NavigationDestination(
                        key: targetKeys.focusTab,
                        icon: const Icon(Icons.hourglass_bottom),
                        label: 'Focus',
                      ),
                    ],
                  ),
                ),
                TutorialOverlay(
                  appState: appState,
                  targetKeys: targetKeys,
                  onPrimary: () {},
                  onSkip: () {},
                ),
              ],
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Rect tabRect = tester.getRect(find.byKey(targetKeys.focusTab));
    final Rect spotlight = _spotlightRect(tester);

    // The nav destination key must resolve to a real render box (not fall back
    // to a centered rect), and the full-screen overlay must reach the bottom
    // bar to highlight it.
    expect((spotlight.center - tabRect.center).distance, lessThan(2));
    expect(spotlight.center.dy, greaterThan(1000));
  });
}
