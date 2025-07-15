import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/network/api_client.dart';
import 'app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize API client
  ApiClient.initialize();

  runApp(
    const ProviderScope(
      child: GeoAnomalyApp(),
    ),
  );
}
