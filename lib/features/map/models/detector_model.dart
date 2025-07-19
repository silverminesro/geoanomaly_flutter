import 'package:flutter/material.dart';

class Detector {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final int range; // 1-5 stars
  final int precision; // 1-5 stars
  final int battery; // 1-5 stars (battery life)
  final int tierRequired;
  final bool isOwned;
  final DetectorRarity rarity;
  final String? specialAbility;

  const Detector({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.range,
    required this.precision,
    required this.battery,
    required this.tierRequired,
    required this.isOwned,
    required this.rarity,
    this.specialAbility,
  });

  // Factory method from JSON
  factory Detector.fromJson(Map<String, dynamic> json) {
    return Detector(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      icon: _getIconFromString(json['icon']),
      range: json['range'],
      precision: json['precision'],
      battery: json['battery'],
      tierRequired: json['tier_required'],
      isOwned: json['is_owned'] ?? false,
      rarity: DetectorRarity.values.firstWhere(
        (r) => r.name == json['rarity'],
        orElse: () => DetectorRarity.common,
      ),
      specialAbility: json['special_ability'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon.codePoint.toString(),
      'range': range,
      'precision': precision,
      'battery': battery,
      'tier_required': tierRequired,
      'is_owned': isOwned,
      'rarity': rarity.name,
      'special_ability': specialAbility,
    };
  }

  // Helper method for icons
  static IconData _getIconFromString(String iconString) {
    switch (iconString) {
      case 'search':
        return Icons.search;
      case 'scanner':
        return Icons.scanner;
      case 'memory':
        return Icons.memory;
      case 'radar':
        return Icons.radar;
      case 'sensors':
        return Icons.sensors;
      case 'satellite':
        return Icons.satellite;
      default:
        return Icons.search;
    }
  }

  // Default detectors that every player gets
  static final List<Detector> defaultDetectors = [
    Detector(
      id: 'basic_metal',
      name: 'Basic Metal Detector',
      description:
          'Simple handheld detector. Limited range but reliable for basic metal detection.',
      icon: Icons.search,
      range: 2,
      precision: 2,
      battery: 4,
      tierRequired: 0,
      isOwned: true,
      rarity: DetectorRarity.common,
      specialAbility: 'Detects metal objects within 10m radius',
    ),
    Detector(
      id: 'ground_scanner',
      name: 'Ground Penetrating Radar',
      description:
          'Advanced ground scanning technology. Better depth and precision.',
      icon: Icons.scanner,
      range: 3,
      precision: 4,
      battery: 3,
      tierRequired: 1,
      isOwned: false,
      rarity: DetectorRarity.uncommon,
      specialAbility: 'Shows depth information and material type hints',
    ),
    Detector(
      id: 'quantum_detector',
      name: 'Quantum Field Detector',
      description:
          'Cutting-edge quantum technology. Extremely precise artifact detection.',
      icon: Icons.memory,
      range: 5,
      precision: 5,
      battery: 2,
      tierRequired: 3,
      isOwned: false,
      rarity: DetectorRarity.legendary,
      specialAbility: 'Pinpoint accuracy with artifact rarity prediction',
    ),
    Detector(
      id: 'electromagnetic',
      name: 'EM Field Scanner',
      description:
          'Detects electromagnetic anomalies. Great for electronic artifacts.',
      icon: Icons.sensors,
      range: 4,
      precision: 3,
      battery: 3,
      tierRequired: 2,
      isOwned: false,
      rarity: DetectorRarity.rare,
      specialAbility: 'Specializes in electronic and energy-based artifacts',
    ),
  ];

  // Copy with method for updates
  Detector copyWith({
    String? id,
    String? name,
    String? description,
    IconData? icon,
    int? range,
    int? precision,
    int? battery,
    int? tierRequired,
    bool? isOwned,
    DetectorRarity? rarity,
    String? specialAbility,
  }) {
    return Detector(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      range: range ?? this.range,
      precision: precision ?? this.precision,
      battery: battery ?? this.battery,
      tierRequired: tierRequired ?? this.tierRequired,
      isOwned: isOwned ?? this.isOwned,
      rarity: rarity ?? this.rarity,
      specialAbility: specialAbility ?? this.specialAbility,
    );
  }

  @override
  String toString() => 'Detector(id: $id, name: $name, owned: $isOwned)';
}

enum DetectorRarity {
  common('Common', Color(0xFF9E9E9E)),
  uncommon('Uncommon', Color(0xFF4CAF50)),
  rare('Rare', Color(0xFF2196F3)),
  epic('Epic', Color(0xFF9C27B0)),
  legendary('Legendary', Color(0xFFFF9800));

  const DetectorRarity(this.displayName, this.color);
  final String displayName;
  final Color color;
}
