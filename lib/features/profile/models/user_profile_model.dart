import 'package:crypto/crypto.dart';
import 'dart:convert';

class UserProfile {
  final String id;
  final String username;
  final String email;

  // Game progression
  final int tier; // 0-4 (Free/Premium tiers)
  final int xp;
  final int level;

  // Statistics
  final int totalArtifacts;
  final int totalGear;
  final int zonesDiscovered;

  // Account info
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Profile customization (stored in backend profileData JSONB)
  final Map<String, dynamic> profileData;

  const UserProfile({
    required this.id,
    required this.username,
    required this.email,
    required this.tier,
    required this.xp,
    required this.level,
    required this.totalArtifacts,
    required this.totalGear,
    required this.zonesDiscovered,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.profileData = const {},
  });

  // ✅ FIXED: Custom JSON parser with proper XP/Level handling
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    try {
      print('🔍 Parsing UserProfile JSON: $json');

      // Handle nested stats object
      final stats = json['stats'] as Map<String, dynamic>? ?? {};
      print('📊 Stats object: $stats');

      // Parse dates safely
      DateTime parseDate(String? dateStr) {
        if (dateStr == null || dateStr.isEmpty) {
          return DateTime.now();
        }
        try {
          return DateTime.parse(dateStr);
        } catch (e) {
          print('⚠️ Date parsing error for "$dateStr": $e');
          return DateTime.now();
        }
      }

      // ✅ SMART PARSING: Try multiple sources for XP and Level
      final xpFromRoot = json['xp'] as int?;
      final xpFromStats = stats['xp'] as int?;
      final finalXP = xpFromRoot ?? xpFromStats ?? 0;

      final levelFromRoot = json['level'] as int?;
      final levelFromStats = stats['level'] as int?;
      final finalLevel = levelFromRoot ?? levelFromStats ?? 1;

      print('📊 XP: root=$xpFromRoot, stats=$xpFromStats, final=$finalXP');
      print(
          '📊 Level: root=$levelFromRoot, stats=$levelFromStats, final=$finalLevel');

      final profile = UserProfile(
        id: json['id'] as String,
        username: json['username'] as String,
        email: json['email'] as String,
        tier: json['tier'] as int? ?? 0,

        // ✅ Use smart parsed values
        xp: finalXP,
        level: finalLevel,

        // ✅ Get from nested stats object
        totalArtifacts: stats['total_artifacts'] as int? ?? 0,
        totalGear: stats['total_gear'] as int? ?? 0,
        zonesDiscovered: stats['zones_visited'] as int? ?? 0,

        isActive: json['is_active'] as bool? ?? true,
        createdAt: parseDate(json['created_at'] as String?),
        updatedAt: parseDate(json['updated_at'] as String?),
        profileData: json['profile_data'] as Map<String, dynamic>? ?? {},
      );

      print(
          '✅ UserProfile parsed - Username: ${profile.username}, XP: ${profile.xp}, Level: ${profile.level}');
      print(
          '✅ Stats - Artifacts: ${profile.totalArtifacts}, Gear: ${profile.totalGear}');
      return profile;
    } catch (e, stackTrace) {
      print('❌ UserProfile parsing error: $e');
      print('❌ Stack trace: $stackTrace');
      print('❌ JSON data: $json');
      rethrow;
    }
  }

  // ✅ Custom toJson method
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'tier': tier,
      'xp': xp,
      'level': level,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'profile_data': profileData,
      'stats': {
        'total_artifacts': totalArtifacts,
        'total_gear': totalGear,
        'zones_visited': zonesDiscovered,
        'level': level,
        'xp': xp,
      },
    };
  }

  // ✅ AVATAR SYSTEM
  /// Get selected emoji avatar (default: random based on username)
  String get avatarEmoji {
    final selectedEmoji = profileData['avatar_emoji'] as String?;
    if (selectedEmoji != null && selectedEmoji.isNotEmpty) {
      return selectedEmoji;
    }

    // Generate consistent emoji based on username
    return _generateDefaultEmoji(username);
  }

  /// Get gravatar URL based on email
  String get gravatarUrl {
    final emailHash =
        md5.convert(utf8.encode(email.toLowerCase().trim())).toString();
    return 'https://www.gravatar.com/avatar/$emailHash?s=200&d=identicon';
  }

  /// Check if user prefers gravatar over emoji
  bool get useGravatar {
    return profileData['use_gravatar'] as bool? ?? false;
  }

  /// Get display avatar (either emoji or gravatar URL)
  String get displayAvatar {
    return useGravatar ? gravatarUrl : avatarEmoji;
  }

  // ✅ TIER SYSTEM
  /// Get tier display name
  String get tierDisplayName {
    switch (tier) {
      case 0:
        return 'Free Player';
      case 1:
        return 'Explorer';
      case 2:
        return 'Adventurer';
      case 3:
        return 'Master Explorer';
      case 4:
        return 'Legendary Hunter';
      default:
        return 'Unknown Tier';
    }
  }

  /// Get tier emoji/icon
  String get tierEmoji {
    switch (tier) {
      case 0:
        return '🆓';
      case 1:
        return '🗺️';
      case 2:
        return '⚔️';
      case 3:
        return '🏆';
      case 4:
        return '👑';
      default:
        return '❓';
    }
  }

  /// Get tier color (for UI)
  String get tierColorHex {
    switch (tier) {
      case 0:
        return '#9E9E9E'; // Grey
      case 1:
        return '#4CAF50'; // Green
      case 2:
        return '#2196F3'; // Blue
      case 3:
        return '#9C27B0'; // Purple
      case 4:
        return '#FF9800'; // Orange
      default:
        return '#9E9E9E';
    }
  }

  // ✅ LEVEL SYSTEM
  /// Calculate XP needed for next level
  int get xpForNextLevel {
    return _calculateXPForLevel(level + 1);
  }

  /// Calculate XP needed for current level
  int get xpForCurrentLevel {
    return level > 1 ? _calculateXPForLevel(level) : 0;
  }

  /// Get XP progress in current level (0.0 - 1.0)
  double get levelProgress {
    final currentLevelXP = xpForCurrentLevel;
    final nextLevelXP = xpForNextLevel;
    final progressXP = xp - currentLevelXP;
    final levelRange = nextLevelXP - currentLevelXP;

    if (levelRange <= 0) return 1.0;
    return (progressXP / levelRange).clamp(0.0, 1.0);
  }

  /// Get XP remaining for next level
  int get xpToNextLevel {
    return (xpForNextLevel - xp).clamp(0, xpForNextLevel);
  }

  // ✅ STATISTICS
  /// Total items collected
  int get totalItems => totalArtifacts + totalGear;

  /// Account age in days
  int get accountAgeDays {
    return DateTime.now().difference(createdAt).inDays;
  }

  /// Formatted account age
  String get accountAgeFormatted {
    final days = accountAgeDays;
    if (days < 7) {
      return '$days day${days == 1 ? '' : 's'}';
    } else if (days < 30) {
      final weeks = (days / 7).floor();
      return '$weeks week${weeks == 1 ? '' : 's'}';
    } else if (days < 365) {
      final months = (days / 30).floor();
      return '$months month${months == 1 ? '' : 's'}';
    } else {
      final years = (days / 365).floor();
      return '$years year${years == 1 ? '' : 's'}';
    }
  }

  /// Activity status
  String get activityStatus {
    final now = DateTime.now();
    final daysSinceUpdate = now.difference(updatedAt).inDays;

    if (daysSinceUpdate == 0) return 'Active today';
    if (daysSinceUpdate == 1) return 'Last seen yesterday';
    if (daysSinceUpdate < 7) return 'Last seen $daysSinceUpdate days ago';
    if (daysSinceUpdate < 30)
      return 'Last seen ${(daysSinceUpdate / 7).floor()} weeks ago';
    return 'Last seen ${(daysSinceUpdate / 30).floor()} months ago';
  }

  // ✅ PROFILE CUSTOMIZATION
  /// Update avatar emoji
  UserProfile withAvatarEmoji(String emoji) {
    final newProfileData = Map<String, dynamic>.from(profileData);
    newProfileData['avatar_emoji'] = emoji;
    newProfileData['use_gravatar'] = false;

    return copyWith(profileData: newProfileData);
  }

  /// Toggle gravatar usage
  UserProfile withGravatar(bool useGravatar) {
    final newProfileData = Map<String, dynamic>.from(profileData);
    newProfileData['use_gravatar'] = useGravatar;

    return copyWith(profileData: newProfileData);
  }

  /// Update profile data
  UserProfile withProfileData(Map<String, dynamic> newData) {
    final mergedData = Map<String, dynamic>.from(profileData);
    mergedData.addAll(newData);

    return copyWith(profileData: mergedData);
  }

  // ✅ COPY WITH METHOD
  UserProfile copyWith({
    String? id,
    String? username,
    String? email,
    int? tier,
    int? xp,
    int? level,
    int? totalArtifacts,
    int? totalGear,
    int? zonesDiscovered,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? profileData,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      tier: tier ?? this.tier,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      totalArtifacts: totalArtifacts ?? this.totalArtifacts,
      totalGear: totalGear ?? this.totalGear,
      zonesDiscovered: zonesDiscovered ?? this.zonesDiscovered,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      profileData: profileData ?? this.profileData,
    );
  }

  // ✅ HELPER METHODS
  /// Generate default emoji based on username
  String _generateDefaultEmoji(String username) {
    const emojis = [
      '😀',
      '😃',
      '😄',
      '😁',
      '😊',
      '🙂',
      '😉',
      '😌',
      '😍',
      '🥰',
      '😘',
      '😗',
      '😙',
      '😚',
      '😋',
      '😛',
      '😝',
      '😜',
      '🤪',
      '🤨',
      '🧐',
      '🤓',
      '😎',
      '🥸',
      '🤩',
      '🥳',
      '😏',
      '😒',
      '😞',
      '😔',
      '🎮',
      '🎯',
      '🎲',
      '🃏',
      '🎭',
      '🎪',
      '🎨',
      '🎬',
      '🎤',
      '🎧',
      '🎼',
      '🎵',
      '🎶',
      '🎹',
      '🥁',
      '🎷',
      '🎺',
      '🎸',
      '🪕',
      '🎻',
    ];

    final hash = username.hashCode.abs();
    return emojis[hash % emojis.length];
  }

  /// Calculate XP needed for specific level
  int _calculateXPForLevel(int targetLevel) {
    if (targetLevel <= 1) return 0;

    // XP formula: level^2 * 100 (exponential growth)
    return (targetLevel * targetLevel * 100);
  }

  @override
  String toString() {
    return 'UserProfile(id: $id, username: $username, level: $level, tier: $tier, xp: $xp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// ✅ UPDATE PROFILE REQUEST MODEL (simplified without annotations)
class UpdateProfileRequest {
  final String? username;
  final String? email;
  final Map<String, dynamic>? profileData;

  const UpdateProfileRequest({
    this.username,
    this.email,
    this.profileData,
  });

  factory UpdateProfileRequest.fromJson(Map<String, dynamic> json) {
    return UpdateProfileRequest(
      username: json['username'] as String?,
      email: json['email'] as String?,
      profileData: json['profile_data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (username != null) 'username': username,
      if (email != null) 'email': email,
      if (profileData != null) 'profile_data': profileData,
    };
  }
}
