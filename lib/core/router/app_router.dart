import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../features/admin/data/firebase_admin_access.dart';
import '../../features/admin/domain/admin_access_service.dart';
import '../../features/admin/presentation/admin_home_screen.dart';
import '../../features/auth/presentation/auth_form_screen.dart';
import '../../features/debug_firebase/presentation/debug_firebase_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/home/presentation/room_landing_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/profile/presentation/profile_setup_screen.dart';
import '../../features/ui_gallery/presentation/ui_gallery_screen.dart';
import '../../features/ui_gallery/presentation/ocean_gallery_screen.dart';
import '../../features/servers/presentation/server_picker_screen.dart';
import '../../shared/widgets/generic_error_screen.dart';
import '../../shared/widgets/splash_screen.dart';
import '../../shared/ocean/reef_standalone_scaffold.dart';
import '../constants/app_strings.dart';
import '../notifications/notification_runtime.dart';
import '../theme/app_tokens.dart';
import 'app_session.dart';

abstract final class AppRouter {
  static final GoRouter router = create();

  static String routeForStage(SessionStage stage) => switch (stage) {
        SessionStage.signedOut => '/login',
        SessionStage.invalidEmail => '/invalid-email',
        SessionStage.needsProfile => '/profile-setup',
        SessionStage.needsServer => '/servers',
        SessionStage.student => '/home',
        SessionStage.completed => '/completed',
        SessionStage.admin => '/admin',
      };

  static GoRouter create({bool isWeb = kIsWeb, AppSession? session}) {
    final guard = session ?? FirebaseAppSession();
    final adminAccess = AdminAccessService(
      FirebaseAdminAuthGateway(),
      FirestoreAdminDirectory(),
    );
    return GoRouter(
      initialLocation: '/gate',
      redirect: (context, state) async {
        final path = state.uri.path;
        if (isWeb) return path == '/unsupported' ? null : '/unsupported';
        if (kDebugMode &&
            (path == '/debug-firebase' || path.startsWith('/ui-gallery')))
          return null;
        final stage = await guard.resolve();
        if (path == '/login' || path == '/register') {
          return stage == SessionStage.signedOut ? null : '/gate';
        }
        if (path == '/invalid-email') {
          return stage == SessionStage.invalidEmail ? null : '/gate';
        }
        if (path == '/gate') {
          return routeForStage(stage);
        }
        if (path == '/admin') {
          return stage == SessionStage.admin ? null : '/gate';
        }
        if (path == '/completed') {
          return stage == SessionStage.completed ? null : '/gate';
        }
        if (path == '/profile-setup') {
          return stage == SessionStage.needsProfile ||
                  stage == SessionStage.needsServer ||
                  stage == SessionStage.student
              ? null
              : '/gate';
        }
        if (path == '/servers') {
          return stage == SessionStage.needsServer ||
                  stage == SessionStage.student
              ? null
              : '/gate';
        }
        if (path == '/home' ||
            path == '/notifications' ||
            path.startsWith('/rooms/')) {
          return stage == SessionStage.student ? null : '/gate';
        }
        return '/gate';
      },
      errorBuilder: (context, state) =>
          GenericErrorScreen(onRetry: () => context.go('/gate')),
      routes: [
        GoRoute(
            path: '/gate', builder: (context, state) => const SplashScreen()),
        GoRoute(
          path: '/unsupported',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text(AppStrings.androidOnly)),
          ),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) =>
              const AuthFormScreen(isRegistration: false),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) =>
              const AuthFormScreen(isRegistration: true),
        ),
        GoRoute(
          path: '/invalid-email',
          builder: (context, state) => ReefStandaloneScaffold(
            title: AppStrings.invalidSchoolEmail,
            child: FilledButton(
              onPressed: () async {
                await NotificationRuntime.instance.beforeSignOut();
                await FirebaseAuth.instance.signOut();
                if (context.mounted) context.go('/login');
              },
              child: const Text(AppStrings.signOut),
            ),
          ),
        ),
        GoRoute(
          path: '/profile-setup',
          builder: (context, state) => const ProfileSetupScreen(),
        ),
        GoRoute(
          path: '/servers',
          builder: (context, state) => const ServerPickerScreen(),
        ),
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/rooms/:roomId',
          builder: (context, state) =>
              RoomLandingScreen(roomId: state.pathParameters['roomId']!),
        ),
        GoRoute(
          path: '/admin',
          builder: (context, state) => AdminHomeScreen(
            access: adminAccess,
            selectedIndex:
                int.tryParse(state.uri.queryParameters['tab'] ?? '') ?? 0,
          ),
        ),
        GoRoute(
          path: '/completed',
          builder: (context, _) => ReefStandaloneScaffold(
            title: AppStrings.completed,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(AppStrings.completedIntro,
                    style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: AppSpacing.s24),
                FilledButton(
                  onPressed: () async {
                    await NotificationRuntime.instance.beforeSignOut();
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) context.go('/login');
                  },
                  child: const Text(AppStrings.signOut),
                ),
              ],
            ),
          ),
        ),
        if (kDebugMode)
          GoRoute(
            path: '/debug-firebase',
            builder: (context, state) => const DebugFirebaseScreen(),
          ),
        if (kDebugMode)
          GoRoute(
            path: '/ui-gallery',
            builder: (context, state) => const UiGalleryScreen(),
          ),
        if (kDebugMode)
          GoRoute(
            path: '/ui-gallery/ocean',
            builder: (context, state) => const OceanGalleryScreen(),
          ),
      ],
    );
  }
}
