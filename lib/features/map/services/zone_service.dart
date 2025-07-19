import 'package:dio/dio.dart';
import 'dart:math' as math;
import '../../../core/network/api_client.dart';
import '../models/zone_model.dart';
import '../models/scan_result_model.dart';
import '../models/location_model.dart';

class ZoneService {
  final Dio _dio = ApiClient.dio;

  Future<ScanResultModel> scanArea(LocationModel location) async {
    try {
      print('🔍 Scanning area: ${location.latitude}, ${location.longitude}');

      // ✅ Skontroluj auth token
      if (ApiClient.authToken == null) {
        throw Exception('Authentication required. Please login first.');
      }

      final response = await _dio.post(
        '/game/scan-area',
        data: {
          'latitude': location.latitude,
          'longitude': location.longitude,
        },
      );

      print('✅ Scan area response: ${response.data}');
      return ScanResultModel.fromJson(response.data);
    } on DioException catch (e) {
      print('❌ Scan area DioException: ${e.response?.statusCode}');
      print('❌ Response data: ${e.response?.data}');

      if (e.response?.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else if (e.response?.statusCode == 403) {
        throw Exception('Access forbidden. Check your tier level.');
      } else if (e.response?.statusCode == 429) {
        throw Exception(
            'Scan cooldown active. Please wait before scanning again.');
      } else {
        throw Exception(
            'Failed to scan area: ${e.response?.data?['error'] ?? e.message}');
      }
    } catch (e) {
      print('❌ Unexpected scan area error: $e');
      throw Exception('Unexpected error occurred while scanning area');
    }
  }

  Future<List<Zone>> getNearbyZones(LocationModel location,
      {double radius = 5000}) async {
    try {
      print(
          '🔍 Getting nearby zones: ${location.latitude}, ${location.longitude}');

      final response = await _dio.get(
        '/game/zones/nearby',
        queryParameters: {
          'lat': location.latitude,
          'lng': location.longitude,
          'radius': radius,
        },
      );

      print('✅ Nearby zones response: ${response.data}');
      return (response.data['zones'] as List? ?? [])
          .map((zone) => Zone.fromJson(zone))
          .toList();
    } on DioException catch (e) {
      print('❌ Nearby zones error: ${e.response?.data}');
      throw Exception('Failed to get nearby zones: ${e.message}');
    } catch (e) {
      print('❌ Unexpected nearby zones error: $e');
      throw Exception('Unexpected error occurred while getting nearby zones');
    }
  }

  Future<Zone> getZoneDetails(String zoneId) async {
    try {
      print('🔍 Getting zone details: $zoneId');

      final response = await _dio.get('/game/zones/$zoneId');

      print('✅ Zone details response: ${response.data}');
      return Zone.fromJson(response.data['zone']);
    } on DioException catch (e) {
      print('❌ Zone details error: ${e.response?.data}');
      throw Exception('Failed to get zone details: ${e.message}');
    } catch (e) {
      print('❌ Unexpected zone details error: $e');
      throw Exception('Unexpected error occurred while getting zone details');
    }
  }

  Future<Map<String, dynamic>> enterZone(String zoneId) async {
    try {
      print('🚪 Entering zone: $zoneId');

      final response = await _dio.post('/game/zones/$zoneId/enter');

      print('✅ Enter zone response: ${response.data}');
      return response.data;
    } on DioException catch (e) {
      print('❌ Enter zone error: ${e.response?.data}');
      throw Exception('Failed to enter zone: ${e.message}');
    } catch (e) {
      print('❌ Unexpected enter zone error: $e');
      throw Exception('Unexpected error occurred while entering zone');
    }
  }

  Future<Map<String, dynamic>> exitZone(String zoneId) async {
    try {
      print('🚪 Exiting zone: $zoneId');

      final response = await _dio.post('/game/zones/$zoneId/exit');

      print('✅ Exit zone response: ${response.data}');
      return response.data;
    } on DioException catch (e) {
      print('❌ Exit zone error: ${e.response?.data}');
      throw Exception('Failed to exit zone: ${e.message}');
    } catch (e) {
      print('❌ Unexpected exit zone error: $e');
      throw Exception('Unexpected error occurred while exiting zone');
    }
  }

  Future<Map<String, dynamic>> scanZone(String zoneId) async {
    try {
      print('🔍 Scanning zone: $zoneId');

      final response = await _dio.get('/game/zones/$zoneId/scan');

      print('✅ Scan zone response: ${response.data}');
      return response.data;
    } on DioException catch (e) {
      print('❌ Scan zone error: ${e.response?.data}');
      throw Exception('Failed to scan zone: ${e.message}');
    } catch (e) {
      print('❌ Unexpected scan zone error: $e');
      throw Exception('Unexpected error occurred while scanning zone');
    }
  }

  // ✅ NEW: Enhanced method for detector screen
  Future<Map<String, dynamic>> getZoneArtifacts(String zoneId) async {
    try {
      print('🔍🎯 Getting zone artifacts for detector: $zoneId');

      // Use existing scanZone method - it returns exactly what we need!
      final scanResult = await scanZone(zoneId);

      final artifactCount = scanResult['total_artifacts'] ?? 0;
      final gearCount = scanResult['total_gear'] ?? 0;
      final totalItems = artifactCount + gearCount;

      print(
          '✅🎯 Detector data loaded: $artifactCount artifacts, $gearCount gear ($totalItems total items)');

      // Validate that we have GPS coordinates for items
      final artifacts = scanResult['artifacts'] as List? ?? [];
      final gear = scanResult['gear'] as List? ?? [];

      int itemsWithGPS = 0;
      for (final artifact in artifacts) {
        if (artifact['location'] != null &&
            artifact['location']['latitude'] != null &&
            artifact['location']['longitude'] != null) {
          itemsWithGPS++;
        }
      }

      for (final gearItem in gear) {
        if (gearItem['location'] != null &&
            gearItem['location']['latitude'] != null &&
            gearItem['location']['longitude'] != null) {
          itemsWithGPS++;
        }
      }

      print('📍 Items with GPS coordinates: $itemsWithGPS/$totalItems');

      if (totalItems > 0 && itemsWithGPS == 0) {
        throw Exception(
            'No items have GPS coordinates for detector navigation');
      }

      return scanResult;
    } catch (e) {
      print('❌🎯 Failed to get zone artifacts for detector: $e');
      if (e.toString().contains('Not in zone')) {
        throw Exception(
            'You must enter the zone first before using the detector');
      }
      throw Exception('Failed to load detector data: $e');
    }
  }

  // ✅ NEW: Distance calculation using Haversine formula
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadiusMeters = 6371000; // Earth's radius in meters

    // Convert degrees to radians
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    final double lat1Rad = _toRadians(lat1);
    final double lat2Rad = _toRadians(lat2);

    // Haversine formula
    final double a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) * math.pow(math.sin(dLon / 2), 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusMeters * c; // Distance in meters
  }

