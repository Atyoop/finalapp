import 'dart:math' as math;

class PharmacyModel {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String address;
  final double rating;
  final bool isOpen;
  final int distanceMeters;

  PharmacyModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.rating,
    required this.isOpen,
    required this.distanceMeters,
  });

  factory PharmacyModel.fromOverpassJson(
    Map<String, dynamic> json, {
    double? userLat,
    double? userLng,
  }) {
    final tags = json['tags'] as Map<String, dynamic>? ?? {};
    final lat = (json['lat'] as num?)?.toDouble() ?? 0.0;
    final lon = (json['lon'] as num?)?.toDouble() ?? 0.0;

    final address = tags['addr:full'] ??
        tags['addr:street'] ??
        tags['display_name'] ??
        '';

    int distance = 0;
    if (userLat != null && userLng != null) {
      distance = _calculateDistance(userLat, userLng, lat, lon);
    }

    return PharmacyModel(
      id: json['id'].toString(),
      name: tags['name'] ?? 'Unknown Pharmacy',
      latitude: lat,
      longitude: lon,
      address: address.toString(),
      rating: 0.0,
      isOpen: false,
      distanceMeters: distance,
    );
  }

  static int _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = _sinSquared(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) * _sinSquared(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return (R * c).round();
  }

  static double _toRadians(double deg) => deg * math.pi / 180;
  static double _sinSquared(double x) {
    final s = math.sin(x);
    return s * s;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
    'address': address,
    'rating': rating,
    'isOpen': isOpen,
    'distanceMeters': distanceMeters,
  };

  factory PharmacyModel.fromCacheJson(Map<String, dynamic> json) {
    return PharmacyModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown Pharmacy',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      address: json['address'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      isOpen: json['isOpen'] as bool? ?? false,
      distanceMeters: json['distanceMeters'] as int? ?? 0,
    );
  }

  String get formattedDistance {
    if (distanceMeters < 1000) {
      return '${distanceMeters}m';
    }
    final km = distanceMeters / 1000;
    return '${km.toStringAsFixed(1)}km';
  }
}
