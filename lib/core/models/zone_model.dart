// lib/core/models/zone_model.dart
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import 'dart:math';

part 'zone_model.g.dart';

@JsonSerializable()
class Zone extends Equatable {
  final String id;
  final String name;
  final String? description;
  final Location location;

  @JsonKey(name: 'radius_meters')
  final int radiusMeters;

  @JsonKey(name: 'tier_required')
  final int tierRequired;

  @JsonKey(name: 'zone_type')
  final String zoneType;

  final String? biome;

  @JsonKey(name: 'danger_level')
  final String? dangerLevel;

  @JsonKey(name: 'is_active')
  final bool isActive;

  // ✅ NEW: TTL and cleanup fields from backend
  @JsonKey(name: 'expires_at')
  final String? expiresAt;

  @JsonKey(name: 'last_activity')
  final String? lastActivity;

  @JsonKey(name: 'auto_cleanup', defaultValue: true)
  final bool autoCleanup;

  @JsonKey(name: 'properties', defaultValue: <String, dynamic>{})
  final Map<String, dynamic> properties;

  @JsonKey(name: 'created_at')
  final String? createdAt;

  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  const Zone({
    required this.id,
    required this.name,
    this.description,
    required this.location,
    required this.radiusMeters,
    required this.tierRequired,
    required this.zoneType,
    this.biome,
    this.dangerLevel,
    required this.isActive,
    this.expiresAt,
    this.lastActivity,
    this.autoCleanup = true,
    this.properties = const <String, dynamic>{},
    this.createdAt,
    this.updatedAt,
  });

