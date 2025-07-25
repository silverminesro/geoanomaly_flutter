import 'package:dio/dio.dart';
import 'dart:convert';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/inventory_item_model.dart';
import '../models/artifact_item_model.dart';
import '../models/gear_item_model.dart';
import '../models/inventory_summary_model.dart';

class InventoryService {
  final Dio _dio = ApiClient.dio;

  // ✅ ENHANCED: Get inventory items with better error handling
  Future<List<InventoryItem>> getInventoryItems({
    String? itemType,
    int? limit,
    int? offset,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      print('🎒 Loading inventory items...');
      print('🎒 Parameters: itemType=$itemType, limit=$limit');

      final response = await _dio.get(
        ApiConstants.inventoryItems,
        queryParameters: {
          if (itemType != null) 'type': itemType,
          if (limit != null) 'limit': limit,
          if (offset != null) 'page': (offset ~/ (limit ?? 50)) + 1,
          if (sortBy != null) 'sort_by': sortBy,
          if (sortOrder != null) 'sort_order': sortOrder,
        },
      );

      print('✅ Response status: ${response.statusCode}');
      print('✅ Response data type: ${response.data.runtimeType}');

      // ✅ ENHANCED: Better response parsing
      List<dynamic> itemsData;

      if (response.data is Map) {
        final data = response.data as Map<String, dynamic>;

        if (data.containsKey('items')) {
          itemsData = data['items'] as List? ?? [];
          print('📊 Found ${itemsData.length} items in response');

          // Log pagination info if available
          if (data.containsKey('pagination')) {
            final pagination = data['pagination'];
            print('📊 Pagination: $pagination');
          }
        } else {
          print('❌ No "items" key in response: ${data.keys}');
          throw Exception('Invalid response format: missing items array');
        }
      } else if (response.data is List) {
        itemsData = response.data as List;
        print('📊 Direct array format with ${itemsData.length} items');
      } else {
        print('❌ Unexpected response format: ${response.data}');
        throw Exception('Invalid response format from server');
      }

      // ✅ ENHANCED: Parse items with detailed debug logging
      final List<InventoryItem> items = [];
      for (int i = 0; i < itemsData.length; i++) {
        try {
          final itemJson = itemsData[i] as Map<String, dynamic>;

          // ✅ DEBUG: Log properties type before parsing
          if (itemJson.containsKey('properties')) {
            final properties = itemJson['properties'];
            print('🔍 Item $i properties type: ${properties.runtimeType}');
            if (properties is String) {
              print(
                  '🔧 Item $i has String properties, will be parsed by model');
            }
          }

          final item = InventoryItem.fromJson(itemJson);
          items.add(item);

          // Log first few successful parses
          if (i < 3) {
            print('✅ Item $i parsed: ${item.name} (${item.rarity})');
          }
        } catch (parseError) {
          print('❌ Failed to parse item $i: $parseError');
          print('❌ Error type: ${parseError.runtimeType}');
          print('❌ Item data keys: ${(itemsData[i] as Map).keys}');

          // ✅ ENHANCED: Try to extract basic info even if parsing fails
          try {
            final itemMap = itemsData[i] as Map<String, dynamic>;
            print('❌ Item ID: ${itemMap['id']}');
            print('❌ Item type: ${itemMap['item_type']}');
            if (itemMap['properties'] is String) {
              print(
                  '❌ Properties (first 100 chars): ${(itemMap['properties'] as String).substring(0, 100)}...');
            }
          } catch (e) {
            print('❌ Could not extract basic item info: $e');
          }

          // Continue with other items instead of failing completely
        }
      }

      print(
          '📊 Successfully parsed ${items.length}/${itemsData.length} inventory items');

      if (items.length != itemsData.length) {
        print(
            '⚠️ ${itemsData.length - items.length} items failed to parse! Check logs above.');
      }

      return items;
    } on DioException catch (e) {
      print('❌ Inventory items DioException: ${e.response?.statusCode}');
      print('❌ Response data: ${e.response?.data}');
      print('❌ Request URL: ${e.requestOptions.uri}');

      throw Exception(_handleDioError(e, 'Failed to load inventory items'));
    } catch (e) {
      print('❌ Unexpected inventory items error: $e');
      print('❌ Error type: ${e.runtimeType}');
      throw Exception('Unexpected error occurred while loading inventory: $e');
    }
  }

