import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/motion/ocean_quality.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/ocean_colors.dart';
import '../ocean/ocean_backdrop.dart';
import '../ocean/ocean_glass_panel.dart';
import 'floating_nav_bar.dart';

/// The Android student shell. Administrators use a separate Android shell.
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.child,
    this.selectedIndex = 0,
    this.openOcean = false,
  });

  final Widget child;
  final int selectedIndex;
  final bool openOcean;

  void _select(BuildContext context, int index) {
    context.go(switch (index) {
      0 => '/home',
      1 => '/notifications',
      _ => '/profile-setup',
    });
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Ocean.settings.setParallax(tabIndex: selectedIndex);
    });
    final ocean = Theme.of(context).extension<OceanColors>()!;
    return FocusTraversalGroup(
      policy: ReadingOrderTraversalPolicy(),
      child: Scaffold(
        backgroundColor: AppPalette.transparent,
        extendBody: true,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const OceanGlassPanel(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.s16,
              vertical: AppSpacing.s4,
            ),
            child: Text(AppStrings.appName),
          ),
          backgroundColor: AppPalette.transparent,
          foregroundColor: ocean.deepNavy,
          surfaceTintColor: AppPalette.transparent,
          systemOverlayStyle: AppTheme.oceanSystemBars,
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
                  bottom: AppSizes.navHeight + AppSpacing.s24 + AppSpacing.s24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppSizes.maxContentWidth,
                    ),
                    child: openOcean
                        ? child
                        : Padding(
                            padding: const EdgeInsets.all(AppSpacing.s16),
                            child: OceanGlassPanel(child: child),
                          ),
                  ),
                ),
              ),
            ),
            if (!openOcean)
              const Positioned(
                right: AppSpacing.s8,
                bottom: AppSizes.navHeight + AppSpacing.s24,
                child: OceanDebugBadge(),
              ),
          ],
        ),
        bottomNavigationBar: FloatingNavBar(
          selectedIndex: selectedIndex,
          onSelected: (index) => _select(context, index),
          destinations: const [
            FloatingNavDestination(
              icon: Icons.meeting_room_outlined,
              label: AppStrings.rooms,
            ),
            FloatingNavDestination(
              icon: Icons.notifications_outlined,
              label: AppStrings.notifications,
            ),
            FloatingNavDestination(
              icon: Icons.person_outline,
              label: AppStrings.profile,
            ),
          ],
        ),
      ),
    );
  }
}
