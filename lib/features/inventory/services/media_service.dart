import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class MediaService {
  final ApiClient _apiClient;

  MediaService(this._apiClient);

  // Upload nového obrázka
  Future<String> uploadImage(String filePath, String itemId) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
      'item_id': itemId,
    });

    final response = await _apiClient.post('/media/upload', data: formData);

    if (response.statusCode == 200) {
      return response.data['media_id'];
    } else {
      throw Exception('Failed to upload image');
    }
  }

  // Získanie URL pre media
  Future<String> getMediaUrl(String mediaId) async {
    final response = await _apiClient.get('/media/$mediaId/url');

    if (response.statusCode == 200) {
      return response.data['url'];
    } else {
      throw Exception('Failed to get media URL');
    }
  }

  // Získanie priameho obrázka
  Future<List<int>> getMediaBytes(String mediaId) async {
    final response = await _apiClient.get(
      '/media/$mediaId',
      queryParameters: {
        'responseType': ResponseType.bytes,
      },
    );

    if (response.statusCode == 200) {
      return response.data as List<int>;
    } else {
      throw Exception('Failed to get media bytes');
    }
  }
}
