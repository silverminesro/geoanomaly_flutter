// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_summary_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InventorySummary _$InventorySummaryFromJson(Map<String, dynamic> json) =>
    InventorySummary(
      totalItems: (json['total_items'] as num).toInt(),
      totalArtifacts: (json['total_artifacts'] as num).toInt(),
      totalGear: (json['total_gear'] as num).toInt(),
      byRarity: Map<String, int>.from(json['by_rarity'] as Map),
    );

Map<String, dynamic> _$InventorySummaryToJson(InventorySummary instance) =>
    <String, dynamic>{
      'total_items': instance.totalItems,
      'total_artifacts': instance.totalArtifacts,
      'total_gear': instance.totalGear,
      'by_rarity': instance.byRarity,
    };
