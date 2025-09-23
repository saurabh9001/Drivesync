import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:geolocator/geolocator.dart';
import '../models/advanced_models.dart';
import '../models/location.dart';
import '../services/ai_service.dart';
import '../data/demo_data.dart';

class MapViewModel extends ChangeNotifier {
  final AIService _aiService;

  MapViewModel(this._aiService) {
    _loadInitialData();
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

  // Initialization
  void _loadInitialData() {
    _blackspots = DemoData.getBlackspots();
    _createMarkers();
    _initializeLocation();
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
      notifyListeners();
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
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
    // MapController doesn't require explicit dispose for flutter_map
    super.dispose();
  }
}