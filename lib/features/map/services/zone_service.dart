import 'package:dio/dio.dart';
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
}
