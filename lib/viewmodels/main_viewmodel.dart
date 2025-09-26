import 'package:flutter/material.dart';
import 'dart:async';
import '../models/advanced_models.dart';
import '../models/user_profile.dart';
import '../services/ai_service.dart';
import '../data/demo_data.dart';

class MainViewModel extends ChangeNotifier {
  final AIService _aiService = AIService();
  
  // Navigation
  int _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;
  
  void setSelectedIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  // User Profile
  UserProfile? _userProfile;
  UserProfile? get userProfile => _userProfile;

  void setUserProfile(UserProfile? profile) {
    _userProfile = profile;
    notifyListeners();
  }

  // Risk Assessment
  double _currentRiskScore = 7.2;
  double get currentRiskScore => _currentRiskScore;

  AlertLevel _currentAlertLevel = AlertLevel.medium;
  AlertLevel get currentAlertLevel => _currentAlertLevel;

  List<String> _currentRecommendations = [];
  List<String> get currentRecommendations => _currentRecommendations;

  // Location Tracking
  bool _isLocationTracking = false;
  bool get isLocationTracking => _isLocationTracking;

  // AI Processing Status
  bool _isAIProcessing = false;
  bool get isAIProcessing => _isAIProcessing;

  // Sensor Data Subscription
  StreamSubscription<SensorData>? _sensorSubscription;

  // Emergency Alert Status
  bool _isEmergencyAlert = false;
  bool get isEmergencyAlert => _isEmergencyAlert;

  // Initialization
  Future<void> initialize() async {
    await _loadUserProfile();
    _initializeAI();
    _loadDemoData();
    
    // Start with real sensors enabled and tracking active
    _isLocationTracking = true;
    if (_aiService.useRealSensors) {
      await _aiService.startRealSensorMonitoring();
    } else {
      _aiService.startSensorSimulation();
    }
    notifyListeners();
  }

  void _loadDemoData() {
    // Load demo user profile if none exists
    if (_userProfile == null) {
      _userProfile = DemoData.getDefaultUserProfile();
      notifyListeners();
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await _aiService.loadUserProfile();
      if (profile != null) {
        _userProfile = profile;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    try {
      await _aiService.saveUserProfile(profile);
      _userProfile = profile;
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving user profile: $e');
    }
  }

  void _initializeAI() {
    // Listen to sensor data updates
    _sensorSubscription = _aiService.sensorStream.listen((sensorData) {
      _updateRiskAssessment();
    });
  }

  void _updateRiskAssessment() {
    _isAIProcessing = true;
    notifyListeners();

    // Calculate risk score
    _currentRiskScore = _aiService.calculateAdvancedRiskScore(_userProfile);
    _currentAlertLevel = _aiService.getAlertLevel(_currentRiskScore);
    _currentRecommendations = _aiService.getSafetyRecommendations(_currentRiskScore);

    // Check for emergency conditions
    _checkEmergencyConditions();

    _isAIProcessing = false;
    notifyListeners();
  }

  void _checkEmergencyConditions() {
    if (_currentRiskScore >= 9.0) {
      _triggerEmergencyAlert();
    } else {
      _isEmergencyAlert = false;
    }
  }

  void _triggerEmergencyAlert() {
    if (!_isEmergencyAlert) {
      _isEmergencyAlert = true;
      _aiService.triggerEmergencyAlert();
      // Additional emergency handling can be added here
    }
  }

  void toggleLocationTracking() {
    _isLocationTracking = !_isLocationTracking;
    
    if (_isLocationTracking) {
      // Start real sensor monitoring by default, fallback to simulation if needed
      if (_aiService.useRealSensors) {
        _aiService.startRealSensorMonitoring();
      } else {
        _aiService.startSensorSimulation();
      }
    } else {
      _aiService.stopRealSensorMonitoring();
      _aiService.stopSensorSimulation();
    }
    
    notifyListeners();
  }

  void updateRiskScore(double newScore) {
    _currentRiskScore = newScore;
    _currentAlertLevel = _aiService.getAlertLevel(newScore);
    notifyListeners();
  }

  // Get risk color based on current score
  Color getRiskColor() {
    if (_currentRiskScore >= 8) return const Color(0xFFEF4444); // red-500
    if (_currentRiskScore >= 5) return const Color(0xFFF59E0B); // yellow-500  
    return const Color(0xFF10B981); // green-500
  }

  // Get alert color based on current level
  Color getAlertColor() {
    switch (_currentAlertLevel) {
      case AlertLevel.high:
        return const Color(0xFFDC2626); // red-600
      case AlertLevel.medium:
        return const Color(0xFFD97706); // amber-600
      case AlertLevel.safe:
        return const Color(0xFF059669); // emerald-600
    }
  }

  // Get alert message
  String getAlertMessage() {
    switch (_currentAlertLevel) {
      case AlertLevel.high:
        return "🚨 HIGH RISK - Exercise extreme caution";
      case AlertLevel.medium:
        return "⚠️ MODERATE RISK - Drive carefully";
      case AlertLevel.safe:
        return "✅ SAFE CONDITIONS - Good travels";
    }
  }

  // Manual emergency trigger
  void triggerManualEmergencyAlert() {
    _triggerEmergencyAlert();
    notifyListeners();
  }

  // Reset emergency alert
  void resetEmergencyAlert() {
    _isEmergencyAlert = false;
    notifyListeners();
  }

  // Get nearby blackspots
  List<AdvancedBlackspot> getNearbyBlackspots() {
    final currentLocation = _aiService.getCurrentLocation();
    if (currentLocation == null) return [];
    
    return _aiService.getNearbyBlackspots(
      currentLocation.latitude,
      currentLocation.longitude,
    );
  }

  // Get current weather
  WeatherData getCurrentWeather() {
    return _aiService.currentWeather;
  }

  // Simulate weather change for demo
  void simulateWeatherChange() {
    _aiService.simulateWeatherChange();
    _updateRiskAssessment();
  }

  // Get AI service instance for other viewmodels
  AIService get aiService => _aiService;

  @override
  void dispose() {
    _sensorSubscription?.cancel();
    _aiService.dispose();
    super.dispose();
  }
}