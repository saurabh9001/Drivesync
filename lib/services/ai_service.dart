import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import '../models/advanced_models.dart';
import '../models/user_profile.dart';
import '../models/emergency_location_data.dart';
import '../data/demo_data.dart';
import 'emergency_sos_service.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal() {
    _initializeWithDemoData();
  }

  // Sensor data simulation
  Timer? _sensorTimer;
  final List<SensorData> _sensorHistory = [];
  final StreamController<SensorData> _sensorController = StreamController.broadcast();
  static const Duration _sensorBroadcastInterval = Duration(milliseconds: 300);
  DateTime? _lastSensorBroadcast;
  Timer? _sensorBroadcastTimer;
  SensorData? _pendingSensorData;
  
  // Weather data
  WeatherData _currentWeather = WeatherData(
    condition: 'clear',
    temperature: 28.0,
    humidity: 60.0,
    windSpeed: 15.0,
    visibility: 2000.0,
    precipitationProbability: 0.1,
  );

  // Enhanced blackspots with demo data
  List<AdvancedBlackspot> _blackspots = [];

  // Current location simulation (Maharashtra - Pune)
  double _currentLat = 18.5204;
  double _currentLng = 73.8567;
  double _currentSpeed = 45.0;
  double _currentDirection = 90.0;

  Stream<SensorData> get sensorStream => _sensorController.stream;
  List<SensorData> get sensorHistory => List.unmodifiable(_sensorHistory);
  WeatherData get currentWeather => _currentWeather;
  List<AdvancedBlackspot> get blackspots => List.unmodifiable(_blackspots);

  void _initializeWithDemoData() {
    _blackspots = DemoData.getBlackspots();
    _currentWeather = DemoData.getCurrentWeather();
  }

  // Real sensor data integration
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  StreamSubscription<Position>? _locationSubscription;
  
  // Multi-sensor integration flag
  bool _useRealSensors = true;
  bool get useRealSensors => _useRealSensors;
  
  void setUseRealSensors(bool useReal) {
    _useRealSensors = useReal;
    if (_useRealSensors) {
      stopSensorSimulation();
      startRealSensorMonitoring();
    } else {
      stopRealSensorMonitoring();
      startSensorSimulation();
    }
  }

  void startSensorSimulation() {
    if (_useRealSensors) return; // Don't simulate if using real sensors
    
    _sensorTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _simulateSensorData();
    });
  }

  void stopSensorSimulation() {
    _sensorTimer?.cancel();
    _sensorTimer = null;
  }

  // Start real sensor monitoring
  Future<void> startRealSensorMonitoring() async {
    if (!_useRealSensors) return;
    
    try {
      // Start accelerometer monitoring
      _accelerometerSubscription = accelerometerEventStream().listen((event) {
        _processRealAccelerometerData(event);
      });

      // Start gyroscope monitoring
      _gyroscopeSubscription = gyroscopeEventStream().listen((event) {
        _processRealGyroscopeData(event);
      });

      // Start GPS monitoring
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.whileInUse || 
          permission == LocationPermission.always) {
        _locationSubscription = Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 1,
          ),
        ).listen((position) {
          _processRealLocationData(position);
        });
      }
    } catch (e) {
      print('Error starting real sensors: $e');
      // Fallback to simulation if real sensors fail
      _useRealSensors = false;
      startSensorSimulation();
    }
  }

  void stopRealSensorMonitoring() {
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _locationSubscription?.cancel();
  }

  // Real sensor data processing
  double _lastAcceleration = 0.0;
  double _lastGyroX = 0.0;
  double _lastGyroY = 0.0;
  double _lastGyroZ = 0.0;
  Position? _lastPosition;

  void _processRealAccelerometerData(AccelerometerEvent event) {
    // Calculate total G-force magnitude, then subtract gravity
    double totalMagnitude = sqrt(pow(event.x, 2) + pow(event.y, 2) + pow(event.z, 2));
    _lastAcceleration = (totalMagnitude - 9.8).abs(); // Net acceleration excluding gravity
    _updateSensorDataFromRealSensors();
  }

  void _processRealGyroscopeData(GyroscopeEvent event) {
    _lastGyroX = event.x;
    _lastGyroY = event.y;
    _lastGyroZ = event.z;
    _updateSensorDataFromRealSensors();
  }

  void _processRealLocationData(Position position) {
    _lastPosition = position;
    _currentLat = position.latitude;
    _currentLng = position.longitude;
    _currentSpeed = position.speed * 3.6; // Convert m/s to km/h
    _currentDirection = position.heading;
    _updateSensorDataFromRealSensors();
  }

  void _updateSensorDataFromRealSensors() {
    if (_lastPosition == null) return; // Wait for GPS data
    
    final sensorData = SensorData(
      latitude: _currentLat,
      longitude: _currentLng,
      speed: _currentSpeed,
      direction: _currentDirection,
      acceleration: _lastAcceleration,
      gyroscopeX: _lastGyroX,
      gyroscopeY: _lastGyroY,
      gyroscopeZ: _lastGyroZ,
      timestamp: DateTime.now(),
    );

    // Keep only last 50 readings
    _sensorHistory.add(sensorData);
    if (_sensorHistory.length > 50) {
      _sensorHistory.removeAt(0);
    }

    _queueSensorData(sensorData);
  }

  void _simulateSensorData() {
    final random = Random();
    
    // Simulate slight movement in Maharashtra area
    _currentLat += (random.nextDouble() - 0.5) * 0.001;
    _currentLng += (random.nextDouble() - 0.5) * 0.001;
    
    // Keep within Maharashtra bounds (Pune region)
    _currentLat = _currentLat.clamp(18.45, 18.65);
    _currentLng = _currentLng.clamp(73.75, 73.95);
    
    // Simulate speed variations
    _currentSpeed += (random.nextDouble() - 0.5) * 10;
    _currentSpeed = _currentSpeed.clamp(0.0, 120.0);
    
    // Simulate direction changes
    _currentDirection += (random.nextDouble() - 0.5) * 20;
    _currentDirection = _currentDirection % 360;

    final sensorData = SensorData(
      latitude: _currentLat,
      longitude: _currentLng,
      speed: _currentSpeed,
      direction: _currentDirection,
      acceleration: (random.nextDouble() - 0.5) * 4.0,
      gyroscopeX: (random.nextDouble() - 0.5) * 2.0,
      gyroscopeY: (random.nextDouble() - 0.5) * 2.0,
      gyroscopeZ: (random.nextDouble() - 0.5) * 2.0,
      timestamp: DateTime.now(),
    );

    // Keep only last 50 readings
    _sensorHistory.add(sensorData);
    if (_sensorHistory.length > 50) {
      _sensorHistory.removeAt(0);
    }

    _queueSensorData(sensorData);
  }

  void _queueSensorData(SensorData sensorData) {
    final now = DateTime.now();
    _pendingSensorData = sensorData;

    if (_lastSensorBroadcast == null ||
        now.difference(_lastSensorBroadcast!) >= _sensorBroadcastInterval) {
      _emitSensorData(sensorData);
      return;
    }

    final remaining =
        _sensorBroadcastInterval - now.difference(_lastSensorBroadcast!);
    _sensorBroadcastTimer?.cancel();
    _sensorBroadcastTimer = Timer(remaining, () {
      if (_pendingSensorData != null) {
        _emitSensorData(_pendingSensorData!);
        _pendingSensorData = null;
      }
    });
  }

  void _emitSensorData(SensorData data) {
    _sensorController.add(data);
    _lastSensorBroadcast = DateTime.now();
  }

  // Advanced risk calculation with emergency SOS trigger
  double calculateAdvancedRiskScore(UserProfile? userProfile) {
    if (_sensorHistory.isEmpty) return 0.0;

    final currentData = _sensorHistory.last;
    
    final riskScore = AIProcessingEngine.calculateDynamicRiskScore(
      currentData,
      _sensorHistory,
      _blackspots,
      _currentWeather,
      userProfile ?? _getDefaultProfile(),
      DateTime.now(),
    );

    // Check for emergency conditions (high risk score >= 8.0)
    if (riskScore >= 8.0) {
      _checkAndTriggerEmergency(riskScore);
    }

    return riskScore;
  }

  DateTime? _lastEmergencyTrigger;
  bool _emergencyTriggered = false;

  // Check and trigger emergency with cooldown to prevent spam
  void _checkAndTriggerEmergency(double riskScore) {
    final now = DateTime.now();
    
    // Prevent multiple triggers within 5 minutes
    if (_lastEmergencyTrigger != null && 
        now.difference(_lastEmergencyTrigger!).inMinutes < 5) {
      return;
    }

    // Only trigger if risk is very high (9.0+) or sustained high risk
    if (riskScore >= 9.0 || (_emergencyTriggered == false && riskScore >= 8.5)) {
      _lastEmergencyTrigger = now;
      _emergencyTriggered = true;
      
      // Trigger emergency in background
      triggerEmergencyAlert().catchError((error) {
        print('Error triggering emergency alert: $error');
      });

      // Reset emergency flag after 10 minutes
      Timer(const Duration(minutes: 10), () {
        _emergencyTriggered = false;
      });
    }
  }

  // Get alert level
  AlertLevel getAlertLevel(double riskScore) {
    return AIProcessingEngine.classifyAlertLevel(riskScore);
  }

  // Get safety recommendations
  List<String> getSafetyRecommendations(double riskScore) {
    if (_sensorHistory.isEmpty) return ['Initializing sensors...'];

    final currentData = _sensorHistory.last;
    final nearbyBlackspots = _getNearbyBlackspots(currentData.latitude, currentData.longitude);
    
    return AIProcessingEngine.generateSafetyRecommendations(
      riskScore,
      _currentWeather,
      currentData,
      nearbyBlackspots,
    );
  }

  // Get nearby blackspots
  List<AdvancedBlackspot> getNearbyBlackspots(double lat, double lng, {double radiusKm = 2.0}) {
    return _blackspots.where((blackspot) {
      final distance = _calculateDistance(lat, lng, blackspot.latitude, blackspot.longitude);
      return distance <= radiusKm * 1000; // Convert km to meters
    }).toList();
  }

  List<AdvancedBlackspot> _getNearbyBlackspots(double lat, double lng) {
    return getNearbyBlackspots(lat, lng, radiusKm: 1.0);
  }

  // Route planning
  List<RouteOption> calculateRouteOptions(double destLat, double destLng) {
    if (_sensorHistory.isEmpty) return [];

    final current = _sensorHistory.last;
    final routes = <RouteOption>[];

    // Main route (direct)
    routes.add(RouteOption(
      id: 'main',
      name: 'Main Route',
      distance: _calculateDistance(current.latitude, current.longitude, destLat, destLng) / 1000,
      estimatedTime: const Duration(minutes: 15),
      safetyScore: 6.5,
      blackspotsOnRoute: _getBlackspotsOnRoute(current.latitude, current.longitude, destLat, destLng),
      waypoints: [
        LatLng(current.latitude, current.longitude),
        LatLng(destLat, destLng),
      ],
      description: 'Fastest route via main roads',
    ));

    // Safe alternative route
    routes.add(RouteOption(
      id: 'safe',
      name: 'Safe Route',
      distance: _calculateDistance(current.latitude, current.longitude, destLat, destLng) / 1000 * 1.2,
      estimatedTime: const Duration(minutes: 20),
      safetyScore: 8.5,
      blackspotsOnRoute: [],
      waypoints: [
        LatLng(current.latitude, current.longitude),
        LatLng(current.latitude + 0.005, current.longitude + 0.005),
        LatLng(destLat, destLng),
      ],
      description: 'Safer route avoiding blackspots',
    ));

    return routes;
  }

  // Simulate weather changes
  void simulateWeatherChange() {
    final random = Random();
    final conditions = ['clear', 'rain', 'fog', 'storm'];
    
    _currentWeather = WeatherData(
      condition: conditions[random.nextInt(conditions.length)],
      temperature: 20.0 + random.nextDouble() * 15.0,
      humidity: 40.0 + random.nextDouble() * 40.0,
      windSpeed: random.nextDouble() * 30.0,
      visibility: 500.0 + random.nextDouble() * 1500.0,
      precipitationProbability: random.nextDouble(),
    );
  }

  // Get current location
  LatLng? getCurrentLocation() {
    if (_sensorHistory.isEmpty) return null;
    final current = _sensorHistory.last;
    return LatLng(current.latitude, current.longitude);
  }

  // Emergency alert - now integrated with SOS
  Future<void> triggerEmergencyAlert() async {
    print('🚨 EMERGENCY ALERT TRIGGERED 🚨');
    print('Location: ${_currentLat}, ${_currentLng}');
    print('Time: ${DateTime.now()}');
    
    final sosService = EmergencySOSService();
    
    // Check if SOS is enabled and auto-trigger is enabled
    if (sosService.sosEnabled && sosService.autoTriggerEnabled) {
      try {
        // Create emergency location data
        final emergencyLocation = EmergencyLocationData(
          latitude: _currentLat,
          longitude: _currentLng,
          address: 'Accident detected by SafeRoute AI',
          timestamp: DateTime.now(),
        );

        // Trigger emergency SOS
        final success = await sosService.triggerEmergencySOS(
          userLocation: emergencyLocation,
          customMessage: '🚨 EMERGENCY ALERT: Accident detected by SafeRoute AI! I need immediate help. Current location: ${emergencyLocation.googleMapsUrl}',
        );

        if (success) {
          print('✅ Emergency SOS triggered successfully');
        } else {
          print('⚠️ Emergency SOS failed to trigger');
        }
      } catch (e) {
        print('❌ Error triggering emergency SOS: $e');
      }
    } else {
      print('⚠️ Emergency SOS not enabled or auto-trigger disabled');
    }
  }



  // Helper methods
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371000; // meters
    double dLat = (lat2 - lat1) * pi / 180;
    double dLng = (lng2 - lng1) * pi / 180;
    
    double a = sin(dLat / 2) * sin(dLat / 2) +
               cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
               sin(dLng / 2) * sin(dLng / 2);
    
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  List<AdvancedBlackspot> _getBlackspotsOnRoute(double startLat, double startLng, double endLat, double endLng) {
    // Simplified: return blackspots within 500m of the direct line
    return _blackspots.where((blackspot) {
      double distToStart = _calculateDistance(startLat, startLng, blackspot.latitude, blackspot.longitude);
      double distToEnd = _calculateDistance(endLat, endLng, blackspot.latitude, blackspot.longitude);
      double routeLength = _calculateDistance(startLat, startLng, endLat, endLng);
      
      return (distToStart + distToEnd) <= (routeLength + 500);
    }).toList();
  }

  // User profile persistence
  Future<UserProfile?> loadUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString('userProfile');
      if (profileJson != null) {
        return UserProfile.fromJson(jsonDecode(profileJson));
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
    return null;
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userProfile', jsonEncode(profile.toJson()));
    } catch (e) {
      print('Error saving user profile: $e');
    }
  }

  UserProfile _getDefaultProfile() {
    return DemoData.getDefaultUserProfile();
  }

  // Cleanup method
  void dispose() {
    _sensorTimer?.cancel();
    _sensorBroadcastTimer?.cancel();
    stopSensorSimulation();
    stopRealSensorMonitoring();
    _sensorController.close();
  }
}