import 'zone_model.dart';
import 'location_model.dart';

class ScanResultModel {
  final int zonesCreated;
  final List<Zone> zones;
  final LocationModel scanAreaCenter;
  final int nextScanAvailable;
  final int maxZones;
  final int currentZoneCount;
  final int playerTier;

  ScanResultModel({
    required this.zonesCreated,
    required this.zones,
    required this.scanAreaCenter,
    required this.nextScanAvailable,
    required this.maxZones,
    required this.currentZoneCount,
    required this.playerTier,
  });

  factory ScanResultModel.fromJson(Map<String, dynamic> json) {
    return ScanResultModel(
      zonesCreated: json['zones_created'] ?? 0,
      zones: (json['zones'] as List? ?? [])
          .map((zone) => Zone.fromJson(zone))
          .toList(),
      scanAreaCenter: LocationModel.fromJson(json['scan_area_center'] ?? {}),
      nextScanAvailable: json['next_scan_available'] ?? 0,
      maxZones: json['max_zones'] ?? 0,
      currentZoneCount: json['current_zone_count'] ?? 0,
      playerTier: json['player_tier'] ?? 0,
    );
  }

  bool get canScanAgain {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return now >= nextScanAvailable;
  }

  Duration get cooldownRemaining {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final remaining = nextScanAvailable - now;
    return Duration(seconds: remaining > 0 ? remaining : 0);
  }
}
