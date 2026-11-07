import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/app_strings.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'shared/widgets/firebase_setup_screen.dart';

final appScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class TeamUpApp extends StatelessWidget {
  const TeamUpApp({super.key, this.startupError, this.router});

  final String? startupError;
  final GoRouter? router;

  @override
  Widget build(BuildContext context) {
    if (startupError != null) {
      return MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: FirebaseSetupScreen(error: startupError!),
      );
    }
    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      scaffoldMessengerKey: appScaffoldMessengerKey,
      routerConfig: router ?? AppRouter.router,
    );
  }
}
