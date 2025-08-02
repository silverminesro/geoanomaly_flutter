import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../core/models/zone_model.dart'; // Import pre Location

part 'gear_item_model.g.dart';

@JsonSerializable()
class GearItem extends Equatable {
  final String id;

  @JsonKey(name: 'zone_id')
  final String? zoneId;

  final String name;
  final String type; // helmet, shield, armor, weapon, etc.
  final int level;

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

  final String? biome;

  @JsonKey(name: 'exclusive_to_biome')
  final bool exclusiveToBiome;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  @JsonKey(name: 'deleted_at')
  final DateTime? deletedAt;

  const GearItem({
    required this.id,
    this.zoneId,
    required this.name,
    required this.type,
    required this.level,
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
    print('🔍 GEAR: Parsing properties: ${value.runtimeType} - $value');

    if (value == null) {
      print('✅ GEAR: Properties null - returning empty map');
      return <String, dynamic>{};
    }

    // If already a Map<String, dynamic>, return as-is
    if (value is Map<String, dynamic>) {
      print(
          '✅ GEAR: Properties already Map<String, dynamic> with ${value.length} keys');
      return value;
    }

    // If it's another type of Map, convert it
    if (value is Map) {
      print('✅ GEAR: Properties is Map - converting to Map<String, dynamic>');
      try {
        final converted = Map<String, dynamic>.from(value);
        print('✅ GEAR: Conversion successful with ${converted.length} keys');
        return converted;
      } catch (e) {
        print('❌ GEAR: Failed to convert Map: $e');
        return <String, dynamic>{};
      }
    }

    // If it's a String, try to parse as JSON
    if (value is String) {
      print('🔧 GEAR: Properties is String - attempting JSON parse');
      try {
        final parsed = json.decode(value);
        print('✅ GEAR: JSON parsed successfully: ${parsed.runtimeType}');

        if (parsed is Map<String, dynamic>) {
          print(
              '✅ GEAR: Parsed as Map<String, dynamic> with ${parsed.length} keys');
          return parsed;
        } else if (parsed is Map) {
          print('✅ GEAR: Parsed as Map - converting to Map<String, dynamic>');
          final converted = Map<String, dynamic>.from(parsed);
          print('✅ GEAR: Conversion successful with ${converted.length} keys');
          return converted;
        } else {
          print('❌ GEAR: Parsed JSON is not a Map: ${parsed.runtimeType}');
          return <String, dynamic>{};
        }
      } catch (e) {
        print('❌ GEAR: Failed to parse properties JSON string: $e');
        print('❌ GEAR: Raw properties value: $value');

        // Try manual extraction for name
        if (value.contains('"name"')) {
          try {
            final nameMatch = RegExp(r'"name":\s*"([^"]*)"').firstMatch(value);
            if (nameMatch != null) {
              final name = nameMatch.group(1);
              print('✅ GEAR: Manually extracted name: $name');
              return {'name': name, 'manual_parse': true};
            }
          } catch (e) {
            print('❌ GEAR: Manual extraction failed: $e');
          }
        }

        return <String, dynamic>{};
      }
    }

    print('❌ GEAR: Unexpected properties type: ${value.runtimeType}');
    return <String, dynamic>{};
  }

  // ✅ ADDED: Custom JSON stringifier for properties (for toJson)
  static dynamic _stringifyProperties(Map<String, dynamic> properties) {
    return properties;
  }

  // ✅ FIXED: Factory method from inventory item - only use existing constructor parameters
  factory GearItem.fromInventoryItem(Map<String, dynamic> json) {
    final properties = json['properties'] as Map<String, dynamic>? ?? {};

    // Store gear-specific values in properties if they exist
    final enhancedProperties = Map<String, dynamic>.from(properties);

    // Add gear stats to properties if they don't already exist
    if (!enhancedProperties.containsKey('attack') &&
        properties['attack'] != null) {
      enhancedProperties['attack'] = properties['attack'];
    }
    if (!enhancedProperties.containsKey('defense') &&
        properties['defense'] != null) {
      enhancedProperties['defense'] = properties['defense'];
    }
    if (!enhancedProperties.containsKey('durability') &&
        properties['durability'] != null) {
      enhancedProperties['durability'] = properties['durability'];
    }
    if (!enhancedProperties.containsKey('max_durability') &&
        properties['max_durability'] != null) {
      enhancedProperties['max_durability'] = properties['max_durability'];
    }
    if (!enhancedProperties.containsKey('weight') &&
        properties['weight'] != null) {
      enhancedProperties['weight'] = properties['weight'];
    }
    if (!enhancedProperties.containsKey('value') &&
        properties['value'] != null) {
      enhancedProperties['value'] = properties['value'];
    }
    if (!enhancedProperties.containsKey('description') &&
        properties['description'] != null) {
      enhancedProperties['description'] = properties['description'];
    }
    if (!enhancedProperties.containsKey('slot') && properties['slot'] != null) {
      enhancedProperties['slot'] = properties['slot'];
    }
    if (!enhancedProperties.containsKey('equipped') &&
        properties['equipped'] != null) {
      enhancedProperties['equipped'] = properties['equipped'];
    }

    return GearItem(
      id: json['item_id'] as String? ?? json['id'] as String? ?? '',
      name: properties['name'] as String? ??
          json['name'] as String? ??
          'Unknown Gear',
      type: properties['type'] as String? ?? 'unknown',
      level: properties['level'] as int? ?? 1,
      exclusiveToBiome: properties['exclusive_to_biome'] as bool? ?? false,
      isActive: properties['is_active'] as bool? ?? true,
      properties: enhancedProperties,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),

      // Optional parameters
      zoneId: properties['zone_id'] as String?,
      biome: properties['biome'] as String?,
      locationLatitude: properties['location_latitude'] as double?,
      locationLongitude: properties['location_longitude'] as double?,
      locationTimestamp: properties['location_timestamp'] != null
          ? DateTime.tryParse(properties['location_timestamp'].toString())
          : null,
      deletedAt: null,
    );
  }

