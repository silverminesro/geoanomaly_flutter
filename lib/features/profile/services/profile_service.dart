import 'package:dio/dio.dart';
import 'dart:convert';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/user_profile_model.dart';

class ProfileService {
  final Dio _dio = ApiClient.dio;

  // ✅ Get user profile from backend
  Future<UserProfile> getUserProfile() async {
    try {
      print('👤 Loading user profile...');

      final response = await _dio.get(ApiConstants.userProfile);

      print('✅ Profile response status: ${response.statusCode}');
      print('🔍 Profile response type: ${response.data.runtimeType}');
      print('📊 Profile raw response: ${response.data}');

      // ✅ ENHANCED: Handle different response formats
      Map<String, dynamic> profileData;

      if (response.data is Map) {
        final data = response.data as Map<String, dynamic>;

        // Check if wrapped in 'user' key
        if (data.containsKey('user')) {
          profileData = data['user'] as Map<String, dynamic>;
          print('📦 Found profile in "user" wrapper');
        } else {
          profileData = data;
          print('📦 Direct profile data');
        }
      } else {
        throw Exception(
            'Invalid profile response format: ${response.data.runtimeType}');
      }

      print('🔍 Profile data keys: ${profileData.keys}');

      // ✅ DEBUG: Log important fields
      if (profileData.containsKey('profile_data')) {
        final profileDataField = profileData['profile_data'];
        print('🔍 Profile data field type: ${profileDataField.runtimeType}');

        if (profileDataField is String) {
          print('🔧 Profile data is JSON string, parsing...');
          try {
            profileData['profile_data'] = json.decode(profileDataField);
            print('✅ Profile data JSON parsed successfully');
          } catch (e) {
            print('❌ Failed to parse profile data JSON: $e');
            profileData['profile_data'] = <String, dynamic>{};
          }
        }
      } else {
        print('⚠️ No profile_data field found, using empty map');
        profileData['profile_data'] = <String, dynamic>{};
      }

      final profile = UserProfile.fromJson(profileData);
      print(
          '✅ Profile parsed: ${profile.username} (Level ${profile.level}, Tier ${profile.tier})');
      print(
          '🎭 Avatar: ${profile.avatarEmoji} (UseGravatar: ${profile.useGravatar})');

      return profile;
    } on DioException catch (e) {
      print('❌ Profile DioException: ${e.response?.statusCode}');
      print('❌ Response data: ${e.response?.data}');
      print('❌ Request URL: ${e.requestOptions.uri}');

      throw Exception(_handleDioError(e, 'Failed to load user profile'));
    } catch (e) {
      print('❌ Unexpected profile error: $e');
      print('❌ Error type: ${e.runtimeType}');
      throw Exception('Unexpected error occurred while loading profile: $e');
    }
  }

  // ✅ Update user profile
  Future<UserProfile> updateProfile(UpdateProfileRequest request) async {
    try {
      print('👤 Updating user profile...');
      print('📝 Update data: ${request.toJson()}');

      final response = await _dio.put(
        ApiConstants.userProfile,
        data: request.toJson(),
      );

      print('✅ Profile update response: ${response.statusCode}');
      print('📊 Update response: ${response.data}');

      // ✅ ENHANCED: Handle update response
      Map<String, dynamic> profileData;

      if (response.data is Map) {
        final data = response.data as Map<String, dynamic>;

        if (data.containsKey('user')) {
          profileData = data['user'] as Map<String, dynamic>;
        } else {
          profileData = data;
        }
      } else {
        throw Exception('Invalid update response format');
      }

      // Handle profile_data JSON string
      if (profileData.containsKey('profile_data') &&
          profileData['profile_data'] is String) {
        try {
          profileData['profile_data'] =
              json.decode(profileData['profile_data']);
        } catch (e) {
          print('❌ Failed to parse updated profile data: $e');
          profileData['profile_data'] = <String, dynamic>{};
        }
      }

      final updatedProfile = UserProfile.fromJson(profileData);
      print('✅ Profile updated: ${updatedProfile.username}');
      print('🎭 New avatar: ${updatedProfile.displayAvatar}');

      return updatedProfile;
    } on DioException catch (e) {
      print('❌ Profile update error: ${e.response?.data}');

      if (e.response?.statusCode == 409) {
        // Handle conflict (username/email already exists)
        final data = e.response?.data as Map<String, dynamic>?;
        final errorMessage =
            data?['error'] ?? 'Username or email already exists';
        throw Exception(errorMessage);
      }

      throw Exception(_handleDioError(e, 'Failed to update profile'));
    } catch (e) {
      print('❌ Unexpected update error: $e');
      throw Exception('Unexpected error occurred while updating profile: $e');
    }
  }

