import 'dart:math' as math;

class EmergencyLocationData {
  final double latitude;
  final double longitude;
  final String? address;
  final DateTime timestamp;
  final double? accuracy; // in meters
  final double? altitude; // in meters
  final double? speed; // in m/s
  final double? heading; // in degrees

  EmergencyLocationData({
    required this.latitude,
    required this.longitude,
    this.address,
    DateTime? timestamp,
    this.accuracy,
    this.altitude,
    this.speed,
    this.heading,
  }) : timestamp = timestamp ?? DateTime.now();

  factory EmergencyLocationData.fromJson(Map<String, dynamic> json) {
    return EmergencyLocationData(
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      address: json['address'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      accuracy: json['accuracy']?.toDouble(),
      altitude: json['altitude']?.toDouble(),
      speed: json['speed']?.toDouble(),
      heading: json['heading']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'timestamp': timestamp.toIso8601String(),
      'accuracy': accuracy,
      'altitude': altitude,
      'speed': speed,
      'heading': heading,
    };
  }

  // Get a Google Maps URL for this location
  String get googleMapsUrl {
    return 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
  }

  // Get a formatted address string
  String get formattedAddress {
    return address ?? 'Lat: ${latitude.toStringAsFixed(6)}, Lng: ${longitude.toStringAsFixed(6)}';
  }

  // Calculate distance between two locations in kilometers
  double distanceTo(EmergencyLocationData other) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    // Convert latitude and longitude from degrees to radians
    double lat1 = latitude * (3.141592653589793 / 180);
    double lon1 = longitude * (3.141592653589793 / 180);
    double lat2 = other.latitude * (3.141592653589793 / 180);
    double lon2 = other.longitude * (3.141592653589793 / 180);
    
    // Haversine formula
    double dLat = lat2 - lat1;
    double dLon = lon2 - lon1;
    double a = 
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c; // Distance in kilometers
  }

  // Validate GPS coordinates
  bool get isValid {
    if (latitude.isNaN || longitude.isNaN) return false;
    if (latitude.abs() > 90 || longitude.abs() > 180) return false;
    if (latitude == 0.0 && longitude == 0.0) return false;
    return true;
  }
}