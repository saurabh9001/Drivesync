import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/emergency_location_data.dart';
import 'emergency_sos_service.dart';

enum RoadConditionLevel {
  smooth(1, "Smooth Road", "Road conditions are excellent"),
  moderate(2, "Moderate Bumps", "Some road irregularities detected"),
  rough(3, "Rough Road", "Poor road conditions - drive carefully");

  const RoadConditionLevel(this.level, this.title, this.description);
  final int level;
  final String title;
  final String description;
}

class RoadConditionDetector extends ChangeNotifier {
  static const double SMOOTH_THRESHOLD = 1.2; // Level 1: Smooth road
  static const double MODERATE_THRESHOLD = 2.5; // Level 2: Moderate bumps
  static const double ROUGH_THRESHOLD = 4.0; // Level 3: Rough road
  static const double EMERGENCY_SOS_THRESHOLD = 7.0; // EMERGENCY: Immediate SOS trigger
  
  static const int SAMPLE_WINDOW = 50; // Number of samples to analyze
  static const Duration NOTIFICATION_COOLDOWN = Duration(minutes: 2);
  
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  final List<double> _accelerationSamples = [];
  RoadConditionLevel _currentCondition = RoadConditionLevel.smooth;
  DateTime _lastNotificationTime = DateTime.now().subtract(Duration(hours: 1));
  
  // Callbacks
  Function(RoadConditionLevel)? onRoadConditionChanged;
  Function(String)? onSuggestionGenerated;
  
  // Statistics
  double _averageRoughness = 0.0;
  double _maxRoughness = 0.0;
  int _roughPatchesCount = 0;
  bool _isMonitoring = false;
  bool _isWebPlatform = false;
  Timer? _webSimulationTimer;
  
  // Emergency SOS tracking
  DateTime? _lastEmergencyTrigger;
  static const Duration _emergencyCooldown = Duration(seconds: 30);

  // Getters
  RoadConditionLevel get currentCondition => _currentCondition;
  bool get isMonitoring => _isMonitoring;
  double get averageVibration => _averageRoughness;
  List<double> get accelerometerData => List.unmodifiable(_accelerationSamples);

  RoadConditionDetector({
    this.onRoadConditionChanged,
    this.onSuggestionGenerated,
  });

