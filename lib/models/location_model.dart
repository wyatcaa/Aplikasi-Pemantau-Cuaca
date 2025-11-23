// class LocationModel {
//   final int? id;
//   final String name;
//   final double latitude;
//   final double longitude;
//   final String country;
//   final String timezone;

//   LocationModel({
//     this.id,
//     required this.name,
//     required this.latitude,
//     required this.longitude,
//     required this.country,
//     required this.timezone,
//   });

//   factory LocationModel.fromJson(Map<String, dynamic> json) {
//     return LocationModel(
//       id: json['id'] ?? 0,
//       name: json['name'] ?? '',
//       latitude: json['latitude'] ?? 0.0,
//       longitude: json['longitude'] ?? 0.0,
//       country: json['country'] ?? '',
//       timezone: json['timezone'] ?? 'UTC',
//     );
//   }

//   // Untuk SQLite INSERT/UPDATE
//   Map<String, dynamic> toMap() {
//     return {
//       'id': id, // boleh null saat insert awal
//       'name': name,
//       'latitude': latitude,
//       'longitude': longitude,
//       'country': country,
//       'timezone': timezone,
//     };
//   }

//   // Untuk baca dari SQLite
//   factory LocationModel.fromMap(Map<String, dynamic> map) {
//     return LocationModel(
//       id: map['id'],
//       name: map['name'],
//       latitude: map['latitude'],
//       longitude: map['longitude'],
//       country: map['country'],
//       timezone: map['timezone'],
//     );
//   }
// }

class LocationModel {
  final int? id;
  final String name;
  final double latitude;
  final double longitude;
  final String country;    // Bisa country_code dari API
  final String timezone;

  LocationModel({
    this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.country,
    required this.timezone,
  });

  // ===========================
  // 1. Untuk API Geocoding (search)
  // ===========================
  factory LocationModel.fromGeocodingJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'],
      name: json['name'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      country: json['country_code'] ?? '',
      timezone: json['timezone'] ?? 'UTC',
    );
  }

  // ===========================
  // 2. Untuk SQLite
  // ===========================
  factory LocationModel.fromMap(Map<String, dynamic> map) {
    return LocationModel(
      id: map['id'],
      name: map['name'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      country: map['country'] ?? '',
      timezone: map['timezone'] ?? 'UTC',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'country': country,
      'timezone': timezone,
    };
  }

  // ===========================
  // 3. Untuk Weather API / GPS user
  // Bisa langsung pakai constructor
  // ===========================
  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'],
      name: json['name'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      country: json['country'] ?? '',
      timezone: json['timezone'] ?? 'UTC',
    );
  }
}
