import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/motion/ocean_quality.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/ocean_colors.dart';
import '../../../shared/ocean/ocean_backdrop.dart';
import '../../../shared/ocean/ocean_effects_control.dart';
import '../../../shared/ocean/ocean_glass_panel.dart';
import '../../../shared/widgets/floating_nav_bar.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Ocean.settings.setParallax(tabIndex: selectedIndex);
    });
    final ocean = Theme.of(context).extension<OceanColors>()!;
    return Scaffold(
      backgroundColor: AppPalette.transparent,
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppPalette.transparent,
        foregroundColor: ocean.deepNavy,
        surfaceTintColor: AppPalette.transparent,
        systemOverlayStyle: AppTheme.oceanSystemBars,
        title: OceanGlassPanel(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s8,
            vertical: AppSpacing.s4,
          ),
          child: Text(
            MediaQuery.sizeOf(context).width < AppSizes.desktopBreakpoint
                ? AppStrings.adminShortTitle
                : AppStrings.adminHome,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        actions: [
          const OceanGlassPanel(
            padding: EdgeInsets.zero,
            child: OceanEffectsMenu(),
          ),
          OceanGlassPanel(
            padding: EdgeInsets.zero,
            child: TextButton.icon(
              onPressed: onSignOut,
              icon: const Icon(Icons.logout),
              label: const Text(AppStrings.signOut),
            ),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const OceanBackdrop(showDebugOverlay: false),
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              Ocean.settings
                  .setParallax(scrollOffset: notification.metrics.pixels);
              return false;
            },
            child: Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.paddingOf(context).top + kToolbarHeight,
                bottom: MediaQuery.sizeOf(context).width <
                        AppSizes.desktopBreakpoint
                    ? AppSizes.navHeight + AppSpacing.s24 + AppSpacing.s24
                    : AppSpacing.s16,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final content = Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                          maxWidth: AppSizes.maxContentWidth),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.s16),
                        child: OceanGlassPanel(child: child),
                      ),
                    ),
                  );
                  if (constraints.maxWidth < AppSizes.desktopBreakpoint)
                    return content;
                  return Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.s16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.r20),
                          child: NavigationRail(
                            backgroundColor: ocean.seaGlass,
                            selectedIndex: selectedIndex,
                            onDestinationSelected: (index) =>
                                _select(context, index),
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
                        ),
                      ),
                      Expanded(child: content),
                    ],
                  );
                },
              ),
            ),
          ),
          Positioned(
            right: AppSpacing.s8,
            bottom:
                MediaQuery.sizeOf(context).width < AppSizes.desktopBreakpoint
                    ? AppSizes.navHeight + AppSpacing.s16
                    : AppSpacing.s8,
            child: const OceanDebugBadge(),
          ),
        ],
      ),
      bottomNavigationBar: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= AppSizes.desktopBreakpoint) {
            return const SizedBox.shrink();
          }
          return FloatingNavBar(
            selectedIndex: selectedIndex,
            onSelected: (index) => _select(context, index),
            destinations: const [
              FloatingNavDestination(
                  icon: Icons.meeting_room_outlined, label: AppStrings.rooms),
              FloatingNavDestination(
                  icon: Icons.event_outlined, label: AppStrings.semester),
              FloatingNavDestination(
                  icon: Icons.notifications_outlined,
                  label: AppStrings.notifications),
              FloatingNavDestination(
                  icon: Icons.bug_report_outlined, label: AppStrings.demoLog),
            ],
          );
        },
      ),
    );
  }
}
