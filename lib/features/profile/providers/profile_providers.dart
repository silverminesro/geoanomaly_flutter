import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_profile_model.dart';
import '../services/profile_service.dart';

// ✅ Profile service provider
final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService();
});

// ✅ Profile state class
class ProfileState {
  final UserProfile? profile;
  final bool isLoading;
  final bool isRefreshing;
  final String? error;
  final bool isOffline;
  final DateTime? lastUpdated;

  const ProfileState({
    this.profile,
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
    this.isOffline = false,
    this.lastUpdated,
  });

  ProfileState copyWith({
    UserProfile? profile,
    bool? isLoading,
    bool? isRefreshing,
    String? error,
    bool? isOffline,
    DateTime? lastUpdated,
    bool clearError = false,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: clearError ? null : (error ?? this.error),
      isOffline: isOffline ?? this.isOffline,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  bool get hasProfile => profile != null;
  bool get hasError => error != null;
  bool get canRefresh => !isLoading && !isRefreshing;
}

// ✅ Profile notifier
class ProfileNotifier extends StateNotifier<ProfileState> {
  final ProfileService _profileService;

  ProfileNotifier(this._profileService) : super(const ProfileState());

  // ✅ Load user profile
  Future<void> loadProfile({bool forceRefresh = false}) async {
    try {
      print('👤 Loading profile (forceRefresh: $forceRefresh)...');

      // Check if we need to load
      if (!forceRefresh && state.hasProfile && !state.hasError) {
        print('✅ Profile already loaded, skipping');
        return;
      }

      // Set loading state
      state = state.copyWith(
        isLoading: !state.hasProfile,
        isRefreshing: state.hasProfile,
        clearError: true,
      );

      // Try to load from cache first if not force refresh
      if (!forceRefresh) {
        final cachedProfile = await _loadFromCache();
        if (cachedProfile != null) {
          print('📱 Loaded profile from cache');
          state = state.copyWith(
            profile: cachedProfile,
            isLoading: false,
            isOffline: true,
          );
        }
      }

      // Load from network
      final profile = await _profileService.getUserProfile();

      // Save to cache
      await _saveToCache(profile);

      // Update state
      state = state.copyWith(
        profile: profile,
        isLoading: false,
        isRefreshing: false,
        isOffline: false,
        lastUpdated: DateTime.now(),
        clearError: true,
      );

      print('✅ Profile loaded successfully: ${profile.username}');
    } catch (e) {
      print('❌ Profile loading error: $e');

      // Try cache if network failed
      if (!state.hasProfile) {
        final cachedProfile = await _loadFromCache();
        if (cachedProfile != null) {
          print('📱 Fallback to cached profile due to network error');
          state = state.copyWith(
            profile: cachedProfile,
            isLoading: false,
            isRefreshing: false,
            isOffline: true,
            error: 'Using cached data - $e',
          );
          return;
        }
      }

      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: e.toString(),
      );
    }
  }

  // ✅ Update profile
  Future<bool> updateProfile(UpdateProfileRequest request) async {
    try {
      print('👤 Updating profile...');

      state = state.copyWith(isLoading: true, clearError: true);

      final updatedProfile = await _profileService.updateProfile(request);

      // Save to cache
      await _saveToCache(updatedProfile);

      state = state.copyWith(
        profile: updatedProfile,
        isLoading: false,
        isOffline: false,
        lastUpdated: DateTime.now(),
        clearError: true,
      );

      print('✅ Profile updated successfully');
      return true;
    } catch (e) {
      print('❌ Profile update error: $e');

      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );

      return false;
    }
  }

