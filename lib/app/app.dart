import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/router/app_router.dart';
import '../core/theme/app_theme.dart';

class GeoAnomalyApp extends ConsumerWidget {
  const GeoAnomalyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'GeoAnomaly',
      theme: AppTheme.theme, // ✅ Používa centralizovaný theme
      routerConfig: appRouter, // ✅ Používa centralizovaný router
      debugShowCheckedModeBanner: false,
    );
  }
}
