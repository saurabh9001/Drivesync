import 'package:latlong2/latlong.dart' as latlong;
import '../models/advanced_models.dart' as advanced_models;

// Common location model used across the app
class Location {
  final double latitude;
  final double longitude;

  const Location(this.latitude, this.longitude);

  // Convert to latlong2 LatLng
  latlong.LatLng toLatLng() => latlong.LatLng(latitude, longitude);

  // Create from latlong2 LatLng
  static Location fromLatLng(latlong.LatLng latLng) => Location(latLng.latitude, latLng.longitude);

  // Create from app's Advanced LatLng (advanced_models.LatLng)
  static Location fromAdvancedLatLng(advanced_models.LatLng latLng) => Location(latLng.latitude, latLng.longitude);

  // Convert to app advanced LatLng
  advanced_models.LatLng toAdvancedLatLng() => advanced_models.LatLng(latitude, longitude);
}

// Convert Location objects to latlong2 LatLng
extension LocationExtensions on Location {
  latlong.LatLng get asLatLng => toLatLng();
}

// Convert latlong2 LatLng to Location objects
extension LatLngExtensions on latlong.LatLng {
  Location get asLocation => Location(latitude, longitude);
}