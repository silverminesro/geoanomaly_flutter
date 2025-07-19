class DetectableItem {
  final String id;
  final String name;
  final String type;
  final String rarity;
  final String material;
  final double latitude;
  final double longitude;
  final int value;
  final String description;
  final bool canBeDetected;
  final double detectionDifficulty;

  // Runtime calculated properties
  final double? distanceFromPlayer;
  final double? bearingFromPlayer;
  final String? compassDirection;

  DetectableItem({
    required this.id,
    required this.name,
    required this.type,
    required this.rarity,
    required this.material,
    required this.latitude,
    required this.longitude,
    required this.value,
    required this.description,
    this.canBeDetected = true,
    this.detectionDifficulty = 1.0,
    this.distanceFromPlayer,
    this.bearingFromPlayer,
    this.compassDirection,
  });

  factory DetectableItem.fromJson(Map<String, dynamic> json) {
    // ✅ FIX: Better handling of nested location data
    double lat = 0.0;
    double lng = 0.0;

    if (json['location'] != null) {
      if (json['location'] is Map) {
        lat = (json['location']['latitude'] as num?)?.toDouble() ?? 0.0;
        lng = (json['location']['longitude'] as num?)?.toDouble() ?? 0.0;
      }
    } else {
      // Fallback: check for direct lat/lng fields
      lat = (json['latitude'] as num?)?.toDouble() ?? 0.0;
      lng = (json['longitude'] as num?)?.toDouble() ?? 0.0;
    }

    return DetectableItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Item',
      type: json['type']?.toString() ?? 'artifact',
      rarity: json['rarity']?.toString() ?? 'common',
      material: json['material']?.toString() ?? 'metal',
      latitude: lat,
      longitude: lng,
      value: (json['value'] as num?)?.toInt() ?? 0,
      description: json['description']?.toString() ?? '',
      canBeDetected: json['can_be_detected'] ?? true,
      detectionDifficulty:
          (json['detection_difficulty'] as num?)?.toDouble() ?? 1.0,
      distanceFromPlayer: (json['distance_from_player'] as num?)?.toDouble(),
      bearingFromPlayer: (json['bearing_from_player'] as num?)?.toDouble(),
      compassDirection: json['compass_direction']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'rarity': rarity,
      'material': material,
      'location': {
        'latitude': latitude,
        'longitude': longitude,
      },
      'value': value,
      'description': description,
      'can_be_detected': canBeDetected,
      'detection_difficulty': detectionDifficulty,
      'distance_from_player': distanceFromPlayer,
      'bearing_from_player': bearingFromPlayer,
      'compass_direction': compassDirection,
    };
  }

  // Helper getters that DetectorScreen needs
  String get rarityDisplayName {
    switch (rarity.toLowerCase()) {
      case 'common':
        return 'Common';
      case 'uncommon':
        return 'Uncommon';
      case 'rare':
        return 'Rare';
      case 'epic':
        return 'Epic';
      case 'legendary':
        return 'Legendary';
      default:
        return 'Unknown';
    }
  }

  String get materialDisplayName {
    switch (material.toLowerCase()) {
      case 'metal':
        return 'Metal';
      case 'stone':
        return 'Stone';
      case 'crystal':
        return 'Crystal';
      case 'organic':
        return 'Organic';
      case 'magical':
        return 'Magical';
      case 'electronic':
        return 'Electronic';
      case 'ceramic':
        return 'Ceramic';
      case 'bone':
        return 'Bone';
      case 'wood':
        return 'Wood';
      default:
        return material.toUpperCase();
    }
  }

  String get distanceDisplay {
    if (distanceFromPlayer == null) return 'Unknown';

    final distance = distanceFromPlayer!;
    if (distance < 1.0) {
      return '${(distance * 100).toInt()}cm';
    } else if (distance < 1000.0) {
      return '${distance.toInt()}m';
    } else {
      return '${(distance / 1000.0).toStringAsFixed(1)}km';
    }
  }

  // ✅ FIX: Add compass direction fallback
  String get compassDirectionDisplay {
    return compassDirection ?? bearingToCompass(bearingFromPlayer ?? 0.0);
  }

  // ✅ NEW: Convert bearing to compass direction
  String bearingToCompass(double bearing) {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final index = ((bearing + 22.5) / 45).floor() % 8;
    return directions[index];
  }

  bool get isVeryClose =>
      distanceFromPlayer != null && distanceFromPlayer! <= 2.0;
  bool get isClose => distanceFromPlayer != null && distanceFromPlayer! <= 10.0;
  bool get hasValidLocation => latitude != 0.0 || longitude != 0.0;

  DetectableItem copyWith({
    String? id,
    String? name,
    String? type,
    String? rarity,
    String? material,
    double? latitude,
    double? longitude,
    int? value,
    String? description,
    bool? canBeDetected,
    double? detectionDifficulty,
    double? distanceFromPlayer,
    double? bearingFromPlayer,
    String? compassDirection,
  }) {
    return DetectableItem(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      rarity: rarity ?? this.rarity,
      material: material ?? this.material,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      value: value ?? this.value,
      description: description ?? this.description,
      canBeDetected: canBeDetected ?? this.canBeDetected,
      detectionDifficulty: detectionDifficulty ?? this.detectionDifficulty,
      distanceFromPlayer: distanceFromPlayer ?? this.distanceFromPlayer,
      bearingFromPlayer: bearingFromPlayer ?? this.bearingFromPlayer,
      compassDirection: compassDirection ?? this.compassDirection,
    );
  }

  @override
  String toString() =>
      'DetectableItem(id: $id, name: $name, type: $type, rarity: $rarity)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DetectableItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
