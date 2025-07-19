import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/map/screens/map_screen.dart';
import '../../features/map/screens/zone_detail_screen.dart';
import '../../features/map/screens/detector_screen.dart'; // ✅ PRIDANÉ
import '../../features/map/models/detector_model.dart'; // ✅ PRIDANÉ
import '../../features/inventory/screens/inventory_screen.dart';
import '../../features/inventory/screens/inventory_detail_screen.dart';
import '../../features/inventory/models/inventory_item_model.dart';
import '../theme/app_theme.dart';

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

    // ✅ Zone detail route
    GoRoute(
      path: '/zone/:id',
      name: 'zone_detail',
      builder: (context, state) {
        final zoneId = state.pathParameters['id']!;
        return ZoneDetailScreen(zoneId: zoneId);
      },
    ),

    // ✅ NOVÉ: Detector screen route
    GoRoute(
      path: '/zone/:zoneId/detector',
      name: 'detector',
      builder: (context, state) {
        final zoneId = state.pathParameters['zoneId']!;
        final detector = state.extra as Detector;
        return DetectorScreen(zoneId: zoneId, detector: detector);
      },
    ),

    // ✅ Inventory routes
    GoRoute(
      path: '/inventory',
      name: 'inventory',
      builder: (context, state) => const InventoryScreen(),
    ),
    GoRoute(
      path: '/inventory/detail',
      name: 'inventory_detail',
      builder: (context, state) {
        final item = state.extra as InventoryItem;
        return InventoryDetailScreen(item: item);
      },
    ),

    // ✅ Profile routes (placeholder)
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          title: Text(
            'Profile',
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
                'Profile Screen',
                style: GameTextStyles.clockTime,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => context.go('/map'),
                child: const Text('Back to Map'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => context.go('/inventory'),
                child: const Text('View Inventory'),
              ),
            ],
          ),
        ),
      ),
    ),

    // ✅ Scanner routes (placeholder)
    GoRoute(
      path: '/scanner',
      name: 'scanner',
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          title: Text(
            'Zone Scanner',
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
                'Scanning for zones...',
                style: GameTextStyles.clockTime,
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => context.go('/map'),
                child: const Text('Back to Map'),
              ),
            ],
          ),
        ),
      ),
    ),
  ],
);
