import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'scores_screen.dart';
import 'calendar_screen.dart';
import 'tasks_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const ScoresScreen(),
    const CalendarScreen(),
    const TasksScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          elevation: 0,
          backgroundColor: Theme.of(context).colorScheme.surface,
          indicatorColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.dashboard_rounded, color: Colors.grey.shade600),
              selectedIcon: Icon(Icons.dashboard_rounded, color: Theme.of(context).colorScheme.primary),
              label: 'Portal',
            ),
            NavigationDestination(
              icon: Icon(Icons.analytics_rounded, color: Colors.grey.shade600),
              selectedIcon: Icon(Icons.analytics_rounded, color: Theme.of(context).colorScheme.primary),
              label: 'Metrics',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_rounded, color: Colors.grey.shade600),
              selectedIcon: Icon(Icons.calendar_month_rounded, color: Theme.of(context).colorScheme.primary),
              label: 'Calendar',
            ),
            NavigationDestination(
              icon: Icon(Icons.task_alt_rounded, color: Colors.grey.shade600),
              selectedIcon: Icon(Icons.task_alt_rounded, color: Theme.of(context).colorScheme.primary),
              label: 'Goals',
            ),
          ],
        ),
      ),
    );
  }
}