  // ✅ ENHANCED: Better summary handling
  Future<InventorySummary> getInventorySummary() async {
    try {
      print('📊 Loading inventory summary from backend...');

      final response = await _dio.get(ApiConstants.inventorySummary);

      print('✅ Summary response status: ${response.statusCode}');
      print('🔍 Summary response type: ${response.data.runtimeType}');

      Map<String, dynamic> summaryData;

      // ✅ ENHANCED: Better response format handling
      if (response.data is String) {
        print('⚠️ Backend sent summary as String, parsing...');
        try {
          final Map<String, dynamic> parsedData = json.decode(response.data);
          summaryData = parsedData.containsKey('summary')
              ? parsedData['summary'] as Map<String, dynamic>
              : parsedData;
        } catch (e) {
          print('❌ Failed to parse JSON string: $e');
          summaryData = _createDefaultSummary();
        }
      } else if (response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        if (data.containsKey('summary')) {
          if (data['summary'] is String) {
            try {
              summaryData =
                  json.decode(data['summary']) as Map<String, dynamic>;
            } catch (e) {
              print('❌ Failed to parse nested JSON string: $e');
              summaryData = _createDefaultSummary();
            }
          } else {
            summaryData = data['summary'] as Map<String, dynamic>;
          }
        } else {
          summaryData = data;
        }
      } else {
        print(
            '❌ Unexpected summary response format: ${response.data.runtimeType}');
        summaryData = _createDefaultSummary();
      }

      print('🔍 Parsed summaryData keys: ${summaryData.keys}');
      return InventorySummary.fromJson(summaryData);
    } catch (e) {
      print('❌ Summary error: $e');
      print('⚠️ Returning default summary due to error');

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

  // ✅ NEW: Helper for creating default summary
  Map<String, dynamic> _createDefaultSummary() {
    return {
      'total_items': 0,
      'total_artifacts': 0,
      'total_gear': 0,
      'total_value': 0,
      'last_updated': DateTime.now().toIso8601String(),
      'rarity_breakdown': <String, int>{},
      'biome_breakdown': <String, int>{},
    };
  }

  // Get detailed artifact information
  Future<ArtifactItem> getArtifactDetails(String artifactId) async {
    try {
      print('💎 Loading artifact details: $artifactId');

      // ✅ FIXED: Use proper endpoint structure
      final response =
          await _dio.get('/api/v1/game/items/artifacts/$artifactId');

      print('✅ Artifact details response: ${response.statusCode}');

      // ✅ ENHANCED: Handle response format
      Map<String, dynamic> artifactData;
      if (response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        artifactData = data.containsKey('artifact') ? data['artifact'] : data;
      } else {
        throw Exception('Invalid artifact response format');
      }

      return ArtifactItem.fromJson(artifactData);
    } on DioException catch (e) {
      print('❌ Artifact details error: ${e.response?.data}');
      if (e.response?.statusCode == 404) {
        throw Exception('Artifact not found');
      } else if (e.response?.statusCode == 501) {
        throw Exception('Artifact details not implemented yet');
      }
      throw Exception(_handleDioError(e, 'Failed to load artifact details'));
    } catch (e) {
      print('❌ Unexpected artifact error: $e');
      throw Exception('Unexpected error occurred while loading artifact: $e');
    }
  }

  // Get detailed gear information
  Future<GearItem> getGearDetails(String gearId) async {
    try {
      print('⚔️ Loading gear details: $gearId');

      // ✅ FIXED: Use proper endpoint structure
      final response = await _dio.get('/api/v1/game/items/gear/$gearId');

      print('✅ Gear details response: ${response.statusCode}');

      // ✅ ENHANCED: Handle response format
      Map<String, dynamic> gearData;
      if (response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        gearData = data.containsKey('gear') ? data['gear'] : data;
      } else {
        throw Exception('Invalid gear response format');
      }

      return GearItem.fromJson(gearData);
    } on DioException catch (e) {
      print('❌ Gear details error: ${e.response?.data}');
      if (e.response?.statusCode == 404) {
        throw Exception('Gear not found');
      } else if (e.response?.statusCode == 501) {
        throw Exception('Gear details not implemented yet');
      }
      throw Exception(_handleDioError(e, 'Failed to load gear details'));
    } catch (e) {
      print('❌ Unexpected gear error: $e');
      throw Exception('Unexpected error occurred while loading gear: $e');
    }
  }

  // Remove item from inventory
  Future<void> removeItem(String inventoryItemId) async {
    try {
      print('🗑️ Removing inventory item: $inventoryItemId');

      final response =
          await _dio.delete('${ApiConstants.inventoryItems}/$inventoryItemId');

      print('✅ Item removed successfully: ${response.statusCode}');
    } on DioException catch (e) {
      print('❌ Remove item error: ${e.response?.data}');
      if (e.response?.statusCode == 404) {
        throw Exception('Item not found in inventory');
      } else if (e.response?.statusCode == 403) {
        throw Exception('You cannot remove this item');
      } else if (e.response?.statusCode == 501) {
        throw Exception('Item removal not implemented yet');
      }
      throw Exception(_handleDioError(e, 'Failed to remove item'));
    } catch (e) {
      print('❌ Unexpected remove error: $e');
      throw Exception('Unexpected error occurred while removing item: $e');
    }
  }

  // Use item (for consumables or usable items)
  Future<Map<String, dynamic>> useItem(String inventoryItemId) async {
    try {
      print('🎯 Using inventory item: $inventoryItemId');

      final response = await _dio
          .post('${ApiConstants.inventoryItems}/$inventoryItemId/use');

      print('✅ Item used successfully: ${response.statusCode}');

      // ✅ ENHANCED: Handle different response formats
      if (response.data is Map) {
        return response.data as Map<String, dynamic>;
      } else {
        return {'success': true, 'message': 'Item used successfully'};
      }
    } on DioException catch (e) {
      print('❌ Use item error: ${e.response?.data}');
      if (e.response?.statusCode == 404) {
        throw Exception('Item not found in inventory');
      } else if (e.response?.statusCode == 403) {
        throw Exception('This item cannot be used');
      } else if (e.response?.statusCode == 409) {
        throw Exception('Item is on cooldown or already used');
      } else if (e.response?.statusCode == 501) {
        throw Exception('Item usage not implemented yet');
      }
      throw Exception(_handleDioError(e, 'Failed to use item'));
    } catch (e) {
      print('❌ Unexpected use error: $e');
      throw Exception('Unexpected error occurred while using item: $e');
    }
  }

  // Toggle favorite status
  Future<void> toggleFavorite(String inventoryItemId, bool favorite) async {
    try {
      print('⭐ Toggling favorite for item: $inventoryItemId to $favorite');

      final response = await _dio.put(
        '${ApiConstants.inventoryItems}/$inventoryItemId/favorite',
        data: {'favorite': favorite},
      );

      print('✅ Favorite toggled successfully: ${response.statusCode}');
    } on DioException catch (e) {
      print('❌ Toggle favorite error: ${e.response?.data}');
      if (e.response?.statusCode == 404) {
        throw Exception('Item not found in inventory');
      } else if (e.response?.statusCode == 501) {
        throw Exception('Favorite feature not implemented yet');
      }
      throw Exception(_handleDioError(e, 'Failed to update favorite status'));
    } catch (e) {
      print('❌ Unexpected favorite error: $e');
      throw Exception('Unexpected error occurred while updating favorite: $e');
    }
  }

  // Batch operations
  Future<List<InventoryItem>> getArtifactsOnly() async {
    return getInventoryItems(itemType: 'artifact');
  }

  Future<List<InventoryItem>> getGearOnly() async {
    return getInventoryItems(itemType: 'gear');
  }

  // ✅ ENHANCED: Search functionality with better endpoint handling
  Future<List<InventoryItem>> searchItems({
    String? query,
    String? itemType,
    String? rarity,
    String? biome,
    int? minLevel,
    int? maxLevel,
  }) async {
    try {
      print('🔍 Searching inventory items...');

      // ✅ Try search endpoint first, fallback to filtering
      try {
        final response = await _dio.get(
          '/api/v1/inventory/search',
          queryParameters: {
            if (query != null) 'q': query,
            if (itemType != null) 'type': itemType,
            if (rarity != null) 'rarity': rarity,
            if (biome != null) 'biome': biome,
            if (minLevel != null) 'min_level': minLevel,
            if (maxLevel != null) 'max_level': maxLevel,
          },
        );

        List<dynamic> itemsData;
        if (response.data is List) {
          itemsData = response.data as List;
        } else if (response.data is Map && response.data.containsKey('items')) {
          itemsData = response.data['items'] as List? ?? [];
        } else {
          itemsData = [];
        }

        final items =
            itemsData.map((item) => InventoryItem.fromJson(item)).toList();
        print('✅ Search found ${items.length} items');
        return items;
      } catch (searchError) {
        print('⚠️ Search endpoint failed, using basic filtering: $searchError');
        return getInventoryItems(itemType: itemType);
      }
    } catch (e) {
      print('❌ Unexpected search error: $e');
      throw Exception('Unexpected error occurred while searching: $e');
    }
  }

  // Get items by biome
  Future<List<InventoryItem>> getItemsByBiome(String biome) async {
    return searchItems(biome: biome);
  }

  // Get items by rarity
  Future<List<InventoryItem>> getItemsByRarity(String rarity) async {
    return searchItems(rarity: rarity);
  }

  // ✅ ENHANCED: Better error handling
  String _handleDioError(DioException e, String defaultMessage) {
    switch (e.response?.statusCode) {
      case 401:
        return 'Authentication required. Please login again.';
      case 403:
        return 'Access forbidden. Check your permissions.';
      case 404:
        return 'Resource not found.';
      case 429:
        return 'Too many requests. Please wait before trying again.';
      case 500:
        return 'Server error. Please try again later.';
      case 501:
        return 'Feature not implemented yet.';
      case 502:
        return 'Bad gateway. Server is temporarily unavailable.';
      case 503:
        return 'Service unavailable. Please try again later.';
      default:
        break;
    }

    // Check for error message in response
    if (e.response?.data != null && e.response?.data is Map) {
      final data = e.response!.data as Map<String, dynamic>;
      if (data.containsKey('error')) {
        return data['error'].toString();
      } else if (data.containsKey('message')) {
        return data['message'].toString();
      }
    }

    // Handle connection errors
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Check your internet connection.';
      case DioExceptionType.receiveTimeout:
        return 'Request timeout. Please try again.';
      case DioExceptionType.sendTimeout:
        return 'Upload timeout. Please try again.';
      case DioExceptionType.connectionError:
        return 'Connection error. Check your internet connection.';
      default:
        break;
    }

    return defaultMessage;
  }

  // Debug and utility methods
  Future<bool> testConnection() async {
    try {
      final response = await _dio.get('${ApiConstants.inventoryItems}?limit=1');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Inventory service connection test failed: $e');
      return false;
    }
  }

  Future<List<InventoryItem>> getAllItems() async {
    return getInventoryItems(limit: 100);
  }

  Future<List<InventoryItem>> refreshInventory() async {
    try {
      print('🔄 Refreshing inventory...');
      return await getInventoryItems(limit: 100);
    } catch (e) {
      print('❌ Failed to refresh inventory: $e');
      rethrow;
    }
  }

  // ✅ ENHANCED: Test endpoints
  Future<void> testRealSummary() async {
    try {
      print('🧪 Testing real summary endpoint...');
      final response = await _dio.get(ApiConstants.inventorySummary);
      print('✅ Real summary response status: ${response.statusCode}');
      print('✅ Real summary response: ${response.data}');
    } catch (e) {
      print('❌ Real summary failed: $e');
    }
  }

  Future<void> testInventoryParsing() async {
    try {
      print('🧪 Testing inventory parsing...');
      final items = await getInventoryItems(limit: 5);
      print('✅ Successfully parsed ${items.length} items for testing');

      for (int i = 0; i < items.length && i < 3; i++) {
        final item = items[i];
        print(
            '✅ Test item $i: ${item.name} (${item.rarity}) - properties: ${item.properties.length} keys');
      }
    } catch (e) {
      print('❌ Inventory parsing test failed: $e');
    }
  }
}
