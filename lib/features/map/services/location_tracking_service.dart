import 'dart:async';
import 'dart:math' as dart_math;
import '../../../core/models/zone_model.dart';
import '../models/location_model.dart';
import 'location_service.dart';
import 'zone_service.dart';

class LocationTrackingService {
  static LocationTrackingService? _instance;
  static LocationTrackingService get instance =>
      _instance ??= LocationTrackingService._internal();

  LocationTrackingService._internal();

  StreamSubscription<LocationModel>? _locationSubscription;
  List<ZoneWithDetails> _nearbyZones = [];
  Zone? _currentZone;
  final ZoneService _zoneService = ZoneService();

  // Callbacks for UI updates
  Function(Zone zone)? onZoneEntered;
  Function(Zone zone)? onZoneExited;
  Function(String message)? onError;

  bool get isTracking => _locationSubscription != null;
  Zone? get currentZone => _currentZone;

  // Start continuous location tracking
  void startTracking() {
    print('🎯 Starting location tracking for zones...');

    _locationSubscription?.cancel(); // Cancel existing if any

    _locationSubscription = LocationService.getLocationStream().listen(
      (location) {
        _checkZoneProximity(location);
        _updateBackendLocation(location);
      },
      onError: (error) {
        print('❌ Location tracking error: $error');
        onError?.call('Location tracking failed: $error');
      },
    );
  }

  // Check if player entered/exited any zones
  void _checkZoneProximity(LocationModel location) async {
    for (ZoneWithDetails zoneDetails in _nearbyZones) {
      final zone = zoneDetails.zone;

      final distance = _calculateDistance(
        location.latitude,
        location.longitude,
        zone.location.latitude,
        zone.location.longitude,
      );

      final isWithinZone = distance <= zone.radiusMeters;
      final wasInZone = _currentZone?.id == zone.id;

      print(
          '📍 Zone ${zone.name}: distance=${distance.toInt()}m, radius=${zone.radiusMeters}m, within=$isWithinZone, was=$wasInZone');

      if (isWithinZone && !wasInZone) {
        // Player entered zone
        await _handleZoneEntry(zone);
      } else if (!isWithinZone && wasInZone) {
        // Player exited zone
        await _handleZoneExit(zone);
      }
    }
  }

  Future<void> _handleZoneEntry(Zone zone) async {
    try {
      print('🚪 Attempting to enter zone: ${zone.name}');

      final result = await _zoneService.enterZone(zone.id);
      _currentZone = zone;

      print('✅ Successfully entered zone: ${zone.name}');
      onZoneEntered?.call(zone);
    } catch (e) {
      print('❌ Failed to enter zone ${zone.name}: $e');
      onError?.call('Failed to enter zone: $e');
    }
  }

  Future<void> _handleZoneExit(Zone zone) async {
    try {
      print('🚪 Attempting to exit zone: ${zone.name}');

      await _zoneService.exitZone(zone.id);
      _currentZone = null;

      print('✅ Successfully exited zone: ${zone.name}');
      onZoneExited?.call(zone);
    } catch (e) {
      print('❌ Failed to exit zone ${zone.name}: $e');
      onError?.call('Failed to exit zone: $e');
    }
  }

  // Update backend with current location
  Future<void> _updateBackendLocation(LocationModel location) async {
    try {
      await _zoneService.updatePlayerLocation(location);
    } catch (e) {
      // Don't spam errors for location updates
      print('⚠️ Failed to update backend location: $e');
    }
  }

  void updateNearbyZones(List<ZoneWithDetails> zones) {
    print('📍 Updating nearby zones: ${zones.length} zones');
    _nearbyZones = zones;
  }

  void stopTracking() {
    print('⏹️ Stopping location tracking');
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _currentZone = null;
  }

  // Calculate distance between two points in meters
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // Earth's radius in meters
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a = dart_math.sin(dLat / 2) * dart_math.sin(dLat / 2) +
        dart_math.cos(_toRadians(lat1)) *
            dart_math.cos(_toRadians(lat2)) *
            dart_math.sin(dLon / 2) *
            dart_math.sin(dLon / 2);
    final double c =
        2 * dart_math.atan2(dart_math.sqrt(a), dart_math.sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (dart_math.pi / 180);
  }

  void dispose() {
    stopTracking();
    _instance = null;
  }
}
