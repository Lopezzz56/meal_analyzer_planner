import 'package:flutter/material.dart';
import 'package:meal_analyzer_planner/components/theme.dart';
import 'package:meal_analyzer_planner/routes/router.dart';
import 'package:provider/provider.dart';
import 'routes/global_state.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => GlobalState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, 

    );
  }
}
