import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/emergency_location_data.dart';

enum AccidentSeverity {
  none(0, "Normal Driving", "All systems normal"),
  minor(1, "Minor Impact", "Possible minor collision detected"),
  moderate(2, "Moderate Accident", "Significant impact detected - checking status"),
  severe(3, "Severe Accident", "EMERGENCY: Severe accident detected - calling help");

  const AccidentSeverity(this.level, this.title, this.description);
  final int level;
  final String title;
  final String description;
}

class MultiSensorAccidentDetector extends ChangeNotifier {
  // Thresholds for different sensors - REALISTIC FOR ACTUAL ACCIDENTS
  static const double ACCIDENT_G_THRESHOLD = 5.0; // 5G+ indicates accident
  static const double SEVERE_G_THRESHOLD = 7.0;   // 7G+ severe accident with automatic SOS
  static const double GYRO_THRESHOLD = 300.0;      // 300°/s sudden rotation
  static const double SPEED_CHANGE_THRESHOLD = 30.0; // 30+ km/h sudden change
  
  // Sample windows for analysis
  static const int SENSOR_SAMPLE_WINDOW = 20;
  static const Duration ACCIDENT_DETECTION_WINDOW = Duration(milliseconds: 500); // Reduced to catch brief spikes
  
  // Sensor subscriptions
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;
  StreamSubscription<Position>? _locationSubscription;
  
  // Sensor data storage
  final List<double> _accelerometerMagnitudes = [];
  final List<double> _gyroscopeRotations = [];
  final List<Position> _locationHistory = [];
  
  // Current state
  AccidentSeverity _currentSeverity = AccidentSeverity.none;
  bool _isMonitoring = false;
  DateTime _lastAccidentCheck = DateTime.now();
  double _maxGForceDetected = 0.0; // Track highest G-force spike
  
  // Notifications
  final FlutterLocalNotificationsPlugin _notificationsPlugin = 
      FlutterLocalNotificationsPlugin();
  
  // Getters
  AccidentSeverity get currentSeverity => _currentSeverity;
  bool get isMonitoring => _isMonitoring;
  double get maxGForceDetected => _maxGForceDetected;
  EmergencyLocationData? get lastEmergencyLocation {
    if (_locationHistory.isEmpty) return null;
    final position = _locationHistory.last;
    return EmergencyLocationData(
      latitude: position.latitude,
      longitude: position.longitude,
      address: null,
      timestamp: position.timestamp,
      accuracy: position.accuracy,
      altitude: position.altitude,
      speed: position.speed,
      heading: position.heading,
    );
  }
  
  // Callbacks
  Function(AccidentSeverity)? onAccidentDetected;
  Function(String)? onEmergencyAlert;

