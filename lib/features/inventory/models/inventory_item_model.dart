import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import '../../map/models/location_model.dart';

part 'inventory_item_model.g.dart';

@JsonSerializable()
class InventoryItem extends Equatable {
  final String id;

  @JsonKey(name: 'item_id')
  final String itemId;

  @JsonKey(name: 'item_type')
  final String itemType;

  final int quantity;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  @JsonKey(name: 'user_id')
  final String? userId;

  // ✅ FIXED: Custom JSON converter for properties field
  @JsonKey(
      name: 'properties',
      fromJson: _parseProperties,
      toJson: _stringifyProperties)
  final Map<String, dynamic> properties;

  @JsonKey(name: 'discovery_location')
  final LocationModel? discoveryLocation;

  @JsonKey(name: 'location_timestamp')
  final DateTime? locationTimestamp;

  @JsonKey(name: 'is_favorite', defaultValue: false)
  final bool isFavorite;

  const InventoryItem({
    required this.id,
    required this.itemId,
    required this.itemType,
    required this.quantity,
    required this.createdAt,
    this.updatedAt,
    this.userId,
    this.properties = const <String, dynamic>{},
    this.discoveryLocation,
    this.locationTimestamp,
    this.isFavorite = false,
  });

  // ✅ FIXED: Enhanced JSON parser with detailed debug logging
  static Map<String, dynamic> _parseProperties(dynamic value) {
    print('🔍 PARSING PROPERTIES: ${value.runtimeType} - $value');

    if (value == null) {
      print('✅ Properties null - returning empty map');
      return <String, dynamic>{};
    }

    // If already a Map<String, dynamic>, return as-is
    if (value is Map<String, dynamic>) {
      print(
          '✅ Properties already Map<String, dynamic> with ${value.length} keys');
      print('✅ Keys: ${value.keys.toList()}');
      return value;
    }

    // If it's another type of Map, convert it
    if (value is Map) {
      print('✅ Properties is Map - converting to Map<String, dynamic>');
      try {
        final converted = Map<String, dynamic>.from(value);
        print('✅ Conversion successful with ${converted.length} keys');
        print('✅ Keys: ${converted.keys.toList()}');
        return converted;
      } catch (e) {
        print('❌ Failed to convert Map: $e');
        return <String, dynamic>{};
      }
    }

    // If it's a String, try to parse as JSON
    if (value is String) {
      print('🔧 Properties is String - attempting JSON parse');
      print('🔧 String length: ${value.length}');
      print(
          '🔧 First 100 chars: ${value.length > 100 ? value.substring(0, 100) + "..." : value}');

      try {
        final parsed = json.decode(value);
        print('✅ JSON parsed successfully: ${parsed.runtimeType}');

        if (parsed is Map<String, dynamic>) {
          print('✅ Parsed as Map<String, dynamic> with ${parsed.length} keys');
          print('✅ Keys: ${parsed.keys.toList()}');
          if (parsed.containsKey('name')) {
            print('✅ Found name: ${parsed['name']}');
          }
          return parsed;
        } else if (parsed is Map) {
          print('✅ Parsed as Map - converting to Map<String, dynamic>');
          try {
            final converted = Map<String, dynamic>.from(parsed);
            print('✅ Conversion successful with ${converted.length} keys');
            print('✅ Keys: ${converted.keys.toList()}');
            return converted;
          } catch (e) {
            print('❌ Failed to convert parsed Map: $e');
            return <String, dynamic>{};
          }
        } else {
          print('❌ Parsed JSON is not a Map: ${parsed.runtimeType} - $parsed');
          return <String, dynamic>{};
        }
      } catch (e) {
        print('❌ Failed to parse properties JSON string: $e');
        print('❌ Raw properties value: $value');

        // Try to extract basic info manually if JSON parse fails
        if (value.contains('"name"')) {
          print('🔧 Attempting manual name extraction...');
          try {
            final nameMatch = RegExp(r'"name":\s*"([^"]*)"').firstMatch(value);
            if (nameMatch != null) {
              final name = nameMatch.group(1);
              print('✅ Manually extracted name: $name');
              return {'name': name, 'manual_parse': true};
            }
          } catch (e) {
            print('❌ Manual extraction failed: $e');
          }
        }

        return <String, dynamic>{};
      }
    }

    print('❌ Unexpected properties type: ${value.runtimeType}');
    print('❌ Value: $value');
    return <String, dynamic>{};
  }

