import 'package:json_annotation/json_annotation.dart';

part 'inventory_item_model.g.dart';

@JsonSerializable()
class InventoryItem {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'item_type')
  final String itemType; // 'artifact' or 'gear'
  @JsonKey(name: 'item_id')
  final String itemId;
  final int quantity;
  final Map<String, dynamic> properties;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  InventoryItem({
    required this.id,
    required this.userId,
    required this.itemType,
    required this.itemId,
    required this.quantity,
    required this.properties,
    required this.createdAt,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) =>
      _$InventoryItemFromJson(json);

  Map<String, dynamic> toJson() => _$InventoryItemToJson(this);

  // Helper getters
  String get name => properties['name'] ?? 'Unknown Item';
  String get rarity => properties['rarity'] ?? 'common';
  String get type => properties['type'] ?? itemType;
  String get biome => properties['biome'] ?? 'unknown';
  String get zoneName => properties['zone_name'] ?? 'Unknown Zone';

  // UI helpers
  bool get isArtifact => itemType == 'artifact';
  bool get isGear => itemType == 'gear';

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
        return 'Unknown';
    }
  }
}
