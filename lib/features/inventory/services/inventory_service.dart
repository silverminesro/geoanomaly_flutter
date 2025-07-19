import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../models/inventory_item_model.dart';
import '../models/inventory_response_model.dart';

class InventoryService {
  final ApiClient _apiClient;

  InventoryService(this._apiClient);

  // GET /api/v1/inventory/items
  Future<InventoryResponse> getInventory({
    int page = 1,
    int limit = 50,
    String? itemType,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'page': page,
        'limit': limit,
      };

      if (itemType != null && itemType.isNotEmpty) {
        queryParams['type'] = itemType;
      }

      final response = await _apiClient.get(
        '/inventory/items',
        queryParameters: queryParams,
      );

      return InventoryResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Failed to load inventory: $e');
    }
  }

  // GET /api/v1/inventory/summary
  Future<InventorySummaryResponse> getSummary() async {
    try {
      final response = await _apiClient.get('/inventory/summary');
      return InventorySummaryResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Failed to load inventory summary: $e');
    }
  }

  // DELETE /api/v1/inventory/:id
  Future<void> deleteItem(String itemId) async {
    try {
      await _apiClient.delete('/inventory/$itemId');
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Failed to delete item: $e');
    }
  }

  // GET /api/v1/inventory/items?type=artifact
  Future<InventoryResponse> getArtifacts({
    int page = 1,
    int limit = 50,
  }) async {
    return getInventory(page: page, limit: limit, itemType: 'artifact');
  }

  // GET /api/v1/inventory/items?type=gear
  Future<InventoryResponse> getGear({
    int page = 1,
    int limit = 50,
  }) async {
    return getInventory(page: page, limit: limit, itemType: 'gear');
  }

  Exception _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return Exception('Connection timeout');
      case DioExceptionType.sendTimeout:
        return Exception('Send timeout');
      case DioExceptionType.receiveTimeout:
        return Exception('Receive timeout');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data['error'] ?? 'Server error';
        return Exception('HTTP $statusCode: $message');
      case DioExceptionType.cancel:
        return Exception('Request cancelled');
      case DioExceptionType.unknown:
        return Exception('Network error: ${e.message}');
      default:
        return Exception('Unknown error: ${e.message}');
    }
  }
}
