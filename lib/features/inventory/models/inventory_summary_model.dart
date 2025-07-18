import 'package:json_annotation/json_annotation.dart';

part 'inventory_summary_model.g.dart';

@JsonSerializable()
class InventorySummary {
  @JsonKey(name: 'total_items')
  final int totalItems;
  @JsonKey(name: 'total_artifacts')
  final int totalArtifacts;
  @JsonKey(name: 'total_gear')
  final int totalGear;
  @JsonKey(name: 'by_rarity')
  final Map<String, int> byRarity;

  InventorySummary({
    required this.totalItems,
    required this.totalArtifacts,
    required this.totalGear,
    required this.byRarity,
  });

  factory InventorySummary.fromJson(Map<String, dynamic> json) =>
      _$InventorySummaryFromJson(json);

  Map<String, dynamic> toJson() => _$InventorySummaryToJson(this);

  // Helper getters
  int get commonCount => byRarity['common'] ?? 0;
  int get rareCount => byRarity['rare'] ?? 0;
  int get epicCount => byRarity['epic'] ?? 0;
  int get legendaryCount => byRarity['legendary'] ?? 0;
}
