import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
import '../models/advanced_models.dart';
import '../models/location.dart';
import '../services/ai_service.dart';
import '../data/demo_data.dart';

class MapViewModel extends ChangeNotifier {
  final AIService _aiService;

  MapViewModel(this._aiService) {
    _loadInitialData();
    _initializeNotifications();
  }

  // Map Controller (flutter_map)
  final MapController _mapController = MapController();
  MapController get mapController => _mapController;

  // Default zoom and center
  static const double _defaultZoom = 13.0;
  final Location _initialCenter = const Location(18.5204, 73.8567);
  Location get initialCenter => _initialCenter;

  Location _currentCenter = const Location(18.5204, 73.8567);
  Location get currentCenter => _currentCenter;

  double _currentZoom = _defaultZoom;
  double get currentZoom => _currentZoom;

  // Markers for flutter_map
  final List<Marker> _markers = [];
  List<Marker> get markers => List.unmodifiable(_markers);

  // Polylines (route) for flutter_map
  final List<latlong.LatLng> _routePoints = [];
  List<latlong.LatLng> get routePoints => List.unmodifiable(_routePoints);

  // Blackspots (app model)
  List<AdvancedBlackspot> _blackspots = [];
  List<AdvancedBlackspot> get blackspots => List.unmodifiable(_blackspots);

  // UI State
  bool _isFullScreen = false;
  bool get isFullScreen => _isFullScreen;

  bool _showTraffic = false;
  bool get showTraffic => _showTraffic;

  Set<BlackspotSeverity> _visibleSeverities = {
    BlackspotSeverity.fatal,
    BlackspotSeverity.serious,
    BlackspotSeverity.minor,
  };
  Set<BlackspotSeverity> get visibleSeverities => _visibleSeverities;

  bool _showAllSeverities = true;
  bool get showAllSeverities => _showAllSeverities;

  // Current user location
  Location? _currentLocation;
  Location? get currentLocation => _currentLocation;

  // Destination location
  Location? _destinationLocation;
  Location? get destinationLocation => _destinationLocation;

  // Location tracking
  StreamSubscription<Position>? _positionStream;
  Timer? _proximityTimer;
  bool _isTrackingLocation = false;
  bool get isTrackingLocation => _isTrackingLocation;

  // Notifications
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  // Distance threshold for arrival notification (in meters)
  static const double _arrivalThreshold = 500.0;

  // Flag to prevent multiple notifications for same destination
  bool _hasNotifiedForCurrentDestination = false;

  // Initialization
  void _loadInitialData() {
    _blackspots = DemoData.getBlackspots();
    _createMarkers();
    _initializeLocation();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    
    await _notificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _initializeLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition();
      _currentLocation = Location(position.latitude, position.longitude);
      _createMarkers(); // Recreate markers to include current location
      notifyListeners();
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  // Start real-time location tracking
  void startLocationTracking() {
    if (_isTrackingLocation) return;
    
    _isTrackingLocation = true;
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      _currentLocation = Location(position.latitude, position.longitude);
      _createMarkers(); // Update markers with new current location
      _checkProximityToDestination();
      notifyListeners();
    });

