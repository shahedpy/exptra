import 'package:flutter/material.dart';

import '../dashboard/dashboard_page.dart';
import '../income_expense/income_expense_page.dart';
import '../lend_borrow/lend_borrow_page.dart';
import '../settings/more_page.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  static const List<Widget> _pages = [
    DashboardPage(),
    IncomeExpensePage(),
    LendBorrowPage(),
    MorePage(),
  ];

  static const List<_NavItemData> _navItems = [
    _NavItemData(label: 'Dashboard', icon: Icons.dashboard_rounded),
    _NavItemData(label: 'Inc/Exp', icon: Icons.swap_vert_rounded),
    _NavItemData(label: 'Len/Bor', icon: Icons.sync_alt_rounded),
    _NavItemData(label: 'More', icon: Icons.grid_view_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer.withValues(alpha: 0.88),
        ),
        child: SafeArea(
          top: false,
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              indicatorColor: colorScheme.secondaryContainer,
              labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((
                states,
              ) {
                final selected = states.contains(WidgetState.selected);
                return Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: selected
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                );
              }),
              iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>((
                states,
              ) {
                final selected = states.contains(WidgetState.selected);
                return IconThemeData(
                  color: selected
                      ? colorScheme.onSecondaryContainer
                      : colorScheme.onSurfaceVariant,
                  size: 20,
                );
              }),
            ),
            child: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) =>
                  setState(() => _currentIndex = index),
              backgroundColor: Colors.transparent,
              destinations: _navItems
                  .map(
                    (item) => NavigationDestination(
                      icon: Icon(item.icon),
                      label: item.label,
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final String label;
  final IconData icon;

  const _NavItemData({required this.label, required this.icon});
}