  // ✅ NEW: Calculate bearing between two points (for direction)
  double calculateBearing(double lat1, double lon1, double lat2, double lon2) {
    final double dLon = _toRadians(lon2 - lon1);
    final double lat1Rad = _toRadians(lat1);
    final double lat2Rad = _toRadians(lat2);

    final double y = math.sin(dLon) * math.cos(lat2Rad);
    final double x = math.cos(lat1Rad) * math.sin(lat2Rad) -
        math.sin(lat1Rad) * math.cos(lat2Rad) * math.cos(dLon);

    final double bearingRad = math.atan2(y, x);
    final double bearingDeg = _toDegrees(bearingRad);

    // Normalize to 0-360 degrees
    return (bearingDeg + 360) % 360;
  }

  // ✅ NEW: Convert bearing to compass direction
  String bearingToCompass(double bearing) {
    const List<String> directions = [
      'N',
      'NNE',
      'NE',
      'ENE',
      'E',
      'ESE',
      'SE',
      'SSE',
      'S',
      'SSW',
      'SW',
      'WSW',
      'W',
      'WNW',
      'NW',
      'NNW'
    ];

    final int index = ((bearing + 11.25) / 22.5).floor() % 16;
    return directions[index];
  }

  // ✅ NEW: Get simple compass direction (N, NE, E, SE, S, SW, W, NW)
  String bearingToSimpleCompass(double bearing) {
    const List<String> directions = [
      'N',
      'NE',
      'E',
      'SE',
      'S',
      'SW',
      'W',
      'NW'
    ];
    final int index = ((bearing + 22.5) / 45).floor() % 8;
    return directions[index];
  }