  // ✅ FIXED: Standard fromJson factory
  factory GearItem.fromJson(Map<String, dynamic> json) {
    try {
      return _$GearItemFromJson(json);
    } catch (e) {
      print('❌ GEAR: Failed to parse GearItem from JSON: $e');
      print('❌ GEAR: JSON data: $json');

      // Fallback creation
      return GearItem(
        id: json['id']?.toString() ?? '',
        zoneId: json['zone_id']?.toString(),
        name: json['name']?.toString() ?? 'Unknown Gear',
        type: json['type']?.toString() ?? 'unknown',
        level: json['level'] as int? ?? 1,
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

  Map<String, dynamic> toJson() => _$GearItemToJson(this);

  @override
  List<Object?> get props => [
        id,
        zoneId,
        name,
        type,
        level,
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

  // Level helpers
  Color get levelColor {
    if (level <= 1) return Colors.grey; // Basic
    if (level <= 3) return const Color(0xFF4CAF50); // Green
    if (level <= 5) return const Color(0xFF2196F3); // Blue
    if (level <= 7) return const Color(0xFF9C27B0); // Purple
    return const Color(0xFFFF9800); // Orange - Epic/Legendary
  }

  String get levelDisplayName {
    if (level <= 1) return 'Basic';
    if (level <= 3) return 'Common';
    if (level <= 5) return 'Rare';
    if (level <= 7) return 'Epic';
    return 'Legendary';
  }

  String get levelStars {
    return '⭐' * (level.clamp(1, 5));
  }

  // Type helpers
  String get typeDisplayName {
    switch (type.toLowerCase()) {
      case 'helmet':
        return 'Helmet';
      case 'shield':
        return 'Shield';
      case 'armor':
        return 'Armor';
      case 'weapon':
        return 'Weapon';
      case 'boots':
        return 'Boots';
      case 'gloves':
        return 'Gloves';
      default:
        return type
            .split(' ')
            .map((word) =>
                word[0].toUpperCase() + word.substring(1).toLowerCase())
            .join(' ');
    }
  }

  String get typeIcon {
    switch (type.toLowerCase()) {
      case 'helmet':
        return '⛑️';
      case 'shield':
        return '🛡️';
      case 'armor':
        return '🦺';
      case 'weapon':
        return '⚔️';
      case 'boots':
        return '👢';
      case 'gloves':
        return '🧤';
      default:
        return '🔧';
    }
  }

  IconData get typeIconData {
    switch (type.toLowerCase()) {
      case 'helmet':
        return Icons.sports_motorsports;
      case 'shield':
        return Icons.shield;
      case 'armor':
        return Icons.security;
      case 'weapon':
        return Icons.gavel;
      case 'boots':
        return Icons.directions_walk;
      case 'gloves':
        return Icons.back_hand;
      default:
        return Icons.build;
    }
  }

  // Biome helpers (same as ArtifactItem)
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
        return const Color(0xFF8B4513);
      case 'rocky':
        return const Color(0xFF808080);
      case 'desert':
        return const Color(0xFFF4A460);
      case 'forest':
        return const Color(0xFF228B22);
      case 'swamp':
        return const Color(0xFF556B2F);
      case 'volcanic':
        return const Color(0xFFFF4500);
      default:
        return Colors.grey;
    }
  }

  // ✅ FIXED: Stats helpers (from properties) with type safety
  int get attack => getProperty<int>('attack') ?? 0;
  int get defense => getProperty<int>('defense') ?? 0;
  int get durability => getProperty<int>('durability') ?? 100;
  int get maxDurability => getProperty<int>('max_durability') ?? 100;
  double? get weight => getProperty<double>('weight');
  double? get value => getProperty<double>('value');
  String? get description => getProperty<String>('description');
  String? get slot => getProperty<String>('slot');
  bool get equipped => getProperty<bool>('equipped') ?? false;

  // Durability helpers
  double get durabilityPercentage {
    if (maxDurability == 0) return 1.0;
    return (durability / maxDurability).clamp(0.0, 1.0);
  }

  String get durabilityDisplay {
    return '$durability / $maxDurability';
  }

  Color get durabilityColor {
    final percentage = durabilityPercentage;
    if (percentage > 0.7) return Colors.green;
    if (percentage > 0.4) return Colors.orange;
    return Colors.red;
  }

  bool get isBroken => durability <= 0;
  bool get needsRepair => durabilityPercentage < 0.3;

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
      print('⚠️ GEAR: Failed to cast property $key to $T: $e');
      return null;
    }
  }

  // Status helpers
  bool get isDeleted => deletedAt != null;
  bool get isAvailable => isActive && !isDeleted && !isBroken;
  bool get canUse => isAvailable && durability > 0;

  // Copy with method
  GearItem copyWith({
    String? id,
    String? zoneId,
    String? name,
    String? type,
    int? level,
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
    return GearItem(
      id: id ?? this.id,
      zoneId: zoneId ?? this.zoneId,
      name: name ?? this.name,
      type: type ?? this.type,
      level: level ?? this.level,
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
    return 'GearItem(id: $id, name: $name, type: $type, level: $level, biome: $biome)';
  }
}