  // ✅ Update only avatar/profile data (for quick avatar changes)
  Future<UserProfile> updateAvatarSettings({
    String? avatarEmoji,
    bool? useGravatar,
  }) async {
    try {
      print('🎭 Updating avatar settings...');
      print('🎨 Avatar emoji: $avatarEmoji');
      print('🖼️ Use gravatar: $useGravatar');

      final profileData = <String, dynamic>{};

      if (avatarEmoji != null) {
        profileData['avatar_emoji'] = avatarEmoji;
        profileData['use_gravatar'] = false; // Override to use emoji
      }

      if (useGravatar != null) {
        profileData['use_gravatar'] = useGravatar;
      }

      final request = UpdateProfileRequest(profileData: profileData);
      return await updateProfile(request);
    } catch (e) {
      print('❌ Avatar update error: $e');
      throw Exception('Failed to update avatar settings: $e');
    }
  }

  // ✅ Update username only
  Future<UserProfile> updateUsername(String newUsername) async {
    try {
      print('👤 Updating username to: $newUsername');

      if (newUsername.length < 3) {
        throw Exception('Username must be at least 3 characters long');
      }

      if (newUsername.length > 50) {
        throw Exception('Username must be less than 50 characters');
      }

      final request = UpdateProfileRequest(username: newUsername);
      return await updateProfile(request);
    } catch (e) {
      print('❌ Username update error: $e');
      rethrow;
    }
  }

  // ✅ Update email only
  Future<UserProfile> updateEmail(String newEmail) async {
    try {
      print('📧 Updating email to: $newEmail');

      if (!_isValidEmail(newEmail)) {
        throw Exception('Please enter a valid email address');
      }

      final request = UpdateProfileRequest(email: newEmail);
      return await updateProfile(request);
    } catch (e) {
      print('❌ Email update error: $e');
      rethrow;
    }
  }

  // ✅ Get user statistics (calculated from profile + inventory)
  Future<Map<String, dynamic>> getUserStatistics() async {
    try {
      print('📊 Loading user statistics...');

      // Get profile first
      final profile = await getUserProfile();

      // ✅ TODO: Could enhance with inventory service data
      // For now, use profile statistics
      final stats = {
        'total_items': profile.totalItems,
        'total_artifacts': profile.totalArtifacts,
        'total_gear': profile.totalGear,
        'zones_discovered': profile.zonesDiscovered,
        'current_level': profile.level,
        'current_xp': profile.xp,
        'xp_to_next_level': profile.xpToNextLevel,
        'level_progress': profile.levelProgress,
        'account_age_days': profile.accountAgeDays,
        'tier_info': {
          'current_tier': profile.tier,
          'tier_name': profile.tierDisplayName,
          'tier_emoji': profile.tierEmoji,
        },
        'activity': {
          'is_active': profile.isActive,
          'last_activity': profile.activityStatus,
        },
      };

      print('📊 Statistics loaded successfully');
      return stats;
    } catch (e) {
      print('❌ Statistics error: $e');
      throw Exception('Failed to load user statistics: $e');
    }
  }

  // ✅ Validate profile changes before sending
  Future<bool> validateUsername(String username) async {
    try {
      if (username.length < 3 || username.length > 50) {
        return false;
      }

      // Check for invalid characters (basic validation)
      final validPattern = RegExp(r'^[a-zA-Z0-9_-]+$');
      return validPattern.hasMatch(username);
    } catch (e) {
      print('❌ Username validation error: $e');
      return false;
    }
  }

  // ✅ Test connection to profile endpoint
  Future<bool> testProfileConnection() async {
    try {
      final response = await _dio.get(ApiConstants.userProfile);
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Profile connection test failed: $e');
      return false;
    }
  }

  // ✅ Helper methods
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  String _handleDioError(DioException e, String defaultMessage) {
    switch (e.response?.statusCode) {
      case 401:
        return 'Authentication required. Please login again.';
      case 403:
        return 'Access forbidden. Check your permissions.';
      case 404:
        return 'Profile not found.';
      case 409:
        return 'Username or email already exists.';
      case 422:
        return 'Invalid profile data. Please check your input.';
      case 429:
        return 'Too many requests. Please wait before trying again.';
      case 500:
        return 'Server error. Please try again later.';
      case 501:
        return 'Profile feature not implemented yet.';
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
      case DioExceptionType.connectionError:
        return 'Connection error. Check your internet connection.';
      default:
        break;
    }

    return defaultMessage;
  }

  // ✅ Debug method for testing
  Future<void> debugProfileData() async {
    try {
      print('🧪 Debug: Testing profile endpoint...');
      final profile = await getUserProfile();

      print('🧪 Debug Profile Info:');
      print('  - ID: ${profile.id}');
      print('  - Username: ${profile.username}');
      print('  - Email: ${profile.email}');
      print('  - Level: ${profile.level} (XP: ${profile.xp})');
      print('  - Tier: ${profile.tier} (${profile.tierDisplayName})');
      print(
          '  - Stats: ${profile.totalArtifacts} artifacts, ${profile.totalGear} gear');
      print(
          '  - Avatar: ${profile.avatarEmoji} (Gravatar: ${profile.useGravatar})');
      print('  - Profile Data: ${profile.profileData}');
      print('  - Account Age: ${profile.accountAgeFormatted}');
      print('  - Activity: ${profile.activityStatus}');
    } catch (e) {
      print('🧪 Debug failed: $e');
    }
  }
}
