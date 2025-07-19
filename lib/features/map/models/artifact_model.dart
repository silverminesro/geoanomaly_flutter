class DetectableItem {
  final String id;
  final String name;
  final String type;
  final String rarity;
  final double latitude;
  final double longitude;
  final Map<String, dynamic> properties;
  final bool isActive;

  DetectableItem({
    required this.id,
    required this.name,
    required this.type,
    required this.rarity,
    required this.latitude,
    required this.longitude,
    required this.properties,
    required this.isActive,
  });

  factory DetectableItem.fromJson(Map<String, dynamic> json) {
    final location = json['location'] ?? {};
    return DetectableItem(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      rarity: json['rarity'] ?? 'common',
      latitude: (location['latitude'] as num).toDouble(),
      longitude: (location['longitude'] as num).toDouble(),
      properties: json['properties'] ?? {},
      isActive: json['is_active'] ?? true,
    );
  }
}
