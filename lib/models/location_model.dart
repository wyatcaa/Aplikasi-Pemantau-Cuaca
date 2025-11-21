class LocationModel {
  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final String country;
  final String timezone;

  LocationModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.country,
    required this.timezone,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      latitude: json['latitude'] ?? 0.0,
      longitude: json['longitude'] ?? 0.0,
      country: json['country'] ?? '',
      timezone: json['timezone'] ?? 'UTC',
    );
  }
}
