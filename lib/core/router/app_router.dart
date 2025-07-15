import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/map/screens/map_screen.dart';
import '../../features/map/screens/zone_detail_screen.dart';

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

    // ✅ Main app routes
    GoRoute(
      path: '/map',
      name: 'map',
      builder: (context, state) => const MapScreen(),
    ),
    GoRoute(
      path: '/zone/:id',
      name: 'zone_detail',
      builder: (context, state) {
        final zoneId = state.pathParameters['id']!;
        return ZoneDetailScreen(zoneId: zoneId);
      },
    ),

    // ✅ TODO: Add these routes later when you create the screens
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
