import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_tokens.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({
    super.key,
    required this.child,
    required this.selectedIndex,
    required this.onSignOut,
  });

  final Widget child;
  final int selectedIndex;
  final Future<void> Function() onSignOut;

  void _select(BuildContext context, int index) =>
      context.go('/admin?tab=$index');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          AppStrings.adminHome,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          TextButton.icon(
            onPressed: onSignOut,
            icon: const Icon(Icons.logout),
            label: const Text(AppStrings.signOut),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final content = Center(
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: AppSizes.maxContentWidth),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s24),
                child: child,
              ),
            ),
          );
          if (constraints.maxWidth < AppSizes.desktopBreakpoint) return content;
          return Row(
            children: [
              NavigationRail(
                selectedIndex: selectedIndex,
                onDestinationSelected: (index) => _select(context, index),
                labelType: NavigationRailLabelType.all,
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.meeting_room_outlined),
                    label: Text(AppStrings.rooms),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.event_outlined),
                    label: Text(AppStrings.semester),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.notifications_outlined),
                    label: Text(AppStrings.notifications),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.bug_report_outlined),
                    label: Text(AppStrings.demoLog),
                  ),
                ],
              ),
              Expanded(child: content),
            ],
          );
        },
      ),
      bottomNavigationBar: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= AppSizes.desktopBreakpoint) {
            return const SizedBox.shrink();
          }
          return NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) => _select(context, index),
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.meeting_room_outlined),
                  label: AppStrings.rooms),
              NavigationDestination(
                  icon: Icon(Icons.event_outlined), label: AppStrings.semester),
              NavigationDestination(
                  icon: Icon(Icons.notifications_outlined),
                  label: AppStrings.notifications),
              NavigationDestination(
                  icon: Icon(Icons.bug_report_outlined),
                  label: AppStrings.demoLog),
            ],
          );
        },
      ),
    );
  }
}
