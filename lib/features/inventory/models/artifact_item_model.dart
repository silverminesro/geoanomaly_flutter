import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../core/models/zone_model.dart'; // Import pre Location

part 'artifact_item_model.g.dart';

@JsonSerializable()
class ArtifactItem extends Equatable {
  final String id;

  @JsonKey(name: 'zone_id')
  final String? zoneId;

  final String name;
  final String type; // crystal, orb, scroll, tablet, rune
  final String rarity; // rare, epic, legendary

  @JsonKey(name: 'location_latitude')
  final double? locationLatitude;

  @JsonKey(name: 'location_longitude')
  final double? locationLongitude;

  @JsonKey(name: 'location_timestamp')
  final DateTime? locationTimestamp;

  // ✅ FIXED: Custom JSON converter for properties field
  @JsonKey(
      name: 'properties',
      fromJson: _parseProperties,
      toJson: _stringifyProperties)
  final Map<String, dynamic> properties;

  @JsonKey(name: 'is_active')
  final bool isActive;

  final String? biome; // wasteland, rocky, desert

  @JsonKey(name: 'exclusive_to_biome')
  final bool exclusiveToBiome;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  @JsonKey(name: 'deleted_at')
  final DateTime? deletedAt;

  const ArtifactItem({
    required this.id,
    this.zoneId,
    required this.name,
    required this.type,
    required this.rarity,
    this.locationLatitude,
    this.locationLongitude,
    this.locationTimestamp,
    required this.properties,
    required this.isActive,
    this.biome,
    required this.exclusiveToBiome,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  // ✅ ADDED: Custom JSON parser for properties (handles String or Map)
  static Map<String, dynamic> _parseProperties(dynamic value) {
    print('🔍 ARTIFACT: Parsing properties: ${value.runtimeType} - $value');

    if (value == null) {
      print('✅ ARTIFACT: Properties null - returning empty map');
      return <String, dynamic>{};
    }

    // If already a Map<String, dynamic>, return as-is
    if (value is Map<String, dynamic>) {
      print(
          '✅ ARTIFACT: Properties already Map<String, dynamic> with ${value.length} keys');
      return value;
    }

    // If it's another type of Map, convert it
    if (value is Map) {
      print(
          '✅ ARTIFACT: Properties is Map - converting to Map<String, dynamic>');
      try {
        final converted = Map<String, dynamic>.from(value);
        print(
            '✅ ARTIFACT: Conversion successful with ${converted.length} keys');
        return converted;
      } catch (e) {
        print('❌ ARTIFACT: Failed to convert Map: $e');
        return <String, dynamic>{};
      }
    }

    // If it's a String, try to parse as JSON
    if (value is String) {
      print('🔧 ARTIFACT: Properties is String - attempting JSON parse');
      try {
        final parsed = json.decode(value);
        print('✅ ARTIFACT: JSON parsed successfully: ${parsed.runtimeType}');

        if (parsed is Map<String, dynamic>) {
          print(
              '✅ ARTIFACT: Parsed as Map<String, dynamic> with ${parsed.length} keys');
          return parsed;
        } else if (parsed is Map) {
          print(
              '✅ ARTIFACT: Parsed as Map - converting to Map<String, dynamic>');
          final converted = Map<String, dynamic>.from(parsed);
          print(
              '✅ ARTIFACT: Conversion successful with ${converted.length} keys');
          return converted;
        } else {
          print('❌ ARTIFACT: Parsed JSON is not a Map: ${parsed.runtimeType}');
          return <String, dynamic>{};
        }
      } catch (e) {
        print('❌ ARTIFACT: Failed to parse properties JSON string: $e');
        print('❌ ARTIFACT: Raw properties value: $value');

        // Try manual extraction for name
        if (value.contains('"name"')) {
          try {
            final nameMatch = RegExp(r'"name":\s*"([^"]*)"').firstMatch(value);
            if (nameMatch != null) {
              final name = nameMatch.group(1);
              print('✅ ARTIFACT: Manually extracted name: $name');
              return {'name': name, 'manual_parse': true};
            }
          } catch (e) {
            print('❌ ARTIFACT: Manual extraction failed: $e');
          }
        }

        return <String, dynamic>{};
      }
    }

    print('❌ ARTIFACT: Unexpected properties type: ${value.runtimeType}');
    return <String, dynamic>{};
  }

  // ✅ ADDED: Custom JSON stringifier for properties (for toJson)
  static dynamic _stringifyProperties(Map<String, dynamic> properties) {
    return properties;
  }

  factory ArtifactItem.fromJson(Map<String, dynamic> json) {
    try {
      return _$ArtifactItemFromJson(json);
    } catch (e) {
      print('❌ ARTIFACT: Failed to parse ArtifactItem from JSON: $e');
      print('❌ ARTIFACT: JSON data: $json');

      // Fallback creation
      return ArtifactItem(
        id: json['id']?.toString() ?? '',
        zoneId: json['zone_id']?.toString(),
        name: json['name']?.toString() ?? 'Unknown Artifact',
        type: json['type']?.toString() ?? 'unknown',
        rarity: json['rarity']?.toString() ?? 'common',
        locationLatitude: json['location_latitude'] as double?,
        locationLongitude: json['location_longitude'] as double?,
        locationTimestamp: json['location_timestamp'] != null
            ? DateTime.tryParse(json['location_timestamp'].toString())
            : null,
        properties: _parseProperties(json['properties']),
        isActive: json['is_active'] as bool? ?? true,
        biome: json['biome']?.toString(),
        exclusiveToBiome: json['exclusive_to_biome'] as bool? ?? false,
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
            DateTime.now(),
        updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
            DateTime.now(),
        deletedAt: json['deleted_at'] != null
            ? DateTime.tryParse(json['deleted_at'].toString())
            : null,
      );
    }
  }

  Map<String, dynamic> toJson() => _$ArtifactItemToJson(this);

  @override
  List<Object?> get props => [
        id,
        zoneId,
        name,
        type,
        rarity,
        locationLatitude,
        locationLongitude,
        locationTimestamp,
        properties,
        isActive,
        biome,
        exclusiveToBiome,
        createdAt,
        updatedAt,
        deletedAt,
      ];

  // Discovery location helpers
  bool get hasDiscoveryLocation =>
      locationLatitude != null && locationLongitude != null;

  Location? get discoveryLocation {
    if (!hasDiscoveryLocation) return null;
    return Location(
      latitude: locationLatitude!,
      longitude: locationLongitude!,
    );
  }

  // Rarity helpers
  Color get rarityColor {
    switch (rarity.toLowerCase()) {
      case 'rare':
        return const Color(0xFF2196F3); // Blue
      case 'epic':
        return const Color(0xFF9C27B0); // Purple
      case 'legendary':
        return const Color(0xFFFF9800); // Orange
      default:
        return Colors.grey;
    }
  }

  String get rarityEmoji {
    switch (rarity.toLowerCase()) {
      case 'rare':
        return '🔵';
      case 'epic':
        return '🟣';
      case 'legendary':
        return '🟠';
      default:
        return '⚪';
    }
  }

  String get rarityDisplayName {
    switch (rarity.toLowerCase()) {
      case 'rare':
        return 'Rare';
      case 'epic':
        return 'Epic';
      case 'legendary':
        return 'Legendary';
      default:
        return 'Common';
    }
  }

  // Type helpers
  String get typeIcon {
    switch (type.toLowerCase()) {
      case 'crystal':
        return '💎';
      case 'orb':
        return '🔮';
      case 'scroll':
        return '📜';
      case 'tablet':
        return '📱';
      case 'rune':
        return 'ᚱ';
      default:
        return '❓';
    }
  }

  String get typeDisplayName {
    switch (type.toLowerCase()) {
      case 'crystal':
        return 'Crystal';
      case 'orb':
        return 'Orb';
      case 'scroll':
        return 'Scroll';
      case 'tablet':
        return 'Tablet';
      case 'rune':
        return 'Rune';
      default:
        return type.toUpperCase();
    }
  }

  // Biome helpers
  String get biomeEmoji {
    switch (biome?.toLowerCase()) {
      case 'wasteland':
        return '☠️';
      case 'rocky':
        return '🗿';
      case 'desert':
        return '🏜️';
      case 'forest':
        return '🌲';
      case 'swamp':
        return '🐸';
      case 'volcanic':
        return '🌋';
      default:
        return '🌍';
    }
  }

  String get biomeDisplayName {
    if (biome == null) return 'Unknown';
    return biome!
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  Color get biomeColor {
    switch (biome?.toLowerCase()) {
      case 'wasteland':
        return const Color(0xFF8B4513); // Dark red/brown
      case 'rocky':
        return const Color(0xFF808080); // Grey
      case 'desert':
        return const Color(0xFFF4A460); // Sandy brown
      case 'forest':
        return const Color(0xFF228B22); // Forest green
      case 'swamp':
        return const Color(0xFF556B2F); // Dark olive green
      case 'volcanic':
        return const Color(0xFFFF4500); // Orange red
      default:
        return Colors.grey;
    }
  }

  // Discovery time helpers
  String get discoveryTimeDisplay {
    if (locationTimestamp == null) return 'Unknown';

    final now = DateTime.now();
    final difference = now.difference(locationTimestamp!);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just discovered';
    }
  }

  String get discoveryDateFormatted {
    if (locationTimestamp == null) return 'Unknown';

    final date = locationTimestamp!;
    return '${date.day}.${date.month}.${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  // ✅ ENHANCED: Properties helpers with type safety
  T? getProperty<T>(String key) {
    final value = properties[key];
    if (value == null) return null;

    try {
      if (T == String) {
        return value.toString() as T;
      } else if (T == int) {
        if (value is int) return value as T;
        if (value is String) {
          final parsed = int.tryParse(value);
          return parsed as T?;
        }
      } else if (T == double) {
        if (value is double) return value as T;
        if (value is int) return value.toDouble() as T;
        if (value is String) {
          final parsed = double.tryParse(value);
          return parsed as T?;
        }
      } else if (T == bool) {
        if (value is bool) return value as T;
        if (value is String) {
          return (value.toLowerCase() == 'true') as T;
        }
      }

      return value as T?;
    } catch (e) {
      print('⚠️ ARTIFACT: Failed to cast property $key to $T: $e');
      return null;
    }
  }

  String? get description => getProperty<String>('description');
  double? get value => getProperty<double>('value');
  int? get power => getProperty<int>('power');

  // Status helpers
  bool get isDeleted => deletedAt != null;
  bool get isAvailable => isActive && !isDeleted;

  // Copy with method
  ArtifactItem copyWith({
    String? id,
    String? zoneId,
    String? name,
    String? type,
    String? rarity,
    double? locationLatitude,
    double? locationLongitude,
    DateTime? locationTimestamp,
    Map<String, dynamic>? properties,
    bool? isActive,
    String? biome,
    bool? exclusiveToBiome,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return ArtifactItem(
      id: id ?? this.id,
      zoneId: zoneId ?? this.zoneId,
      name: name ?? this.name,
      type: type ?? this.type,
      rarity: rarity ?? this.rarity,
      locationLatitude: locationLatitude ?? this.locationLatitude,
      locationLongitude: locationLongitude ?? this.locationLongitude,
      locationTimestamp: locationTimestamp ?? this.locationTimestamp,
      properties: properties ?? this.properties,
      isActive: isActive ?? this.isActive,
      biome: biome ?? this.biome,
      exclusiveToBiome: exclusiveToBiome ?? this.exclusiveToBiome,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  String toString() {
    return 'ArtifactItem(id: $id, name: $name, type: $type, rarity: $rarity, biome: $biome)';
  }
}