  factory Zone.fromJson(Map<String, dynamic> json) => _$ZoneFromJson(json);
  Map<String, dynamic> toJson() => _$ZoneToJson(this);

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        location,
        radiusMeters,
        tierRequired,
        zoneType,
        biome,
        dangerLevel,
        isActive,
        expiresAt,
        lastActivity,
        autoCleanup,
        properties,
        createdAt,
        updatedAt,
      ];

  // ✅ NEW: Helper methods
  bool get isDynamic => zoneType == 'dynamic';
  bool get isStatic => zoneType == 'static';
  bool get isEvent => zoneType == 'event';
  bool get isPermanent => expiresAt == null;

  String get displayBiome => biome ?? 'Unknown';
  String get displayDangerLevel => dangerLevel ?? 'Unknown';

  // ✅ NEW: Zone status helpers
  String get zoneTypeDisplayName {
    switch (zoneType) {
      case 'static':
        return 'Static Zone';
      case 'dynamic':
        return 'Dynamic Zone';
      case 'event':
        return 'Event Zone';
      default:
        return 'Unknown Zone';
    }
  }

  String get dangerLevelDisplayName {
    switch (dangerLevel) {
      case 'low':
        return 'Low Risk';
      case 'medium':
        return 'Medium Risk';
      case 'high':
        return 'High Risk';
      case 'extreme':
        return 'Extreme Risk';
      default:
        return 'Unknown Risk';
    }
  }

  // ✅ NEW: Distance calculation helper
  double distanceFromPoint(double lat, double lng) {
    return _calculateDistance(lat, lng, location.latitude, location.longitude);
  }

  bool isWithinRange(double lat, double lng) {
    final distance = distanceFromPoint(lat, lng);
    return distance <= radiusMeters;
  }

  // ✅ NEW: Copy with method
  Zone copyWith({
    String? id,
    String? name,
    String? description,
    Location? location,
    int? radiusMeters,
    int? tierRequired,
    String? zoneType,
    String? biome,
    String? dangerLevel,
    bool? isActive,
    String? expiresAt,
    String? lastActivity,
    bool? autoCleanup,
    Map<String, dynamic>? properties,
    String? createdAt,
    String? updatedAt,
  }) {
    return Zone(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      location: location ?? this.location,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      tierRequired: tierRequired ?? this.tierRequired,
      zoneType: zoneType ?? this.zoneType,
      biome: biome ?? this.biome,
      dangerLevel: dangerLevel ?? this.dangerLevel,
      isActive: isActive ?? this.isActive,
      expiresAt: expiresAt ?? this.expiresAt,
      lastActivity: lastActivity ?? this.lastActivity,
      autoCleanup: autoCleanup ?? this.autoCleanup,
      properties: properties ?? this.properties,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'Zone(id: $id, name: $name, type: $zoneType, tier: $tierRequired)';
}

@JsonSerializable()
class Location extends Equatable {
  final double latitude;
  final double longitude;

  const Location({
    required this.latitude,
    required this.longitude,
  });

  factory Location.fromJson(Map<String, dynamic> json) =>
      _$LocationFromJson(json);
  Map<String, dynamic> toJson() => _$LocationToJson(this);

  @override
  List<Object?> get props => [latitude, longitude];

  // ✅ NEW: Location helpers
  String get coordinatesString =>
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';

  double distanceTo(Location other) {
    return _calculateDistance(
        latitude, longitude, other.latitude, other.longitude);
  }

  Location copyWith({
    double? latitude,
    double? longitude,
  }) {
    return Location(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  @override
  String toString() => 'Location(lat: $latitude, lng: $longitude)';
}

// ✅ NEW: Utility functions
double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const double earthRadius = 6371000; // Earth's radius in meters

  final dLat = _toRadians(lat2 - lat1);
  final dLon = _toRadians(lon2 - lon1);

  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRadians(lat1)) *
          cos(_toRadians(lat2)) *
          sin(dLon / 2) *
          sin(dLon / 2);

  final c = 2 * atan2(sqrt(a), sqrt(1 - a));

  return earthRadius * c;
}

double _toRadians(double degrees) {
  return degrees * pi / 180;
}

// ✅ NEW: Zone with additional data for UI
@JsonSerializable()
class ZoneWithDetails extends Equatable {
  final Zone zone;
  final double? distanceFromPlayer;
  final int? artifactCount;
  final int? gearCount;
  final bool canEnter;

  @JsonKey(name: 'player_count')
  final int? playerCount;

  @JsonKey(name: 'last_visited')
  final String? lastVisited;

  const ZoneWithDetails({
    required this.zone,
    this.distanceFromPlayer,
    this.artifactCount,
    this.gearCount,
    required this.canEnter,
    this.playerCount,
    this.lastVisited,
  });

  factory ZoneWithDetails.fromJson(Map<String, dynamic> json) =>
      _$ZoneWithDetailsFromJson(json);
  Map<String, dynamic> toJson() => _$ZoneWithDetailsToJson(this);

  @override
  List<Object?> get props => [
        zone,
        distanceFromPlayer,
        artifactCount,
        gearCount,
        canEnter,
        playerCount,
        lastVisited,
      ];

  // ✅ NEW: UI helper methods
  String get distanceDisplay {
    if (distanceFromPlayer == null) return 'Unknown distance';

    final distance = distanceFromPlayer!;
    if (distance < 1000) {
      return '${distance.toInt()}m away';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)}km away';
    }
  }

  String get itemCountDisplay {
    final artifacts = artifactCount ?? 0;
    final gear = gearCount ?? 0;
    final total = artifacts + gear;

    if (total == 0) return 'No items';
    return '$total items ($artifacts artifacts, $gear gear)';
  }

  String get playerCountDisplay {
    final count = playerCount ?? 0;
    if (count == 0) return 'Empty';
    if (count == 1) return '1 player';
    return '$count players';
  }

  @override
  String toString() =>
      'ZoneWithDetails(zone: ${zone.name}, distance: $distanceFromPlayer, canEnter: $canEnter)';
}

// ✅ NEW: Scan area response model
@JsonSerializable()
class ScanAreaResponse extends Equatable {
  @JsonKey(name: 'zones_created')
  final int zonesCreated;

  final List<ZoneWithDetails> zones;

  @JsonKey(name: 'scan_area_center')
  final Location scanAreaCenter;

  @JsonKey(name: 'next_scan_available')
  final int nextScanAvailable;

  @JsonKey(name: 'max_zones')
  final int maxZones;

  @JsonKey(name: 'current_zone_count')
  final int currentZoneCount;

  @JsonKey(name: 'player_tier')
  final int playerTier;

  const ScanAreaResponse({
    required this.zonesCreated,
    required this.zones,
    required this.scanAreaCenter,
    required this.nextScanAvailable,
    required this.maxZones,
    required this.currentZoneCount,
    required this.playerTier,
  });

  factory ScanAreaResponse.fromJson(Map<String, dynamic> json) =>
      _$ScanAreaResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ScanAreaResponseToJson(this);

  @override
  List<Object?> get props => [
        zonesCreated,
        zones,
        scanAreaCenter,
        nextScanAvailable,
        maxZones,
        currentZoneCount,
        playerTier,
      ];

  @override
  String toString() =>
      'ScanAreaResponse(created: $zonesCreated, found: ${zones.length})';
}