  // ✅ Update username
  Future<bool> updateUsername(String newUsername) async {
    try {
      print('👤 Updating username to: $newUsername');

      // Validate username
      if (newUsername.length < 3) {
        state = state.copyWith(
            error: 'Username must be at least 3 characters long');
        return false;
      }

      state = state.copyWith(isLoading: true, clearError: true);

      final updatedProfile = await _profileService.updateUsername(newUsername);

      await _saveToCache(updatedProfile);

      state = state.copyWith(
        profile: updatedProfile,
        isLoading: false,
        lastUpdated: DateTime.now(),
        clearError: true,
      );

      print('✅ Username updated successfully');
      return true;
    } catch (e) {
      print('❌ Username update error: $e');

      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );

      return false;
    }
  }

  // ✅ Update email
  Future<bool> updateEmail(String newEmail) async {
    try {
      print('📧 Updating email to: $newEmail');

      state = state.copyWith(isLoading: true, clearError: true);

      final updatedProfile = await _profileService.updateEmail(newEmail);

      await _saveToCache(updatedProfile);

      state = state.copyWith(
        profile: updatedProfile,
        isLoading: false,
        lastUpdated: DateTime.now(),
        clearError: true,
      );

      print('✅ Email updated successfully');
      return true;
    } catch (e) {
      print('❌ Email update error: $e');

      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );

      return false;
    }
  }

  // ✅ Update avatar emoji
  Future<bool> updateAvatarEmoji(String emoji) async {
    try {
      print('🎭 Updating avatar emoji to: $emoji');

      // Optimistic update
      final currentProfile = state.profile;
      if (currentProfile != null) {
        final optimisticProfile = currentProfile.withAvatarEmoji(emoji);
        state = state.copyWith(profile: optimisticProfile);
      }

      final updatedProfile = await _profileService.updateAvatarSettings(
        avatarEmoji: emoji,
      );

      await _saveToCache(updatedProfile);

      state = state.copyWith(
        profile: updatedProfile,
        lastUpdated: DateTime.now(),
        clearError: true,
      );

      print('✅ Avatar emoji updated successfully');
      return true;
    } catch (e) {
      print('❌ Avatar emoji update error: $e');

      // Revert optimistic update on error
      await loadProfile();

      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // ✅ Toggle gravatar
  Future<bool> toggleGravatar(bool useGravatar) async {
    try {
      print('🖼️ Toggling gravatar: $useGravatar');

      // Optimistic update
      final currentProfile = state.profile;
      if (currentProfile != null) {
        final optimisticProfile = currentProfile.withGravatar(useGravatar);
        state = state.copyWith(profile: optimisticProfile);
      }

      final updatedProfile = await _profileService.updateAvatarSettings(
        useGravatar: useGravatar,
      );

      await _saveToCache(updatedProfile);

      state = state.copyWith(
        profile: updatedProfile,
        lastUpdated: DateTime.now(),
        clearError: true,
      );

      print('✅ Gravatar setting updated successfully');
      return true;
    } catch (e) {
      print('❌ Gravatar update error: $e');

      // Revert optimistic update on error
      await loadProfile();

      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // ✅ Refresh profile
  Future<void> refresh() async {
    await loadProfile(forceRefresh: true);
  }

  // ✅ Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  // ✅ Reset profile (for logout)
  void reset() {
    state = const ProfileState();
    _clearCache();
  }

  // ✅ Cache management
  Future<void> _saveToCache(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'profile': profile.toJson(),
        'cached_at': DateTime.now().toIso8601String(),
      };

      await prefs.setString('cached_profile', json.encode(cacheData));
      print('💾 Profile saved to cache');
    } catch (e) {
      print('❌ Failed to save profile to cache: $e');
    }
  }

  Future<UserProfile?> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheString = prefs.getString('cached_profile');

      if (cacheString == null) return null;

      final cacheData = json.decode(cacheString) as Map<String, dynamic>;
      final cachedAt = DateTime.parse(cacheData['cached_at']);

      // Check if cache is too old (24 hours)
      if (DateTime.now().difference(cachedAt).inHours > 24) {
        print('⏰ Profile cache expired');
        await _clearCache();
        return null;
      }

      final profileJson = cacheData['profile'] as Map<String, dynamic>;
      return UserProfile.fromJson(profileJson);
    } catch (e) {
      print('❌ Failed to load profile from cache: $e');
      await _clearCache();
      return null;
    }
  }

  Future<void> _clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_profile');
      print('🗑️ Profile cache cleared');
    } catch (e) {
      print('❌ Failed to clear profile cache: $e');
    }
  }

  // ✅ Debug method
  void debugProfile() {
    print('🧪 Profile State Debug:');
    print('  - Has Profile: ${state.hasProfile}');
    print('  - Is Loading: ${state.isLoading}');
    print('  - Is Refreshing: ${state.isRefreshing}');
    print('  - Has Error: ${state.hasError}');
    print('  - Is Offline: ${state.isOffline}');
    print('  - Last Updated: ${state.lastUpdated}');
    if (state.profile != null) {
      print(
          '  - Profile: ${state.profile!.username} (${state.profile!.tierDisplayName})');
    }
    if (state.error != null) {
      print('  - Error: ${state.error}');
    }
  }
}

// ✅ Profile provider
final profileProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final profileService = ref.read(profileServiceProvider);
  return ProfileNotifier(profileService);
});
// ✅ Current user provider (convenience)
final currentUserProvider = Provider<UserProfile?>((ref) {
  return ref.watch(profileProvider).profile;
});

// ✅ Profile stats provider
final profileStatsProvider = Provider<Map<String, dynamic>?>((ref) {
  final profile = ref.watch(currentUserProvider);

  if (profile == null) return null;

  return {
    'total_items': profile.totalItems,
    'total_artifacts': profile.totalArtifacts,
    'total_gear': profile.totalGear,
    'zones_discovered': profile.zonesDiscovered,
    'current_level': profile.level,
    'current_xp': profile.xp,
    'xp_to_next_level': profile.xpToNextLevel,
    'level_progress': profile.levelProgress,
    'account_age_days': profile.accountAgeDays,
    'account_age_formatted': profile.accountAgeFormatted,
    'tier_info': {
      'current_tier': profile.tier,
      'tier_name': profile.tierDisplayName,
      'tier_emoji': profile.tierEmoji,
      'tier_color': profile.tierColorHex,
    },
    'avatar_info': {
      'emoji': profile.avatarEmoji,
      'gravatar_url': profile.gravatarUrl,
      'use_gravatar': profile.useGravatar,
      'display_avatar': profile.displayAvatar,
    },
    'activity': {
      'is_active': profile.isActive,
      'activity_status': profile.activityStatus,
    },
  };
});

// ✅ Quick access providers
final userLevelProvider = Provider<int>((ref) {
  return ref.watch(currentUserProvider)?.level ?? 1;
});

final userTierProvider = Provider<int>((ref) {
  return ref.watch(currentUserProvider)?.tier ?? 0;
});

final userAvatarProvider = Provider<String>((ref) {
  final profile = ref.watch(currentUserProvider);
  return profile?.displayAvatar ?? '😀';
});

final userXpProgressProvider = Provider<double>((ref) {
  return ref.watch(currentUserProvider)?.levelProgress ?? 0.0;
});

// ✅ Profile loading state providers
final isProfileLoadingProvider = Provider<bool>((ref) {
  return ref.watch(profileProvider).isLoading;
});

final profileErrorProvider = Provider<String?>((ref) {
  return ref.watch(profileProvider).error;
});

final isProfileOfflineProvider = Provider<bool>((ref) {
  return ref.watch(profileProvider).isOffline;
});
