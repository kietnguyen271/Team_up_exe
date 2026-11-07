import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_tokens.dart';

/// The Android student shell. Administrators use a separate Android shell.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child, this.selectedIndex = 0});

  final Widget child;
  final int selectedIndex;

  void _select(BuildContext context, int index) {
    context.go(switch (index) {
      0 => '/home',
      1 => '/notifications',
      _ => '/profile-setup',
    });
  }

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: ReadingOrderTraversalPolicy(),
      child: Scaffold(
        appBar: AppBar(title: const Text(AppStrings.appName)),
        body: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: AppSizes.maxContentWidth),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s24),
              child: child,
            ),
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) => _select(context, index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.meeting_room_outlined),
              selectedIcon: Icon(Icons.meeting_room),
              label: AppStrings.rooms,
            ),
            NavigationDestination(
              icon: Icon(Icons.notifications_outlined),
              selectedIcon: Icon(Icons.notifications),
              label: AppStrings.notifications,
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: AppStrings.profile,
            ),
          ],
        ),
      ),
    );
  }
}
