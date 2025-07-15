import 'package:dio/dio.dart';

class ApiClient {
  static late Dio _dio;
  static String? _authToken;

  static Dio get dio => _dio;

  static void initialize() {
    _dio = Dio(BaseOptions(
      baseUrl: 'http://192.168.1.134:8080/api/v1', // ✅ Zmeň na tvoju IP adresu
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // Add auth interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_authToken != null) {
          options.headers['Authorization'] = 'Bearer $_authToken';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        print(
            '❌ API Error: ${error.response?.statusCode} - ${error.response?.data}');
        handler.next(error);
      },
    ));

    // Add logging interceptor
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
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
}
