import 'location_model.dart';

class Zone {
  final String id;
  final String name;
  final String description;
  final LocationModel location;
  final int radiusMeters;
  final int tierRequired;
  final String zoneType;
  final String biome;
  final String dangerLevel;
  final bool isActive;
  final DateTime? expiresAt;
  final Map<String, dynamic> properties;

  Zone({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.radiusMeters,
    required this.tierRequired,
    required this.zoneType,
    required this.biome,
    required this.dangerLevel,
    required this.isActive,
    this.expiresAt,
    this.properties = const {},
  });

  factory Zone.fromJson(Map<String, dynamic> json) {
    return Zone(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      location: LocationModel.fromJson(json['location'] ?? {}),
      radiusMeters: json['radius_meters'] ?? 100,
      tierRequired: json['tier_required'] ?? 0,
      zoneType: json['zone_type'] ?? 'static',
      biome: json['biome'] ?? 'forest',
      dangerLevel: json['danger_level'] ?? 'low',
      isActive: json['is_active'] ?? true,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
      properties: json['properties'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'location': location.toJson(),
      'radius_meters': radiusMeters,
      'tier_required': tierRequired,
      'zone_type': zoneType,
      'biome': biome,
      'danger_level': dangerLevel,
      'is_active': isActive,
      'expires_at': expiresAt?.toIso8601String(),
      'properties': properties,
    };
  }

  String get tierName {
    switch (tierRequired) {
      case 0:
        return 'Free';
      case 1:
        return 'Basic';
      case 2:
        return 'Standard';
      case 3:
        return 'Premium';
      case 4:
        return 'Elite';
      default:
        return 'Unknown';
    }
  }

  String get dangerLevelEmoji {
    switch (dangerLevel) {
      case 'low':
        return '🟢';
      case 'medium':
        return '🟡';
      case 'high':
        return '🟠';
      case 'extreme':
        return '🔴';
      default:
        return '⚪';
    }
  }

  String get biomeEmoji {
    switch (biome) {
      case 'forest':
        return '🌲';
      case 'swamp':
        return '🐸';
      case 'desert':
        return '🏜️';
      case 'mountain':
        return '⛰️';
      case 'wasteland':
        return '☠️';
      case 'volcanic':
        return '🌋';
      default:
        return '🌍';
    }
  }
}