  // ✅ NEW: Calculate signal strength based on distance and detector properties
  double calculateSignalStrength(
    double distanceMeters, {
    double maxRangeMeters = 500.0,
    double precisionFactor = 1.0,
    String? itemRarity,
  }) {
    if (distanceMeters <= 0) return 1.0;
    if (distanceMeters >= maxRangeMeters) return 0.0;

    // Base strength calculation (inverse distance)
    double baseStrength = 1.0 - (distanceMeters / maxRangeMeters);

    // Apply precision factor (better detectors have better precision)
    baseStrength = math.pow(baseStrength, 1.0 / precisionFactor).toDouble();

    // Rarity bonus (rarer items give stronger signals)
    double rarityMultiplier = 1.0;
    switch (itemRarity?.toLowerCase()) {
      case 'legendary':
        rarityMultiplier = 1.5;
        break;
      case 'epic':
        rarityMultiplier = 1.3;
        break;
      case 'rare':
        rarityMultiplier = 1.2;
        break;
      case 'common':
      default:
        rarityMultiplier = 1.0;
        break;
    }

    return (baseStrength * rarityMultiplier).clamp(0.0, 1.0);
  }

  // ✅ NEW: Format distance for display
  String formatDistance(double distanceMeters) {
    if (distanceMeters < 1.0) {
      return '${(distanceMeters * 100).toInt()}cm';
    } else if (distanceMeters < 1000.0) {
      return '${distanceMeters.toInt()}m';
    } else {
      return '${(distanceMeters / 1000.0).toStringAsFixed(1)}km';
    }
  }

  // ✅ NEW: Collection method for detector
  Future<Map<String, dynamic>> collectItem(
      String zoneId, String itemType, String itemId) async {
    try {
      print('🎯💎 Collecting $itemType: $itemId from zone: $zoneId');

      final response = await _dio.post(
        '/game/zones/$zoneId/collect',
        data: {
          'item_type': itemType,
          'item_id': itemId,
        },
      );

      print('✅💎 Collection successful: ${response.data}');
      return response.data;
    } on DioException catch (e) {
      print('❌💎 Collection error: ${e.response?.data}');

      if (e.response?.statusCode == 400) {
        final errorMsg = e.response?.data?['error'] ?? 'Collection failed';
        throw Exception(errorMsg);
      } else if (e.response?.statusCode == 403) {
        throw Exception(
            'Cannot collect this item. Check your tier level or proximity.');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Item not found or already collected.');
      } else {
        throw Exception(
            'Failed to collect item: ${e.response?.data?['error'] ?? e.message}');
      }
    } catch (e) {
      print('❌💎 Unexpected collection error: $e');
      throw Exception('Unexpected error occurred while collecting item');
    }
  }

  // ✅ Helper method pre debugging
  Future<bool> testBackendConnection() async {
    try {
      final response = await _dio.get('/test');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Backend connection test failed: $e');
      return false;
    }
  }

  // ✅ Private helper methods
  double _toRadians(double degrees) => degrees * math.pi / 180.0;
  double _toDegrees(double radians) => radians * 180.0 / math.pi;
}
