import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:meal_analyzer_planner/screens/history/history.dart';
import 'package:meal_analyzer_planner/screens/meal_analysis.dart';
import 'package:meal_analyzer_planner/screens/meal_planner.dart';



final router = GoRouter(
  initialLocation: '/analysis',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return Scaffold(
          body: child,
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _getIndex(state.uri.toString()), 
            onTap: (index) {
              switch (index) {
                case 0:
                  context.go('/analysis');
                  break;
                case 1:
                  context.go('/planner');
                  break;
                case 2:
                  context.go('/history');
                  break;
              }
            },
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.camera), label: "Analysis"),
              BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: "Planner"),
              BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "History"),
            ],
          ),
        );
      },
      routes: [
        GoRoute(
          path: '/analysis',
          builder: (context, state) => const AnalysisScreen(),
        ),
        GoRoute(
          path: '/planner',
          builder: (context, state) => const PlannerScreen(),
        ),
        GoRoute(
          path: '/history',
          builder: (context, state) => const HistoryScreen(),
        ),
      ],
    ),
  ],
);

int _getIndex(String location) {
  if (location.startsWith('/planner')) return 1;
  if (location.startsWith('/history')) return 2;
  return 0;
}
