import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
// import '../../features/map/screens/map_screen.dart'; // ✅ Uncomment keď vytvoríš map screen

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

    // ✅ TODO: Map routes (pridaj keď vytvoríš map screen)
    // GoRoute(
    //   path: '/map',
    //   name: 'map',
    //   builder: (context, state) => const MapScreen(),
    // ),
  ],
);
