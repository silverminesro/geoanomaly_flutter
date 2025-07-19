// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InventoryResponse _$InventoryResponseFromJson(Map<String, dynamic> json) =>
    InventoryResponse(
      success: json['success'] as bool,
      items: (json['items'] as List<dynamic>)
          .map((e) => InventoryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination: InventoryPagination.fromJson(
          json['pagination'] as Map<String, dynamic>),
      filter: InventoryFilter.fromJson(json['filter'] as Map<String, dynamic>),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$InventoryResponseToJson(InventoryResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'items': instance.items,
      'pagination': instance.pagination,
      'filter': instance.filter,
      'timestamp': instance.timestamp.toIso8601String(),
    };

InventoryPagination _$InventoryPaginationFromJson(Map<String, dynamic> json) =>
    InventoryPagination(
      currentPage: (json['current_page'] as num).toInt(),
      totalPages: (json['total_pages'] as num).toInt(),
      totalItems: (json['total_items'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
    );

Map<String, dynamic> _$InventoryPaginationToJson(
        InventoryPagination instance) =>
    <String, dynamic>{
      'current_page': instance.currentPage,
      'total_pages': instance.totalPages,
      'total_items': instance.totalItems,
      'limit': instance.limit,
    };

InventoryFilter _$InventoryFilterFromJson(Map<String, dynamic> json) =>
    InventoryFilter(
      itemType: json['item_type'] as String?,
    );

Map<String, dynamic> _$InventoryFilterToJson(InventoryFilter instance) =>
    <String, dynamic>{
      'item_type': instance.itemType,
    };

InventorySummaryResponse _$InventorySummaryResponseFromJson(
        Map<String, dynamic> json) =>
    InventorySummaryResponse(
      success: json['success'] as bool,
      summary:
          InventorySummary.fromJson(json['summary'] as Map<String, dynamic>),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$InventorySummaryResponseToJson(
        InventorySummaryResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'summary': instance.summary,
      'timestamp': instance.timestamp.toIso8601String(),
    };