  MultiSensorAccidentDetector({
    this.onAccidentDetected,
    this.onEmergencyAlert,
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

  /// Initialize all sensors for accident detection
  Future<void> initialize() async {
    await _initializeNotifications();
    await _startMultiSensorMonitoring();
    _isMonitoring = true;
    notifyListeners();
  }

  /// Initialize notifications
  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    
    await _notificationsPlugin.initialize(initializationSettings);
  }

  /// Start monitoring all sensors
  Future<void> _startMultiSensorMonitoring() async {
    // 1. Accelerometer for G-force detection
    _accelerometerSubscription = accelerometerEventStream().listen((event) {
      _processAccelerometerData(event);
    });

    // 2. Gyroscope for rotation detection
    _gyroscopeSubscription = gyroscopeEventStream().listen((event) {
      _processGyroscopeData(event);
    });

    // 3. Magnetometer for orientation changes
    _magnetometerSubscription = magnetometerEventStream().listen((event) {
      _processMagnetometerData(event);
    });

    // 4. GPS for speed and location analysis
    try {
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
          _processLocationData(position);
        });
      }
    } catch (e) {
      print('GPS initialization failed: $e');
    }
  }

  /// Process accelerometer data for sudden impacts
  void _processAccelerometerData(AccelerometerEvent event) async {
    // Calculate total acceleration magnitude
    double magnitude = sqrt(
      pow(event.x, 2) + pow(event.y, 2) + pow(event.z, 2)
    );
    
    // Track highest G-force
    _maxGForceDetected = max(_maxGForceDetected, magnitude);
    
    _accelerometerMagnitudes.add(magnitude);
    
    // Keep recent samples only
    if (_accelerometerMagnitudes.length > SENSOR_SAMPLE_WINDOW) {
      _accelerometerMagnitudes.removeAt(0);
    }
    
    // Check if SOS is enabled before processing
    final sosEnabled = await _isSosEnabled();
    if (!sosEnabled) {
      print('⚠️ G-Force detected but SOS is DISABLED - ignoring ${magnitude.toStringAsFixed(2)}G');
      return; // Exit early if SOS is disabled
    }
    
    // Get user-configured threshold
    final userThreshold = await _getUserGForceThreshold();
    
    // Immediate severe accident detection for high G-force spikes
    if (magnitude > userThreshold) {
      print('🚨 G-FORCE SPIKE DETECTED: ${magnitude.toStringAsFixed(2)}G (User Threshold: ${userThreshold.toStringAsFixed(1)}G)');
      print('🔄 TRIGGERING IMMEDIATE SEVERE ACCIDENT - SOS ENABLED ✅');
      _triggerImmediateSevereAccident('SEVERE G-FORCE SPIKE: ${magnitude.toStringAsFixed(1)}G');
    }
    // Check for accident-level G-forces
    else if (magnitude > ACCIDENT_G_THRESHOLD) {
      print('⚠️ High G-Force: ${magnitude.toStringAsFixed(2)}G (Threshold: ${ACCIDENT_G_THRESHOLD}G)');
      _triggerAccidentAnalysis('High G-Force Detected: ${magnitude.toStringAsFixed(1)}G');
    }
  }

  /// Process gyroscope data for sudden rotations
  void _processGyroscopeData(GyroscopeEvent event) {
    // Calculate total rotation magnitude
    double rotationMagnitude = sqrt(pow(event.x, 2) + pow(event.y, 2) + pow(event.z, 2));
    
    _gyroscopeRotations.add(rotationMagnitude);
    
    // Keep recent samples only
    if (_gyroscopeRotations.length > SENSOR_SAMPLE_WINDOW) {
      _gyroscopeRotations.removeAt(0);
    }
    
    // Check for sudden rotation (vehicle spinning/rolling)
    if (rotationMagnitude > GYRO_THRESHOLD) {
      _triggerAccidentAnalysis('Sudden Rotation Detected: ${rotationMagnitude.toStringAsFixed(1)}°/s');
    }
  }

  /// Process magnetometer data for orientation changes
  void _processMagnetometerData(MagnetometerEvent event) {
    // Calculate magnetic field magnitude
    double magneticMagnitude = sqrt(pow(event.x, 2) + pow(event.y, 2) + pow(event.z, 2));
    
    // Detect sudden magnetic field changes (vehicle flipping)
    // Implementation depends on baseline calibration
    // This is a simplified version
    if (magneticMagnitude > 100.0 || magneticMagnitude < 10.0) {
      // Unusual magnetic reading - possible vehicle flip
      _triggerAccidentAnalysis('Orientation Change Detected');
    }
  }

  /// Process GPS location data for speed analysis
  void _processLocationData(Position position) {
    _locationHistory.add(position);
    
    // Keep recent locations only
    if (_locationHistory.length > 10) {
      _locationHistory.removeAt(0);
    }
    
    // Calculate speed change if we have enough data
    if (_locationHistory.length >= 2) {
      Position previous = _locationHistory[_locationHistory.length - 2];
      Position current = _locationHistory.last;
      
      double speedChange = (current.speed - previous.speed).abs() * 3.6; // Convert to km/h
      
      // Check for sudden speed change (crash deceleration)
      if (speedChange > SPEED_CHANGE_THRESHOLD) {
        _triggerAccidentAnalysis('Sudden Speed Change: ${speedChange.toStringAsFixed(1)} km/h');
      }
    }
  }

  /// Analyze all sensor data to determine accident severity
  void _triggerAccidentAnalysis(String trigger) async {
    // Prevent multiple rapid analyses
    if (DateTime.now().difference(_lastAccidentCheck) < ACCIDENT_DETECTION_WINDOW) {
      return;
    }
    
    _lastAccidentCheck = DateTime.now();
    
    // Multi-sensor fusion algorithm
    AccidentSeverity severity = await _calculateAccidentSeverity();
    
    if (severity != AccidentSeverity.none && severity != _currentSeverity) {
      _currentSeverity = severity;
      
      // Trigger callbacks
      onAccidentDetected?.call(severity);
      
      // Send notifications
      await _sendAccidentNotification(severity, trigger);
      
      // Emergency procedures for severe accidents
      if (severity == AccidentSeverity.severe) {
        await _handleSevereAccident();
      }
      
      notifyListeners();
    }
  }

  /// Immediate severe accident detection for high G-force spikes
  void _triggerImmediateSevereAccident(String trigger) async {
    print('🚨 IMMEDIATE SEVERE ACCIDENT DETECTED: $trigger');
    print('🔄 CALLING onAccidentDetected CALLBACK WITH SEVERE SEVERITY');
    
    // Force severe accident regardless of cooldown for high G-force spikes
    _currentSeverity = AccidentSeverity.severe;
    
    // Trigger callbacks immediately
    print('🔄 EXECUTING: onAccidentDetected?.call(AccidentSeverity.severe)');
    onAccidentDetected?.call(AccidentSeverity.severe);
    print('✅ CALLBACK EXECUTED - MainAppProvider should now handle severe accident');
    
    // Send notifications
    await _sendAccidentNotification(AccidentSeverity.severe, trigger);
    
    // Emergency procedures
    await _handleSevereAccident();
    
    // Update last check to prevent spam
    _lastAccidentCheck = DateTime.now();
    
    notifyListeners();
  }

  /// Multi-sensor fusion to calculate accident severity
  Future<AccidentSeverity> _calculateAccidentSeverity() async {
    double accidentScore = 0.0;
    
    // Get user-configured threshold
    final userThreshold = await _getUserGForceThreshold();
    
    // 1. Accelerometer analysis (40% weight)
    if (_accelerometerMagnitudes.isNotEmpty) {
      double maxG = _accelerometerMagnitudes.reduce(max);
      if (maxG > userThreshold) {
        accidentScore += 4.0; // Severe contribution
      } else if (maxG > ACCIDENT_G_THRESHOLD) {
        accidentScore += 2.0; // Moderate contribution
      }
    }
    
    // 2. Gyroscope analysis (30% weight)
    if (_gyroscopeRotations.isNotEmpty) {
      double maxRotation = _gyroscopeRotations.reduce(max);
      if (maxRotation > GYRO_THRESHOLD) {
        accidentScore += 3.0; // High rotation indicates accident
      }
    }
    
    // 3. GPS speed analysis (20% weight)
    if (_locationHistory.length >= 2) {
      double speedChange = _calculateMaxSpeedChange();
      if (speedChange > SPEED_CHANGE_THRESHOLD * 2) {
        accidentScore += 2.0; // Severe deceleration
      } else if (speedChange > SPEED_CHANGE_THRESHOLD) {
        accidentScore += 1.0; // Moderate deceleration
      }
    }
    
    // 4. Pattern analysis (10% weight)
    bool hasMultipleSensorTriggers = _checkMultipleSensorTriggers();
    if (hasMultipleSensorTriggers) {
      accidentScore += 1.0; // Multiple sensors indicate real accident
    }
    
    // Determine severity based on total score
    if (accidentScore >= 6.0) {
      return AccidentSeverity.severe;
    } else if (accidentScore >= 3.0) {
      return AccidentSeverity.moderate;
    } else if (accidentScore >= 1.0) {
      return AccidentSeverity.minor;
    } else {
      return AccidentSeverity.none;
    }
  }

  /// Calculate maximum speed change in recent history
  double _calculateMaxSpeedChange() {
    if (_locationHistory.length < 2) return 0.0;
    
    double maxChange = 0.0;
    for (int i = 1; i < _locationHistory.length; i++) {
      double change = (_locationHistory[i].speed - _locationHistory[i-1].speed).abs() * 3.6;
      maxChange = max(maxChange, change);
    }
    return maxChange;
  }

  /// Check if multiple sensors triggered simultaneously
  bool _checkMultipleSensorTriggers() {
    bool highG = _accelerometerMagnitudes.isNotEmpty && 
                 _accelerometerMagnitudes.any((g) => g > ACCIDENT_G_THRESHOLD);
    bool highRotation = _gyroscopeRotations.isNotEmpty && 
                       _gyroscopeRotations.any((r) => r > GYRO_THRESHOLD);
    bool speedChange = _calculateMaxSpeedChange() > SPEED_CHANGE_THRESHOLD;
    
    int triggerCount = 0;
    if (highG) triggerCount++;
    if (highRotation) triggerCount++;
    if (speedChange) triggerCount++;
    
    return triggerCount >= 2; // At least 2 sensors triggered
  }

  /// Send accident notification
  Future<void> _sendAccidentNotification(AccidentSeverity severity, String trigger) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'accident_channel',
      'Accident Detection',
      channelDescription: 'Notifications for detected accidents',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.show(
      severity.level,
      '🚨 ${severity.title}',
      '${severity.description}\nTrigger: $trigger',
      platformChannelSpecifics,
    );
  }

  /// Handle severe accident - emergency procedures
  Future<void> _handleSevereAccident() async {
    // Emergency alert
    onEmergencyAlert?.call('SEVERE ACCIDENT DETECTED - INITIATING EMERGENCY PROCEDURES');
    
    // Here you could implement:
    // 1. Automatic emergency calling
    // 2. SMS to emergency contacts
    // 3. Location sharing with emergency services
    // 4. Medical information broadcasting
    
    print('🚨 SEVERE ACCIDENT DETECTED - EMERGENCY PROCEDURES ACTIVATED');
  }

  /// Stop all sensor monitoring
  @override
  void dispose() {
    _isMonitoring = false;
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _magnetometerSubscription?.cancel();
    _locationSubscription?.cancel();
    super.dispose();
  }

  /// Get current sensor status
  Map<String, dynamic> getSensorStatus() {
    return {
      'isMonitoring': _isMonitoring,
      'currentSeverity': _currentSeverity.title,
      'accelerometerSamples': _accelerometerMagnitudes.length,
      'gyroscopeSamples': _gyroscopeRotations.length,
      'locationSamples': _locationHistory.length,
      'lastG': _accelerometerMagnitudes.isNotEmpty 
          ? _accelerometerMagnitudes.last.toStringAsFixed(2) : 'N/A',
      'lastRotation': _gyroscopeRotations.isNotEmpty 
          ? _gyroscopeRotations.last.toStringAsFixed(2) : 'N/A',
      'currentSpeed': _locationHistory.isNotEmpty 
          ? (_locationHistory.last.speed * 3.6).toStringAsFixed(1) + ' km/h' : 'N/A',
    };
  }
}