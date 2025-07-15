import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/map/screens/map_screen.dart';
import '../theme/app_theme.dart'; // ✅ Pridaj import

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    // ✅ Auth routes
    GoRoute(
      path: '/splash',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => const RegisterScreen(),
    ),

    // ✅ Map routes
    GoRoute(
      path: '/map',
      name: 'map',
      builder: (context, state) => const MapScreen(),
    ),

    // ✅ Zone detail route (zatiaľ placeholder)
    GoRoute(
      path: '/zone/:id',
      name: 'zone_detail',
      builder: (context, state) {
        final zoneId = state.pathParameters['id']!;
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Zone Details',
              style: GameTextStyles.clockTime.copyWith(
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            backgroundColor: AppTheme.primaryColor,
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Zone ID: $zoneId',
                  style: GameTextStyles.clockTime,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => context.go('/map'),
                  child: Text('Back to Map'),
                ),
              ],
            ),
          ),
        );
      },
    ),

    // ✅ TODO: Add these routes later
    // GoRoute(
    //   path: '/profile',
    //   name: 'profile',
    //   builder: (context, state) => const ProfileScreen(),
    // ),
    // GoRoute(
    //   path: '/inventory',
    //   name: 'inventory',
    //   builder: (context, state) => const InventoryScreen(),
    // ),
  ],
);
