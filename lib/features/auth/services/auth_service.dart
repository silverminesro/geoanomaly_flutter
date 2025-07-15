import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../models/auth_models.dart';

class AuthService {
  final Dio _dio = ApiClient.dio;

  // ✅ Login - simplified for direct API communication
  Future<AuthResponse> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'username': username,
          'password': password,
        },
      );

      print('✅ Login response: ${response.data}');

      final user = User.fromJson(response.data['user']);
      final token = response.data['token'];

      // Save token to API client
      ApiClient.setAuthToken(token);

      return AuthResponse(user: user, token: token);
    } on DioException catch (e) {
      print('❌ Login error: ${e.response?.data}');
      throw Exception(_handleDioError(e, 'Login failed'));
    } catch (e) {
      print('❌ Unexpected login error: $e');
      throw Exception('Unexpected error occurred during login');
    }
  }

  // ✅ Register - simplified for direct API communication
  Future<AuthResponse> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {
          'username': username,
          'email': email,
          'password': password,
        },
      );

      print('✅ Register response: ${response.data}');

      final user = User.fromJson(response.data['user']);
      final token = response.data['token'];

      // Save token to API client
      ApiClient.setAuthToken(token);

      return AuthResponse(user: user, token: token);
    } on DioException catch (e) {
      print('❌ Register error: ${e.response?.data}');
      throw Exception(_handleDioError(e, 'Registration failed'));
    } catch (e) {
      print('❌ Unexpected register error: $e');
      throw Exception('Unexpected error occurred during registration');
    }
  }

  // ✅ Get Profile
  Future<User> getProfile() async {
    try {
      final response = await _dio.get('/user/profile');

      print('✅ Profile response: ${response.data}');

      // Handle both direct user object and wrapped response
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data.containsKey('user')) {
          return User.fromJson(data['user']);
        } else {
          return User.fromJson(data);
        }
      }

      throw Exception('Invalid response format');
    } on DioException catch (e) {
      print('❌ Profile error: ${e.response?.data}');

      if (e.response?.statusCode == 401) {
        ApiClient.clearAuthToken();
        throw Exception('Session expired');
      }

      throw Exception(_handleDioError(e, 'Failed to get profile'));
    } catch (e) {
      print('❌ Unexpected profile error: $e');
      throw Exception('Unexpected error occurred while getting profile');
    }
  }

  // ✅ Logout
  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (e) {
      print('❌ Logout error: $e');
      // Continue with logout even if server call fails
    } finally {
      // Clear token from API client
      ApiClient.clearAuthToken();
    }
  }

  // ✅ Validate token
  Future<bool> validateToken() async {
    try {
      if (ApiClient.authToken == null) return false;

      // Try to get profile to validate token
      await getProfile();
      return true;
    } catch (e) {
      // Token is invalid, clear it
      ApiClient.clearAuthToken();
      return false;
    }
  }

  // ✅ Handle Dio errors
  String _handleDioError(DioException e, String defaultMessage) {
    switch (e.response?.statusCode) {
      case 401:
        return 'Invalid credentials or session expired';
      case 409:
        final errorData = e.response?.data;
        if (errorData is Map<String, dynamic>) {
          return errorData['error'] ?? 'Username or email already exists';
        }
        return 'Username or email already exists';
      case 422:
        return 'Invalid input data';
      case 403:
        return 'Access forbidden';
      case 404:
        return 'Endpoint not found';
      case 500:
        return 'Server error occurred';
      default:
        break;
    }

    // Try to extract error message from response
    if (e.response?.data != null) {
      try {
        final errorData = e.response?.data;
        if (errorData is Map<String, dynamic>) {
          return errorData['error'] ?? errorData['message'] ?? defaultMessage;
        } else if (errorData is String) {
          return errorData;
        }
      } catch (parseError) {
        // If parsing fails, continue to default handling
      }
    }

    // Handle network errors
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout - check your internet connection';
      case DioExceptionType.sendTimeout:
        return 'Request timeout - server is taking too long to respond';
      case DioExceptionType.receiveTimeout:
        return 'Response timeout - server is taking too long to respond';
      case DioExceptionType.connectionError:
        return 'Cannot connect to server - check if server is running';
      case DioExceptionType.badResponse:
        return 'Bad response from server';
      case DioExceptionType.cancel:
        return 'Request was cancelled';
      case DioExceptionType.unknown:
        if (e.message?.contains('Failed host lookup') == true) {
          return 'Cannot resolve server address - check IP address';
        }
        return 'Unknown network error occurred';
      default:
        return defaultMessage;
    }
  }
}

// ✅ Auth Response Model
class AuthResponse {
  final User user;
  final String token;

  AuthResponse({
    required this.user,
    required this.token,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: User.fromJson(json['user']),
      token: json['token'],
    );
  }
}
