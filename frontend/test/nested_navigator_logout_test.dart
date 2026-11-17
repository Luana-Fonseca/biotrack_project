import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression test for the "logout duplicates the bottom menu" bug:
/// a screen living inside a nested per-tab Navigator (like ProfileScreen
/// inside AppShell) must use `Navigator.of(context, rootNavigator: true)`
/// to replace the whole app on logout — a plain `Navigator.of(context)`
/// resolves to the nested Navigator and just stacks the new screen on top
/// of the shell instead of replacing it, leaving the tab bar visible
/// underneath (and stacking a second one on the next login).
void main() {
  Widget shellWithNestedScreen(void Function(BuildContext) onButtonTap) {
    return MaterialApp(
      home: Scaffold(
        bottomNavigationBar: Container(key: const Key('SHELL_TAB_BAR'), height: 50, color: Colors.blue),
        body: Navigator(
          onGenerateRoute: (settings) => MaterialPageRoute(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => onButtonTap(context),
                  child: const Text('Sair'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('BUGGY: Navigator.of(context) without rootNavigator nests instead of replacing', (tester) async {
    await tester.pumpWidget(shellWithNestedScreen((context) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const Scaffold(body: Text('Landing'))),
        (route) => false,
      );
    }));

    expect(find.byKey(const Key('SHELL_TAB_BAR')), findsOneWidget);
    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();

    expect(find.text('Landing'), findsOneWidget);
    // The tab bar is still mounted underneath — the bug.
    expect(find.byKey(const Key('SHELL_TAB_BAR')), findsOneWidget);
  });

  testWidgets('FIXED: Navigator.of(context, rootNavigator: true) replaces the whole app', (tester) async {
    await tester.pumpWidget(shellWithNestedScreen((context) {
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const Scaffold(body: Text('Landing'))),
        (route) => false,
      );
    }));

    expect(find.byKey(const Key('SHELL_TAB_BAR')), findsOneWidget);
    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();

    expect(find.text('Landing'), findsOneWidget);
    expect(find.byKey(const Key('SHELL_TAB_BAR')), findsNothing);
  });
}