    // Check proximity every 30 seconds
    _proximityTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkProximityToDestination();
    });

    notifyListeners();
  }

  // Stop location tracking
  void stopLocationTracking() {
    _isTrackingLocation = false;
    _positionStream?.cancel();
    _proximityTimer?.cancel();
    notifyListeners();
  }

  // Set destination location
  void setDestination(double latitude, double longitude) {
    _destinationLocation = Location(latitude, longitude);
    _hasNotifiedForCurrentDestination = false; // Reset notification flag
    _createMarkers(); // Update markers to include destination
    
    // Start location tracking when destination is set
    if (!_isTrackingLocation) {
      startLocationTracking();
    }
    
    notifyListeners();
  }

  // Clear destination
  void clearDestination() {
    _destinationLocation = null;
    _hasNotifiedForCurrentDestination = false; // Reset notification flag
    stopLocationTracking();
    _createMarkers(); // Update markers to remove destination
    notifyListeners();
  }

  // Check if user is within 500 meters of destination
  void _checkProximityToDestination() {
    if (_currentLocation == null || _destinationLocation == null || _hasNotifiedForCurrentDestination) return;

    double distance = _calculateDistance(
      _currentLocation!.latitude,
      _currentLocation!.longitude,
      _destinationLocation!.latitude,
      _destinationLocation!.longitude,
    );

    if (distance <= _arrivalThreshold) {
      _hasNotifiedForCurrentDestination = true; // Mark as notified
      _showArrivalNotification(distance);
      
      // Automatically clear destination after arrival notification with a success message
      Future.delayed(const Duration(seconds: 3), () {
        if (_destinationLocation != null) { // Check if destination still exists
          clearDestination();
        }
      });
    }
  }

  // Calculate distance between two points in meters
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  // Get formatted distance to destination
  String? getDistanceToDestination() {
    if (_currentLocation == null || _destinationLocation == null) return null;

    double distance = _calculateDistance(
      _currentLocation!.latitude,
      _currentLocation!.longitude,
      _destinationLocation!.latitude,
      _destinationLocation!.longitude,
    );

    if (distance < 1000) {
      return '${distance.round()} m';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)} km';
    }
  }

  // Show arrival notification
  Future<void> _showArrivalNotification(double distance) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'location_channel',
      'Location Notifications',
      channelDescription: 'Notifications for location-based alerts',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    await _notificationsPlugin.show(
      0,
      'Destination Reached! 🎯',
      'You arrived! (${distance.round()}m away) - Destination cleared automatically.',
      notificationDetails,
    );
  }

  void toggleAllSeverities() {
    _showAllSeverities = !_showAllSeverities;
    if (_showAllSeverities) {
      _visibleSeverities = {
        BlackspotSeverity.fatal,
        BlackspotSeverity.serious,
        BlackspotSeverity.minor,
      };
    } else {
      _visibleSeverities.clear();
    }
    _createMarkers();
    notifyListeners();
  }

  void toggleSeverityFilter(BlackspotSeverity severity) {
    if (_visibleSeverities.contains(severity)) {
      _visibleSeverities.remove(severity);
    } else {
      _visibleSeverities.add(severity);
    }
    _showAllSeverities = _visibleSeverities.length == 3;
    _createMarkers();
    notifyListeners();
  }

  Future<void> centerOnCurrentLocation() async {
    if (_currentLocation == null) await _initializeLocation();
    if (_currentLocation != null) moveMap(_currentLocation!, 16.0);
  }

  void moveMap(Location location, [double? zoom]) {
    _mapController.move(location.asLatLng, zoom ?? _currentZoom);
    _currentCenter = location;
    if (zoom != null) _currentZoom = zoom;
    notifyListeners();
  }

  void toggleFullScreen() {
    _isFullScreen = !_isFullScreen;
    notifyListeners();
  }

  void toggleTraffic() {
    _showTraffic = !_showTraffic;
    notifyListeners();
  }

  void _createMarkers() {
    _markers.clear();

    // Add current location marker
    if (_currentLocation != null) {
      _markers.add(
        Marker(
          point: latlong.LatLng(_currentLocation!.latitude, _currentLocation!.longitude),
          width: 50,
          height: 50,
          builder: (context) => _buildCurrentLocationMarker(),
        ),
      );
    }

    // Add destination marker
    if (_destinationLocation != null) {
      _markers.add(
        Marker(
          point: latlong.LatLng(_destinationLocation!.latitude, _destinationLocation!.longitude),
          width: 50,
          height: 50,
          builder: (context) => _buildDestinationMarker(),
        ),
      );
    }

    // Add blackspot markers
    for (final spot in _blackspots) {
      if (!_visibleSeverities.contains(spot.severity)) continue;
      final loc = Location(spot.latitude, spot.longitude);
      _markers.add(
        Marker(
          point: loc.asLatLng,
          width: 40,
          height: 40,
          builder: (context) => GestureDetector(
            onTap: () => onBlackspotTapped(spot),
            child: _buildMarkerIcon(spot.severity),
          ),
        ),
      );
    }
    notifyListeners();
  }

  Widget _buildCurrentLocationMarker() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Icon(
        Icons.my_location,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  Widget _buildDestinationMarker() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Icon(
        Icons.location_on,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  Widget _buildMarkerIcon(BlackspotSeverity severity) {
    final color = _getBlackspotColor(severity);
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withOpacity(0.95),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: const Icon(Icons.warning, color: Colors.white, size: 18),
    );
  }

  void onBlackspotTapped(AdvancedBlackspot blackspot) {
    moveMap(Location(blackspot.latitude, blackspot.longitude), 15.0);
  }

  Color _getBlackspotColor(BlackspotSeverity severity) {
    switch (severity) {
      case BlackspotSeverity.fatal:
        return const Color(0xFFDC2626);
      case BlackspotSeverity.serious:
        return const Color(0xFFF59E0B);
      case BlackspotSeverity.minor:
        return const Color(0xFF10B981);
    }
  }

  // Convert AIService RouteOption waypoints (app LatLng) into flutter_map/polyline points
  void buildRouteFromRouteOption(RouteOption option) {
    _routePoints.clear();
    for (final wp in option.waypoints) {
      _routePoints.add(latlong.LatLng(wp.latitude, wp.longitude));
    }
    notifyListeners();
  }

  // Plan route to destination (latitude, longitude)
  Future<void> planRoute(double destLat, double destLng) async {
    _routePoints.clear();
    _routePoints.addAll([]);

    _blackspots = DemoData.getBlackspots();

    _routePoints.addAll(
      _aiService
          .calculateRouteOptions(destLat, destLng)
          .fold<List<latlong.LatLng>>([], (acc, option) {
        if (acc.isEmpty && option.waypoints.isNotEmpty) {
          acc.addAll(option.waypoints.map((w) => latlong.LatLng(w.latitude, w.longitude)));
        }
        return acc;
      }),
    );

    notifyListeners();
  }

  // Search stub - centers on predefined cities for demo
  Future<void> searchLocation(String query) async {
    final q = query.toLowerCase();
    if (q.contains('mumbai')) {
      moveMap(const Location(19.0760, 72.8777), 12.0);
    } else if (q.contains('delhi')) {
      moveMap(const Location(28.6139, 77.2090), 12.0);
    }
  }

  List<AdvancedBlackspot> getNearbyBlackspots({double radiusKm = 2.0}) {
    final loc = _currentLocation ?? _currentCenter;
  return _aiService.getNearbyBlackspots(loc.latitude, loc.longitude, radiusKm: radiusKm)
        .where((b) => _visibleSeverities.contains(b.severity))
        .toList();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _proximityTimer?.cancel();
    super.dispose();
  }
}