  // ✅ ADDED: Custom JSON stringifier for properties (for toJson)
  static dynamic _stringifyProperties(Map<String, dynamic> properties) {
    return properties;
  }

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    print('🔧 InventoryItem.fromJson called');
    print('🔧 JSON keys: ${json.keys.toList()}');

    try {
      final result = _$InventoryItemFromJson(json);
      print('✅ InventoryItem created successfully: ${result.name}');
      return result;
    } catch (e) {
      print('❌ Failed to parse InventoryItem from JSON: $e');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ JSON data: $json');

      // ✅ ENHANCED FALLBACK: Create basic item if parsing fails
      try {
        print('🔧 Attempting fallback parsing...');

        final fallbackProperties = _parseProperties(json['properties']);
        print('🔧 Fallback properties: $fallbackProperties');

        final item = InventoryItem(
          id: json['id']?.toString() ?? '',
          itemId: json['item_id']?.toString() ?? '',
          itemType: json['item_type']?.toString() ?? 'unknown',
          quantity: json['quantity'] as int? ?? 1,
          createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
              DateTime.now(),
          updatedAt: json['updated_at'] != null
              ? DateTime.tryParse(json['updated_at'].toString())
              : null,
          userId: json['user_id']?.toString(),
          properties: fallbackProperties,
          isFavorite: json['is_favorite'] as bool? ?? false,
        );

        print('✅ Fallback item created: ${item.name}');
        return item;
      } catch (fallbackError) {
        print('❌ Fallback parsing also failed: $fallbackError');

        // Last resort: create minimal item
        return InventoryItem(
          id: json['id']?.toString() ?? 'unknown',
          itemId: json['item_id']?.toString() ?? 'unknown',
          itemType: json['item_type']?.toString() ?? 'unknown',
          quantity: 1,
          createdAt: DateTime.now(),
          properties: {'name': 'Unknown Item', 'parsing_failed': true},
        );
      }
    }
  }

  Map<String, dynamic> toJson() => _$InventoryItemToJson(this);

  // ✅ ENHANCED: Safer computed getters with detailed debug logging
  String get name {
    print('🔍 Getting name from properties: ${properties.keys.toList()}');

    final nameValue = properties['name'];
    if (nameValue != null) {
      print('✅ Found name in properties: $nameValue');
      return nameValue.toString();
    }

    print('⚠️ No name found in properties, attempting fallback...');

    // Fallback: try to construct name from type and level/rarity
    final type = properties['type']?.toString();
    final level = properties['level']?.toString();
    final rarity = properties['rarity']?.toString();

    print('🔧 Fallback values - type: $type, level: $level, rarity: $rarity');

    if (type != null) {
      if (level != null && itemType == 'gear') {
        final fallbackName = '${type.capitalize()} +$level';
        print('✅ Generated gear name: $fallbackName');
        return fallbackName;
      } else if (rarity != null && itemType == 'artifact') {
        final fallbackName = '${rarity.capitalize()} $type';
        print('✅ Generated artifact name: $fallbackName');
        return fallbackName;
      } else {
        final fallbackName = type.capitalize();
        print('✅ Generated basic name: $fallbackName');
        return fallbackName;
      }
    }

    final defaultName = 'Unknown ${itemType.capitalize()}';
    print('⚠️ Using default name: $defaultName');
    return defaultName;
  }

  String get rarity {
    final rarityValue = properties['rarity'];
    if (rarityValue != null) {
      return rarityValue.toString().toLowerCase();
    }

    // Fallback for gear: use level as rarity indicator
    if (itemType == 'gear') {
      final level = properties['level'];
      if (level != null) {
        final levelInt = int.tryParse(level.toString()) ?? 1;
        if (levelInt >= 8) return 'legendary';
        if (levelInt >= 6) return 'epic';
        if (levelInt >= 4) return 'rare';
        return 'common';
      }
    }

    return 'common';
  }

  DateTime get acquiredAt {
    // Try collected_at first, then fall back to created_at
    final collectedAt = properties['collected_at'];
    if (collectedAt != null) {
      if (collectedAt is int) {
        // Unix timestamp
        return DateTime.fromMillisecondsSinceEpoch(collectedAt * 1000);
      } else if (collectedAt is String) {
        final parsed = DateTime.tryParse(collectedAt);
        if (parsed != null) return parsed;
      }
    }

    return createdAt;
  }

  // ✅ ENHANCED: Better property access with type safety
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
      print('⚠️ Failed to cast property $key to $T: $e');
      return null;
    }
  }

  @override
  List<Object?> get props => [
        id,
        itemId,
        itemType,
        quantity,
        createdAt,
        updatedAt,
        userId,
        properties,
        discoveryLocation,
        locationTimestamp,
        isFavorite,
      ];

  // Helper getters
  bool get isArtifact => itemType.toLowerCase() == 'artifact';
  bool get isGear => itemType.toLowerCase() == 'gear';

  String get displayName => name;

  String get displayRarity {
    switch (rarity.toLowerCase()) {
      case 'common':
        return 'Common';
      case 'rare':
        return 'Rare';
      case 'epic':
        return 'Epic';
      case 'legendary':
        return 'Legendary';
      default:
        if (rarity.startsWith('level_')) {
          final level = rarity.substring(6);
          return 'Level $level';
        }
        return rarity.capitalize();
    }
  }

  String get timeSinceAcquired {
    final now = DateTime.now();
    final difference = now.difference(acquiredAt);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return '1 day ago';
      } else if (difference.inDays < 30) {
        return '${difference.inDays} days ago';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return months == 1 ? '1 month ago' : '$months months ago';
      } else {
        final years = (difference.inDays / 365).floor();
        return years == 1 ? '1 year ago' : '$years years ago';
      }
    } else if (difference.inHours > 0) {
      return difference.inHours == 1
          ? '1 hour ago'
          : '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return difference.inMinutes == 1
          ? '1 minute ago'
          : '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  String get acquiredDateFormatted {
    return '${acquiredAt.day}/${acquiredAt.month}/${acquiredAt.year}';
  }

  String get acquiredTimeFormatted {
    return '${acquiredAt.hour.toString().padLeft(2, '0')}:${acquiredAt.minute.toString().padLeft(2, '0')}';
  }

  String get acquiredDateTimeFormatted {
    return '$acquiredDateFormatted at $acquiredTimeFormatted';
  }

  String get biomeEmoji {
    final biome = getProperty<String>('biome')?.toLowerCase();
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
      case 'frozen':
        return '❄️';
      case 'abyss':
        return '🕳️';
      default:
        return '🌍';
    }
  }

  String get biomeDisplayName {
    final biome = getProperty<String>('biome');
    if (biome == null) return 'Unknown';
    return biome.capitalize();
  }

  bool get hasDiscoveryLocation => discoveryLocation != null;

  bool hasProperty(String key) {
    return properties.containsKey(key) && properties[key] != null;
  }

  String get typeDisplayName {
    switch (itemType.toLowerCase()) {
      case 'artifact':
        return 'Artifact';
      case 'gear':
        return 'Equipment';
      default:
        return itemType.capitalize();
    }
  }

  // ✅ ENHANCED: Get level for gear items
  int get level {
    if (!isGear) return 1;
    final levelValue = getProperty<int>('level');
    return levelValue ?? 1;
  }

  // ✅ ENHANCED: Get zone information
  String get zoneName {
    return getProperty<String>('zone_name') ?? 'Unknown Zone';
  }

  String get zoneBiome {
    return getProperty<String>('zone_biome') ??
        getProperty<String>('biome') ??
        'unknown';
  }

  String get dangerLevel {
    final danger = getProperty<String>('danger_level');
    if (danger == null) return 'unknown';
    return danger.capitalize();
  }

  // ✅ ENHANCED: Rarity color for UI
  String get rarityColor {
    switch (rarity.toLowerCase()) {
      case 'common':
        return '#9E9E9E'; // Gray
      case 'rare':
        return '#2196F3'; // Blue
      case 'epic':
        return '#9C27B0'; // Purple
      case 'legendary':
        return '#FF9800'; // Orange
      default:
        return '#9E9E9E';
    }
  }

  // Copy with method
  InventoryItem copyWith({
    String? id,
    String? itemId,
    String? itemType,
    int? quantity,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
    Map<String, dynamic>? properties,
    LocationModel? discoveryLocation,
    DateTime? locationTimestamp,
    bool? isFavorite,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      itemType: itemType ?? this.itemType,
      quantity: quantity ?? this.quantity,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      properties: properties ?? this.properties,
      discoveryLocation: discoveryLocation ?? this.discoveryLocation,
      locationTimestamp: locationTimestamp ?? this.locationTimestamp,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  @override
  String toString() =>
      'InventoryItem(id: $id, name: $name, type: $itemType, rarity: $rarity, biome: ${getProperty<String>('biome')})';
}

// ✅ ADDED: String extension for capitalize
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }
}
