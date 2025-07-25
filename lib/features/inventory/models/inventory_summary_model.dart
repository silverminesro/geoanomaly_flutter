import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

// part 'inventory_summary_model.g.dart';

@JsonSerializable()
class InventorySummary extends Equatable {
  // ✅ OPRAVENÉ: Made nullable and added type conversion
  @JsonKey(name: 'total_items', defaultValue: 0)
  final int totalItems;

  @JsonKey(name: 'total_artifacts', defaultValue: 0)
  final int totalArtifacts;

  @JsonKey(name: 'total_gear', defaultValue: 0)
  final int totalGear;

  @JsonKey(name: 'total_value', defaultValue: 0)
  final int totalValue;

  // ✅ OPRAVENÉ: Made nullable for last_updated
  @JsonKey(name: 'last_updated')
  final DateTime? lastUpdated;

  // ✅ OPRAVENÉ: Made nullable with defaults for breakdown maps
  @JsonKey(name: 'rarity_breakdown', defaultValue: <String, int>{})
  final Map<String, int> rarityBreakdown;

  @JsonKey(name: 'biome_breakdown', defaultValue: <String, int>{})
  final Map<String, int> biomeBreakdown;

  const InventorySummary({
    required this.totalItems,
    required this.totalArtifacts,
    required this.totalGear,
    required this.totalValue,
    this.lastUpdated, // ✅ OPRAVENÉ: Made nullable
    required this.rarityBreakdown,
    required this.biomeBreakdown,
  });

  // ✅ KOMPLETNE NOVÝ: Custom fromJson with robust type conversion
  factory InventorySummary.fromJson(Map<String, dynamic> json) {
    try {
      // ✅ SAFE TYPE CONVERSION: Handle String/int/null values
      final totalItems = _parseIntSafely(json['total_items']) ?? 0;
      final totalArtifacts = _parseIntSafely(json['total_artifacts']) ?? 0;
      final totalGear = _parseIntSafely(json['total_gear']) ?? 0;
      final totalValue = _parseIntSafely(json['total_value']) ?? 0;

      // ✅ SAFE DATETIME PARSING
      DateTime? lastUpdated;
      if (json['last_updated'] != null) {
        try {
          if (json['last_updated'] is String) {
            lastUpdated = DateTime.parse(json['last_updated']);
          } else if (json['last_updated'] is int) {
            lastUpdated =
                DateTime.fromMillisecondsSinceEpoch(json['last_updated']);
          }
        } catch (e) {
          print('⚠️ Failed to parse last_updated: ${json['last_updated']}');
          lastUpdated = DateTime.now(); // Fallback
        }
      } else {
        lastUpdated = DateTime.now(); // Default to now if missing
      }

      // ✅ SAFE MAP PARSING for breakdowns
      final rarityBreakdown =
          _parseBreakdownMap(json['rarity_breakdown']) ?? <String, int>{};
      final biomeBreakdown =
          _parseBreakdownMap(json['biome_breakdown']) ?? <String, int>{};

      return InventorySummary(
        totalItems: totalItems,
        totalArtifacts: totalArtifacts,
        totalGear: totalGear,
        totalValue: totalValue,
        lastUpdated: lastUpdated,
        rarityBreakdown: rarityBreakdown,
        biomeBreakdown: biomeBreakdown,
      );
    } catch (e) {
      print('❌ Error parsing InventorySummary: $e');
      print('❌ Raw JSON: $json');

      // ✅ FALLBACK: Return default summary if parsing fails
      return InventorySummary(
        totalItems: 0,
        totalArtifacts: 0,
        totalGear: 0,
        totalValue: 0,
        lastUpdated: DateTime.now(),
        rarityBreakdown: <String, int>{},
        biomeBreakdown: <String, int>{},
      );
    }
  }

  // ✅ HELPER: Safe integer parsing from any type
  static int? _parseIntSafely(dynamic value) {
    if (value == null) return null;

    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;

      // Try parsing as double first, then convert to int
      final doubleValue = double.tryParse(value);
      if (doubleValue != null) return doubleValue.toInt();
    }

    print('⚠️ Could not parse int from: $value (${value.runtimeType})');
    return null;
  }

  // ✅ HELPER: Safe breakdown map parsing
  static Map<String, int>? _parseBreakdownMap(dynamic value) {
    if (value == null) return <String, int>{};

    if (value is Map) {
      final Map<String, int> result = {};

      value.forEach((key, val) {
        if (key != null) {
          final stringKey = key.toString();
          final intValue = _parseIntSafely(val) ?? 0;
          result[stringKey] = intValue;
        }
      });

      return result;
    }

    print(
        '⚠️ Could not parse breakdown map from: $value (${value.runtimeType})');
    return <String, int>{};
  }

  Map<String, dynamic> toJson() {
    return {
      'total_items': totalItems,
      'total_artifacts': totalArtifacts,
      'total_gear': totalGear,
      'total_value': totalValue,
      'last_updated': lastUpdated?.toIso8601String(),
      'rarity_breakdown': rarityBreakdown,
      'biome_breakdown': biomeBreakdown,
    };
  }

  @override
  List<Object?> get props => [
        totalItems,
        totalArtifacts,
        totalGear,
        totalValue,
        lastUpdated,
        rarityBreakdown,
        biomeBreakdown,
      ];

  // Helper getters
  double get averageValue {
    return totalItems > 0 ? totalValue / totalItems : 0.0;
  }

  String get formattedTotalValue {
    if (totalValue >= 1000000) {
      return '${(totalValue / 1000000).toStringAsFixed(1)}M';
    } else if (totalValue >= 1000) {
      return '${(totalValue / 1000).toStringAsFixed(1)}K';
    } else {
      return totalValue.toString();
    }
  }

  // Get most common rarity
  String get mostCommonRarity {
    if (rarityBreakdown.isEmpty) return 'None';

    final sortedRarities = rarityBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedRarities.first.key;
  }

  // Get most common biome
  String get mostCommonBiome {
    if (biomeBreakdown.isEmpty) return 'None';

    final sortedBiomes = biomeBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedBiomes.first.key;
  }

  // ✅ HELPER: Check if summary has data
  bool get isEmpty => totalItems == 0;
  bool get hasData => totalItems > 0;

  // ✅ HELPER: Get formatted last updated
  String get formattedLastUpdated {
    if (lastUpdated == null) return 'Never';

    final now = DateTime.now();
    final difference = now.difference(lastUpdated!);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  String toString() =>
      'InventorySummary(total: $totalItems, artifacts: $totalArtifacts, gear: $totalGear, updated: $formattedLastUpdated)';
}