  /// Get user-configured G-force threshold from SharedPreferences
  Future<double> _getUserGForceThreshold() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('g_force_threshold') ?? 28.0; // Default to 28.0G (4X original)
  }

  /// Check if SOS is enabled in user settings
  Future<bool> _isSosEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('sos_enabled') ?? false;
  }

  /// Initialize the road condition detector
  Future<void> initialize() async {
    // Check if running on web platform
    _isWebPlatform = kIsWeb;
    
    if (_isWebPlatform) {
      print('Road Condition Detector: Running on web platform - using simulation mode');
      await _initializeWebFallback();
    } else {
      await _initializeNotifications();
    }
    
    _startAccelerometerMonitoring();
  }

  /// Initialize local notifications
  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    
    await _notificationsPlugin.initialize(initializationSettings);
  }

  /// Initialize web fallback with simulated data
  Future<void> _initializeWebFallback() async {
    print('Road Condition Detector: Initializing web fallback mode');
    // Web notifications would require different setup
    // For now, we'll just use console logging
  }

  /// Start monitoring accelerometer for road condition detection
  void _startAccelerometerMonitoring() {
    _isMonitoring = true;
    
    if (_isWebPlatform) {
      _startWebSimulation();
    } else {
      try {
        _accelerometerSubscription = accelerometerEventStream().listen(
          (AccelerometerEvent event) {
            _processAccelerometerData(event);
          },
          onError: (error) {
            print('Road Condition Detector: Accelerometer error - $error');
            _startWebSimulation(); // Fallback to simulation
          },
        );
      } catch (e) {
        print('Road Condition Detector: Failed to access accelerometer - $e');
        _startWebSimulation(); // Fallback to simulation
      }
    }
    
    notifyListeners();
  }

  /// Start web simulation for demo purposes
  void _startWebSimulation() {
    print('Road Condition Detector: Starting web simulation mode');
    
    _webSimulationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      // Simulate different road conditions with random data
      final random = Random();
      final simulationModes = [
        {'condition': RoadConditionLevel.smooth, 'baseValue': 0.8, 'variance': 0.3},
        {'condition': RoadConditionLevel.moderate, 'baseValue': 2.0, 'variance': 0.5},
        {'condition': RoadConditionLevel.rough, 'baseValue': 4.5, 'variance': 1.0},
      ];
      
      final mode = simulationModes[random.nextInt(simulationModes.length)];
      final baseValue = mode['baseValue'] as double;
      final variance = mode['variance'] as double;
      
      // Generate simulated accelerometer data
      for (int i = 0; i < 10; i++) {
        final simulatedMagnitude = baseValue + (random.nextDouble() - 0.5) * variance;
        _accelerationSamples.add(simulatedMagnitude.abs());
        
        if (_accelerationSamples.length > SAMPLE_WINDOW) {
          _accelerationSamples.removeAt(0);
        }
      }
      
      if (_accelerationSamples.length >= SAMPLE_WINDOW) {
        _analyzeRoadCondition();
      }
    });
  }

  /// Process accelerometer data and detect road conditions
  void _processAccelerometerData(AccelerometerEvent event) async {
    // Calculate total magnitude first, then remove gravity
    double totalMagnitude = sqrt(pow(event.x, 2) + pow(event.y, 2) + pow(event.z, 2));
    double magnitude = (totalMagnitude - 9.8).abs(); // Net acceleration excluding gravity
    
    // Check if SOS is enabled before processing
    final sosEnabled = await _isSosEnabled();
    if (!sosEnabled) {
      print('⚠️ Road condition G-Force detected but SOS is DISABLED - ignoring ${magnitude.toStringAsFixed(2)}G');
      return; // Exit early if SOS is disabled
    }
    
    // Get user-configured threshold
    final userThreshold = await _getUserGForceThreshold();
    
    // EMERGENCY SOS TRIGGER - For extremely high G-force spikes using user threshold
    if (magnitude > userThreshold) {
      print('🚨🚨🚨 EMERGENCY G-FORCE DETECTED: ${magnitude.toStringAsFixed(2)}G (User Threshold: ${userThreshold.toStringAsFixed(1)}G)');
      print('🚨 ROAD CONDITION DETECTOR TRIGGERING IMMEDIATE EMERGENCY SOS - SOS ENABLED ✅');
      _triggerEmergencySOS(magnitude);
    }
    
    // Add to sample window
    _accelerationSamples.add(magnitude);
    
    // Keep only recent samples
    if (_accelerationSamples.length > SAMPLE_WINDOW) {
      _accelerationSamples.removeAt(0);
    }
    
    // Analyze road condition if we have enough samples
    if (_accelerationSamples.length >= SAMPLE_WINDOW) {
      _analyzeRoadCondition();
    }
  }

  /// Analyze road condition based on acceleration patterns
  void _analyzeRoadCondition() {
    if (_accelerationSamples.isEmpty) return;
    
    // Calculate statistics
    double sum = _accelerationSamples.reduce((a, b) => a + b);
    double average = sum / _accelerationSamples.length;
    
    // Calculate standard deviation (roughness indicator)
    double variance = _accelerationSamples
        .map((value) => pow(value - average, 2))
        .reduce((a, b) => a + b) / _accelerationSamples.length;
    double standardDeviation = sqrt(variance);
    
    // Update statistics
    _averageRoughness = standardDeviation;
    _maxRoughness = _accelerationSamples.reduce(max);
    
    // Determine road condition level
    RoadConditionLevel newCondition = _determineRoadCondition(standardDeviation);
    
    // Check if condition changed significantly
    if (newCondition != _currentCondition) {
      _currentCondition = newCondition;
      _handleRoadConditionChange(newCondition);
      notifyListeners(); // Notify UI about the change
    }
  }

  /// Determine road condition based on roughness
  RoadConditionLevel _determineRoadCondition(double roughness) {
    if (roughness <= SMOOTH_THRESHOLD) {
      return RoadConditionLevel.smooth;
    } else if (roughness <= MODERATE_THRESHOLD) {
      return RoadConditionLevel.moderate;
    } else {
      _roughPatchesCount++;
      return RoadConditionLevel.rough;
    }
  }

  /// Handle road condition changes
  void _handleRoadConditionChange(RoadConditionLevel condition) {
    // Trigger callback
    onRoadConditionChanged?.call(condition);
    
    // Generate driving suggestion
    String suggestion = _generateDrivingSuggestion(condition);
    onSuggestionGenerated?.call(suggestion);
    
    // Send notification if enough time has passed
    if (DateTime.now().difference(_lastNotificationTime) > NOTIFICATION_COOLDOWN) {
      _sendRoadConditionNotification(condition, suggestion);
      _lastNotificationTime = DateTime.now();
    }
  }

  /// Generate driving suggestions based on road condition
  String _generateDrivingSuggestion(RoadConditionLevel condition) {
    switch (condition) {
      case RoadConditionLevel.smooth:
        return "Road conditions are excellent. Maintain safe driving speed.";
      
      case RoadConditionLevel.moderate:
        return "Some road bumps detected. Reduce speed slightly and maintain safe distance.";
      
      case RoadConditionLevel.rough:
        return "⚠️ Poor road conditions ahead! Reduce speed significantly and avoid sudden movements.";
    }
  }

  /// Send road condition notification
  Future<void> _sendRoadConditionNotification(RoadConditionLevel condition, String suggestion) async {
    if (_isWebPlatform) {
      // For web platform, log to console (could be extended to show web notifications)
      print('🛣️ Road Condition Alert: ${condition.title} - $suggestion');
      _lastNotificationTime = DateTime.now();
      return;
    }
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'road_condition_channel',
      'Road Conditions',
      channelDescription: 'Notifications about road conditions',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    
    const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);
    
    // Choose notification icon based on condition level
    String emoji = condition == RoadConditionLevel.rough ? "⚠️" : 
                  condition == RoadConditionLevel.moderate ? "⚡" : "✅";
    
    await _notificationsPlugin.show(
      condition.level,
      '$emoji ${condition.title}',
      suggestion,
      notificationDetails,
    );
    
    _lastNotificationTime = DateTime.now();
  }

  /// Get current road condition statistics
  Map<String, dynamic> getRoadConditionStats() {
    return {
      'currentCondition': _currentCondition.title,
      'currentLevel': _currentCondition.level,
      'averageRoughness': _averageRoughness.toStringAsFixed(2),
      'maxRoughness': _maxRoughness.toStringAsFixed(2),
      'roughPatchesCount': _roughPatchesCount,
      'samplesCollected': _accelerationSamples.length,
    };
  }

  /// Update detection thresholds (for calibration)
  void updateThresholds({
    double? smoothThreshold,
    double? moderateThreshold,
    double? roughThreshold,
  }) {
    // Note: You would need to make the thresholds non-const to use this
    // For now, this is a placeholder for future customization
  }

  /// Get road condition recommendations
  List<String> getRoadConditionRecommendations() {
    List<String> recommendations = [];
    
    switch (_currentCondition) {
      case RoadConditionLevel.smooth:
        recommendations.addAll([
          "✅ Optimal driving conditions",
          "🚗 Safe to maintain normal speed",
          "⛽ Good for fuel efficiency",
        ]);
        break;
        
      case RoadConditionLevel.moderate:
        recommendations.addAll([
          "⚡ Minor road irregularities",
          "🐌 Consider reducing speed by 10-15%",
          "🔧 Check tire pressure regularly",
          "👀 Stay alert for potholes",
        ]);
        break;
        
      case RoadConditionLevel.rough:
        recommendations.addAll([
          "⚠️ Poor road conditions detected",
          "🐌 Reduce speed by 20-30%",
          "🚗 Increase following distance",
          "🛠️ Avoid sudden braking or steering",
          "💡 Consider alternate route if available",
        ]);
        break;
    }
    
    return recommendations;
  }

  /// Reset statistics
  void resetStats() {
    _roughPatchesCount = 0;
    _averageRoughness = 0.0;
    _maxRoughness = 0.0;
    _accelerationSamples.clear();
  }

  /// Trigger emergency SOS for extremely high G-force (10G+)
  Future<void> _triggerEmergencySOS(double magnitude) async {
    // Check cooldown to prevent spam
    final now = DateTime.now();
    if (_lastEmergencyTrigger != null &&
        now.difference(_lastEmergencyTrigger!) < _emergencyCooldown) {
      print('⏳ Emergency SOS cooldown active — ignoring duplicate trigger.');
      return;
    }

    _lastEmergencyTrigger = now;
    
    print('🚨 ROAD CONDITION EMERGENCY: ${magnitude.toStringAsFixed(1)}G spike detected!');
    print('📱 Initiating automatic emergency SOS from road condition detector...');

    try {
      final sosService = EmergencySOSService();
      await sosService.setSosEnabled(true);
      await sosService.setAutoTriggerEnabled(true);

      // Get real GPS location for emergency
      Position? currentPosition;
      try {
        currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(const Duration(seconds: 10));
      } catch (e) {
        print('⚠️ Failed to get GPS location for emergency: $e');
      }

      final emergencyLocation = EmergencyLocationData(
        latitude: currentPosition?.latitude ?? 0.0,
        longitude: currentPosition?.longitude ?? 0.0,
        accuracy: currentPosition?.accuracy ?? 0.0,
        altitude: currentPosition?.altitude ?? 0.0,
        speed: currentPosition?.speed ?? 0.0,
        heading: currentPosition?.heading ?? 0.0,
        address: currentPosition != null 
            ? 'Lat: ${currentPosition.latitude.toStringAsFixed(5)}, Lng: ${currentPosition.longitude.toStringAsFixed(5)}'
            : 'GPS location unavailable - Emergency G-force spike detected',
        timestamp: currentPosition?.timestamp ?? DateTime.now(),
      );

      final success = await sosService.triggerEmergencySOS(
        userLocation: emergencyLocation,
        customMessage: '🚨 EXTREME G-FORCE EMERGENCY! ${magnitude.toStringAsFixed(1)}G impact detected by DriveSync! I need immediate help at ${emergencyLocation.formattedAddress}. GPS Location: ${emergencyLocation.googleMapsUrl}',
      );

      if (success) {
        print('✅ Emergency SOS triggered successfully from road condition detector');
      } else {
        print('⚠️ Emergency SOS failed from road condition detector');
      }
    } catch (e) {
      print('❌ Error triggering emergency SOS from road condition: $e');
    }
  }

  /// Stop monitoring
  @override
  void dispose() {
    _isMonitoring = false;
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
    _webSimulationTimer?.cancel();
    _webSimulationTimer = null;
    super.dispose();
  }
}

/// Extension for easy condition comparison
extension RoadConditionComparison on RoadConditionLevel {
  bool isWorseThan(RoadConditionLevel other) => level > other.level;
  bool isBetterThan(RoadConditionLevel other) => level < other.level;
  bool isEqualTo(RoadConditionLevel other) => level == other.level;
}