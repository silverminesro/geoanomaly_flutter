import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../models/auth_models.dart';

class AuthService {
  final ApiClient _apiClient;

  AuthService(this._apiClient);

  // ✅ Getter for ApiClient access
  ApiClient get apiClient => _apiClient;

  // ✅ Login (POST /auth/login) - FIXED for Go backend
  Future<AuthResponse> login(LoginRequest request) async {
    try {
      final response =
          await _apiClient.post('/auth/login', data: request.toJson());

      // ✅ FIXED: Handle Go backend response format
      Map<String, dynamic> responseData;
      if (response.data is Map<String, dynamic>) {
        responseData = response.data as Map<String, dynamic>;
      } else {
        throw AuthException('Invalid response format');
      }

      // ✅ Go backend returns: {"message": "Login successful", "token": "...", "user": {...}}
      if (responseData.containsKey('token') &&
          responseData.containsKey('user')) {
        final authResponse = AuthResponse(
          token: responseData['token'] as String,
          user: User.fromJson(responseData['user'] as Map<String, dynamic>),
        );

        // ✅ Save token immediately after successful login
        await _apiClient.saveToken(authResponse.token);
        return authResponse;
      } else {
        throw AuthException('Invalid response format from server');
      }
    } on DioException catch (e) {
      throw AuthException(_handleDioError(e, 'Login failed'));
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Network error: ${e.toString()}');
    }
  }

  // ✅ Register (POST /auth/register) - FIXED for Go backend
  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      final response =
          await _apiClient.post('/auth/register', data: request.toJson());

      // ✅ FIXED: Handle Go backend response format
      Map<String, dynamic> responseData;
      if (response.data is Map<String, dynamic>) {
        responseData = response.data as Map<String, dynamic>;
      } else {
        throw AuthException('Invalid response format');
      }

      // ✅ Go backend returns: {"message": "User registered successfully", "token": "...", "user": {...}}
      if (responseData.containsKey('token') &&
          responseData.containsKey('user')) {
        final authResponse = AuthResponse(
          token: responseData['token'] as String,
          user: User.fromJson(responseData['user'] as Map<String, dynamic>),
        );

        // ✅ Save token immediately after successful registration
        await _apiClient.saveToken(authResponse.token);
        return authResponse;
      } else {
        throw AuthException('Invalid response format from server');
      }
    } on DioException catch (e) {
      throw AuthException(_handleDioError(e, 'Registration failed'));
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Network error: ${e.toString()}');
    }
  }

  // ✅ Get Profile (GET /user/profile) - FIXED for Go backend
  Future<User> getProfile() async {
    try {
      final response = await _apiClient.get('/user/profile');

      // ✅ FIXED: Handle Go backend response format
      Map<String, dynamic> responseData;
      if (response.data is Map<String, dynamic>) {
        responseData = response.data as Map<String, dynamic>;
      } else {
        throw AuthException('Invalid response format');
      }

      // ✅ Go backend might return: {"user": {...}} or directly {...}
      if (responseData.containsKey('user')) {
        return User.fromJson(responseData['user'] as Map<String, dynamic>);
      } else {
        // Direct user object
        return User.fromJson(responseData);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _apiClient.clearToken();
        throw AuthException('Session expired');
      }
      throw AuthException(_handleDioError(e, 'Failed to get profile'));
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Network error: ${e.toString()}');
    }
  }

  // ✅ Refresh Token (POST /auth/refresh) - FIXED for Go backend
  Future<AuthResponse> refreshToken() async {
    try {
      final response = await _apiClient.post('/auth/refresh');

      // ✅ FIXED: Handle Go backend response format
      Map<String, dynamic> responseData;
      if (response.data is Map<String, dynamic>) {
        responseData = response.data as Map<String, dynamic>;
      } else {
        throw AuthException('Invalid response format');
      }

      // ✅ Go backend returns: {"message": "Token refreshed successfully", "token": "...", "user_tier": 1}
      if (responseData.containsKey('token')) {
        final authResponse = AuthResponse(
          token: responseData['token'] as String,
          user: User.fromJson({}), // We'll get user from separate profile call
        );

        // ✅ Save new token
        await _apiClient.saveToken(authResponse.token);
        return authResponse;
      } else {
        throw AuthException('Invalid response format from server');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _apiClient.clearToken();
        throw AuthException('Session expired');
      }
      throw AuthException(_handleDioError(e, 'Token refresh failed'));
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Network error: ${e.toString()}');
    }
  }

  // ✅ Logout (POST /auth/logout) - FIXED for Go backend
  Future<void> logout() async {
    try {
      // ✅ Try to notify backend about logout
      await _apiClient.post('/auth/logout');
    } catch (e) {
      // ✅ Even if backend call fails, clear local token
      print('Logout API call failed: $e');
    } finally {
      // ✅ Always clear token locally
      await _apiClient.clearToken();
    }
  }

  // ✅ Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await _apiClient.getToken();
    return token != null && token.isNotEmpty;
  }

  // ✅ Validate token by checking profile
  Future<bool> validateToken() async {
    try {
      if (!await isLoggedIn()) return false;

      // Try to get profile to validate token
      await getProfile();
      return true;
    } catch (e) {
      // Token is invalid, clear it
      await _apiClient.clearToken();
      return false;
    }
  }

  // ✅ ENHANCED: Better error handling for Go backend
  String _handleDioError(DioException e, String defaultMessage) {
    // ✅ Handle specific HTTP status codes
    switch (e.response?.statusCode) {
      case 401:
        return 'Invalid credentials or session expired';
      case 409:
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

    // ✅ Try to extract error message from Go backend response
    if (e.response?.data != null) {
      try {
        final errorData = e.response?.data;
        if (errorData is Map<String, dynamic>) {
          // Go backend returns: {"error": "message"} or {"message": "message"}
          return errorData['error'] ?? errorData['message'] ?? defaultMessage;
        } else if (errorData is String) {
          return errorData;
        }
      } catch (parseError) {
        // If parsing fails, continue to default handling
      }
    }

    // ✅ Handle network errors
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

  // ✅ ADDED: Debug method to test connection
  Future<Map<String, dynamic>> testConnection() async {
    try {
      // Test health endpoint
      final healthResponse = await _apiClient.get('/../../health');

      // Test API endpoint
      final apiResponse = await _apiClient.get('/test');

      return {
        'health': healthResponse.data,
        'api': apiResponse.data,
        'status': 'connected',
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'status': 'failed',
      };
    }
  }
}

// ✅ Custom Auth Exception
class AuthException implements Exception {
  final String message;

  AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}
