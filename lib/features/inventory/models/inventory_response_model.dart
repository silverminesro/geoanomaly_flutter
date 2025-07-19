import 'package:json_annotation/json_annotation.dart';
import 'inventory_item_model.dart';
import 'inventory_summary_model.dart';

part 'inventory_response_model.g.dart';

@JsonSerializable()
class InventoryResponse {
  final bool success;
  final List<InventoryItem> items;
  final InventoryPagination pagination;
  final InventoryFilter filter;
  final DateTime timestamp;

  InventoryResponse({
    required this.success,
    required this.items,
    required this.pagination,
    required this.filter,
    required this.timestamp,
  });

  factory InventoryResponse.fromJson(Map<String, dynamic> json) =>
      _$InventoryResponseFromJson(json);

  Map<String, dynamic> toJson() => _$InventoryResponseToJson(this);
}

@JsonSerializable()
class InventoryPagination {
  @JsonKey(name: 'current_page')
  final int currentPage;
  @JsonKey(name: 'total_pages')
  final int totalPages;
  @JsonKey(name: 'total_items')
  final int totalItems;
  final int limit;

  InventoryPagination({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.limit,
  });

  factory InventoryPagination.fromJson(Map<String, dynamic> json) =>
      _$InventoryPaginationFromJson(json);

  Map<String, dynamic> toJson() => _$InventoryPaginationToJson(this);

  bool get hasNextPage => currentPage < totalPages;
  bool get hasPreviousPage => currentPage > 1;
}

@JsonSerializable()
class InventoryFilter {
  @JsonKey(name: 'item_type')
  final String? itemType;

  InventoryFilter({this.itemType});

  factory InventoryFilter.fromJson(Map<String, dynamic> json) =>
      _$InventoryFilterFromJson(json);

  Map<String, dynamic> toJson() => _$InventoryFilterToJson(this);
}

@JsonSerializable()
class InventorySummaryResponse {
  final bool success;
  final InventorySummary summary;
  final DateTime timestamp;

  InventorySummaryResponse({
    required this.success,
    required this.summary,
    required this.timestamp,
  });

  factory InventorySummaryResponse.fromJson(Map<String, dynamic> json) =>
      _$InventorySummaryResponseFromJson(json);

  Map<String, dynamic> toJson() => _$InventorySummaryResponseToJson(this);
}
