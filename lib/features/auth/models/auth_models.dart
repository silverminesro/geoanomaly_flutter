// ✅ User Model
class User {
  final String id;
  final String username;
  final String email;
  final int tier;
  final int level;
  final int xp;
  final int totalArtifacts;
  final int totalGear;
  final int zonesDiscovered;
  final bool isActive;
  final bool isBanned;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.tier,
    required this.level,
    required this.xp,
    required this.totalArtifacts,
    required this.totalGear,
    required this.zonesDiscovered,
    required this.isActive,
    required this.isBanned,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      tier: json['tier'] ?? 0,
      level: json['level'] ?? 1,
      xp: json['xp'] ?? 0,
      totalArtifacts: json['total_artifacts'] ?? 0,
      totalGear: json['total_gear'] ?? 0,
      zonesDiscovered: json['zones_discovered'] ?? 0,
      isActive: json['is_active'] ?? true,
      isBanned: json['is_banned'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'tier': tier,
      'level': level,
      'xp': xp,
      'total_artifacts': totalArtifacts,
      'total_gear': totalGear,
      'zones_discovered': zonesDiscovered,
      'is_active': isActive,
      'is_banned': isBanned,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get tierName {
    switch (tier) {
      case 0:
        return 'Free';
      case 1:
        return 'Basic';
      case 2:
        return 'Standard';
      case 3:
        return 'Premium';
      case 4:
        return 'Elite';
      default:
        return 'Unknown';
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
