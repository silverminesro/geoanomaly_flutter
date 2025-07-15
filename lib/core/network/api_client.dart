import 'package:dio/dio.dart';

class ApiClient {
  static late Dio _dio;
  static String? _authToken;

  static Dio get dio => _dio;

  static void initialize() {
    _dio = Dio(BaseOptions(
      baseUrl: 'http://192.168.1.134:8080/api/v1',
      connectTimeout: const Duration(seconds: 15), // ✅ Zvýšené na 15s
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add auth interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_authToken != null) {
          options.headers['Authorization'] = 'Bearer $_authToken';
          print('🔑 Using auth token: ${_authToken!.substring(0, 20)}...');
        } else {
          print('⚠️ No auth token available');
        }
        print('🌐 ${options.method} ${options.baseUrl}${options.path}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        print('✅ Response ${response.statusCode}: ${response.data}');
        handler.next(response);
      },
      onError: (error, handler) {
        print(
            '❌ API Error: ${error.response?.statusCode} - ${error.response?.data}');
        print(
            '❌ Request: ${error.requestOptions.method} ${error.requestOptions.path}');
        handler.next(error);
      },
    ));

    // Add logging interceptor
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      requestHeader: true,
      responseHeader: false,
      logPrint: (obj) => print('🌐 API: $obj'),
    ));
  }

  static void setAuthToken(String token) {
    _authToken = token;
    print('✅ Auth token set: ${token.substring(0, 20)}...');
  }

  static void clearAuthToken() {
    _authToken = null;
    print('🔓 Auth token cleared');
  }

  static String? get authToken => _authToken;

  // ✅ Helper method pre debugging
  static Future<bool> testConnection() async {
    try {
      final response = await _dio.get('/test');
      print('✅ Backend connection test: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Backend connection failed: $e');
      return false;
    }
  }
}
