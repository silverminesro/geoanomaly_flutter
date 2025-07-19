import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/inventory_item_model.dart';
import '../models/inventory_response_model.dart';
import '../models/inventory_summary_model.dart'; // ✅ PRIDAJ

import '../services/inventory_service.dart';
import '../../../core/network/api_client.dart';

// Service provider
final inventoryServiceProvider = Provider<InventoryService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return InventoryService(apiClient);
});

// State classes
class InventoryState {
  final List<InventoryItem> items;
  final bool isLoading;
  final String? error;
  final InventoryPagination? pagination;
  final String? currentFilter;

  InventoryState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.pagination,
    this.currentFilter,
  });

  InventoryState copyWith({
    List<InventoryItem>? items,
    bool? isLoading,
    String? error,
    InventoryPagination? pagination,
    String? currentFilter,
  }) {
    return InventoryState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      pagination: pagination ?? this.pagination,
      currentFilter: currentFilter ?? this.currentFilter,
    );
  }
}

class InventorySummaryState {
  final InventorySummary? summary;
  final bool isLoading;
  final String? error;

  InventorySummaryState({
    this.summary,
    this.isLoading = false,
    this.error,
  });

  InventorySummaryState copyWith({
    InventorySummary? summary,
    bool? isLoading,
    String? error,
  }) {
    return InventorySummaryState(
      summary: summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Inventory provider
class InventoryNotifier extends StateNotifier<InventoryState> {
  final InventoryService _service;

  InventoryNotifier(this._service) : super(InventoryState());

  Future<void> loadInventory({
    int page = 1,
    int limit = 50,
    String? itemType,
    bool isRefresh = false,
  }) async {
    if (isRefresh || state.items.isEmpty) {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final response = await _service.getInventory(
        page: page,
        limit: limit,
        itemType: itemType,
      );

      List<InventoryItem> newItems;
      if (page == 1 || isRefresh) {
        newItems = response.items;
      } else {
        newItems = [...state.items, ...response.items];
      }

      state = state.copyWith(
        items: newItems,
        isLoading: false,
        pagination: response.pagination,
        currentFilter: itemType,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> deleteItem(String itemId) async {
    try {
      await _service.deleteItem(itemId);

      // Remove item from local state
      final updatedItems =
          state.items.where((item) => item.id != itemId).toList();
      state = state.copyWith(items: updatedItems);

      // Refresh to get updated pagination
      await loadInventory(isRefresh: true);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> refresh() async {
    await loadInventory(isRefresh: true, itemType: state.currentFilter);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Summary provider
class InventorySummaryNotifier extends StateNotifier<InventorySummaryState> {
  final InventoryService _service;

  InventorySummaryNotifier(this._service) : super(InventorySummaryState());

  Future<void> loadSummary() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _service.getSummary();
      state = state.copyWith(
        summary: response.summary,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

// Providers
final inventoryProvider =
    StateNotifierProvider<InventoryNotifier, InventoryState>((ref) {
  final service = ref.watch(inventoryServiceProvider);
  return InventoryNotifier(service);
});

final inventorySummaryProvider =
    StateNotifierProvider<InventorySummaryNotifier, InventorySummaryState>(
        (ref) {
  final service = ref.watch(inventoryServiceProvider);
  return InventorySummaryNotifier(service);
});
