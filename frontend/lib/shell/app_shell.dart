import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/calculator/calculator_screen.dart';
import '../features/dashboard/dashboard_provider.dart';
import '../features/dashboard/explorer_dashboard_screen.dart';
import '../features/dashboard/operational_dashboard_screen.dart';
import '../features/learning/trilhas_screen.dart';
import '../features/profile/profile_screen.dart';
import '../shared/widgets/bio_tab_bar.dart';

/// Hosts the 4 bottom tabs, each with its own nested [Navigator] so pushing a
/// sub-screen (e.g. a trilha's module content) keeps the tab bar visible.
///
/// IMPORTANT: any code that needs to replace the *entire app* (login,
/// logout) must escape these nested Navigators with
/// `Navigator.of(context, rootNavigator: true)` — a plain `Navigator.of
/// (context)` from inside a tab resolves to that tab's own nested Navigator,
/// not the root one, and merely stacks a screen on top of this shell instead
/// of replacing it.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  final ValueNotifier<bool> _explorerMode = ValueNotifier(false);

  final List<GlobalKey<NavigatorState>> _navigatorKeys = List.generate(4, (_) => GlobalKey<NavigatorState>());

  static const _tabs = [
    BioTabItem('calc', 'Calcular'),
    BioTabItem('chart', 'Dashboard'),
    BioTabItem('book', 'Trilhas'),
    BioTabItem('user', 'Perfil'),
  ];

  void _onTabTap(int index) {
    if (index == _index) {
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
    } else {
      setState(() => _index = index);
      // The 4 tabs live in an IndexedStack, so each one's widget is built once (on app start) and
      // just hidden/shown afterward — its initState never runs again, so without this its data
      // (here: CO2/economy totals and the trend chart) would stay frozen at whatever it was when
      // the app launched, never picking up calculations made after that.
      if (index == 1) {
        context.read<DashboardProvider>().load();
      }
    }
  }

  Widget _tabNavigator(int index, Widget child) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (settings) => MaterialPageRoute(builder: (_) => child),
    );
  }

  @override
  void dispose() {
    _explorerMode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          _tabNavigator(0, const CalculatorScreen()),
          _tabNavigator(
            1,
            // A nested Navigator only calls onGenerateRoute once per route, so a
            // child built from state captured at that moment never updates on
            // later rebuilds — the swap must happen inside this static child via
            // a listenable instead of by picking a different widget up here.
            ValueListenableBuilder<bool>(
              valueListenable: _explorerMode,
              builder: (_, explorer, __) => explorer
                  ? ExplorerDashboardScreen(onSwitch: () => _explorerMode.value = false)
                  : OperationalDashboardScreen(onSwitch: () => _explorerMode.value = true),
            ),
          ),
          _tabNavigator(2, const TrilhasScreen()),
          _tabNavigator(3, const ProfileScreen()),
        ],
      ),
      bottomNavigationBar: BioTabBar(currentIndex: _index, onTap: _onTabTap, items: _tabs),
    );
  }
}
