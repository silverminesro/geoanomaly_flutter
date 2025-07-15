import 'package:equatable/equatable.dart';

// ✅ Login Request (bez JSON generator)
class LoginRequest extends Equatable {
  final String username;
  final String password;

  const LoginRequest({
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'username': username,
        'password': password,
      };

  @override
  List<Object?> get props => [username, password];
}

// ✅ Register Request
class RegisterRequest extends Equatable {
  final String username;
  final String email;
  final String password;

  const RegisterRequest({
    required this.username,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'username': username,
        'email': email,
        'password': password,
      };

  @override
  List<Object?> get props => [username, email, password];
}

// ✅ User Model (manuálny JSON parsing)
class User extends Equatable {
  final String id;
  final String username;
  final String email;
  final int tier;
  final bool isActive;
  final String createdAt;
  final int xp;
  final int level;
  final int totalArtifacts;
  final int totalGear;
  final int zonesDiscovered;

  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.tier,
    required this.isActive,
    required this.createdAt,
    this.xp = 0,
    this.level = 1,
    this.totalArtifacts = 0,
    this.totalGear = 0,
    this.zonesDiscovered = 0,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        username: json['username'] as String,
        email: json['email'] as String,
        tier: json['tier'] as int,
        isActive: json['is_active'] as bool,
        createdAt: json['created_at'] as String,
        xp: json['xp'] as int? ?? 0,
        level: json['level'] as int? ?? 1,
        totalArtifacts: json['total_artifacts'] as int? ?? 0,
        totalGear: json['total_gear'] as int? ?? 0,
        zonesDiscovered: json['zones_discovered'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'tier': tier,
        'is_active': isActive,
        'created_at': createdAt,
        'xp': xp,
        'level': level,
        'total_artifacts': totalArtifacts,
        'total_gear': totalGear,
        'zones_discovered': zonesDiscovered,
      };

  @override
  List<Object?> get props => [
        id,
        username,
        email,
        tier,
        isActive,
        createdAt,
        xp,
        level,
        totalArtifacts,
        totalGear,
        zonesDiscovered
      ];
}

// ✅ Auth Response
class AuthResponse extends Equatable {
  final String token;
  final User user;
  final String? message;
  final String? timestamp;

  const AuthResponse({
    required this.token,
    required this.user,
    this.message,
    this.timestamp,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        token: json['token'] as String,
        user: User.fromJson(json['user'] as Map<String, dynamic>),
        message: json['message'] as String?,
        timestamp: json['timestamp'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'token': token,
        'user': user.toJson(),
        if (message != null) 'message': message,
        if (timestamp != null) 'timestamp': timestamp,
      };

  @override
  List<Object?> get props => [token, user, message, timestamp];
}

// ✅ API Error Response
class ApiError extends Equatable {
  final String error;
  final String? message;
  final String? details;

  const ApiError({
    required this.error,
    this.message,
    this.details,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) => ApiError(
        error: json['error'] as String,
        message: json['message'] as String?,
        details: json['details'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'error': error,
        if (message != null) 'message': message,
        if (details != null) 'details': details,
      };

  @override
  List<Object?> get props => [error, message, details];
}
