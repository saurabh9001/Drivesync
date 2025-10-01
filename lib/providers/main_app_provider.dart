import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../models/emergency_contact.dart';
import '../models/emergency_location_data.dart';
import '../services/emergency_sos_service.dart';
import '../services/multi_sensor_accident_detector.dart';

class MainAppProvider extends StatefulWidget {
  final Widget child;

  const MainAppProvider({super.key, required this.child});

  @override
  State<MainAppProvider> createState() => _MainAppProviderState();
}

class _MainAppProviderState extends State<MainAppProvider> {
  late MultiSensorAccidentDetector _accidentDetector;
  bool _isEmergencyHandling = false;
  DateTime? _lastEmergencyTrigger;
  static const Duration _emergencyCooldown = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    _initializeAccidentDetector();
  }

  void _initializeAccidentDetector() {
    _accidentDetector = MultiSensorAccidentDetector(
      onAccidentDetected: (severity) {
        _handleAccidentDetected(severity);
      },
      onEmergencyAlert: (message) {
        _handleEmergencyAlert(message);
      },
    );

    // Initialize the detector
    _accidentDetector.initialize();
  }

  void _handleAccidentDetected(AccidentSeverity severity) {
    print('🚨 Accident Detected: ${severity.title}');
    
    // Show immediate UI feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                severity == AccidentSeverity.severe ? Icons.emergency : Icons.warning,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${severity.title}: ${severity.description}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: severity == AccidentSeverity.severe 
              ? Colors.red 
              : Colors.orange,
          duration: Duration(
            seconds: severity == AccidentSeverity.severe ? 10 : 5,
          ),
          action: severity == AccidentSeverity.severe
              ? SnackBarAction(
                  label: 'CALL 108',
                  textColor: Colors.white,
                  onPressed: () => _makeEmergencyCall(),
                )
              : null,
        ),
      );
    }

    // Additional actions based on severity
    switch (severity) {
      case AccidentSeverity.severe:
        _handleSevereAccident();
        break;
      case AccidentSeverity.moderate:
        _handleModerateAccident();
        break;
      case AccidentSeverity.minor:
        _logMinorIncident();
        break;
      case AccidentSeverity.none:
        break;
    }
  }

  Future<void> _handleSevereAccident() async {
    print('🚨 MainAppProvider._handleSevereAccident() CALLED - STARTING EMERGENCY FLOW');
    
    if (_isEmergencyHandling) {
      print('⏳ Emergency response already in progress. Skipping duplicate trigger.');
      return;
    }

    final now = DateTime.now();
    if (_lastEmergencyTrigger != null &&
        now.difference(_lastEmergencyTrigger!) < _emergencyCooldown) {
      print('⏳ Emergency cooldown active — ignoring duplicate severe alert.');
      return;
    }

    _isEmergencyHandling = true;
    _lastEmergencyTrigger = now;

    print('🚨 SEVERE ACCIDENT - INITIATING AUTOMATIC EMERGENCY PROCEDURES');

    final emergencyService = EmergencySOSService();
    await emergencyService.setSosEnabled(true);
    await emergencyService.setAutoTriggerEnabled(true);

    final location = await _resolveAccidentLocation();
    final message =
        'SEVERE accident detected by DriveSync! I need immediate help at ${location.formattedAddress}. '
        'Google Maps: ${location.googleMapsUrl}';

    bool smsSuccess = false;

    try {
      // STEP 1: Send emergency SMS to all contacts
      print('📱 STEP 1: About to call _sendEmergencySMS...');
      smsSuccess = await _sendEmergencySMS(
        emergencyService: emergencyService,
        overrideLocation: location,
        customMessage: message,
      );
      print('📱 STEP 1 RESULT: SMS success = $smsSuccess');

      // STEP 2: Make automatic emergency call to first priority contact
      final hasPriorityContact = emergencyService.emergencyContacts.any(
        (contact) => contact.type == ContactType.family ||
            contact.type == ContactType.police,
      );

      if (!smsSuccess || !hasPriorityContact) {
        print('⚠️ SMS failed or no priority contact — attempting emergency call');
      }
      
      print('📞 STEP 2: About to call _makeEmergencyCall...');
      await _makeEmergencyCall(emergencyService: emergencyService);
      print('📞 STEP 2 COMPLETED: Emergency call attempted');

      _logSevereAccident();
      _showEmergencyStatusDialog(location: location, smsSent: smsSuccess);
    } catch (e) {
      print('❌ Emergency SOS flow failed: $e');
      await _makeEmergencyCall(emergencyService: emergencyService);
    } finally {
      _isEmergencyHandling = false;
    }
  }

  void _handleModerateAccident() {
    // Moderate accident - user confirmation required
    print('⚠️ MODERATE ACCIDENT - USER CONFIRMATION REQUIRED');
    _showAccidentConfirmationDialog();
  }

  void _handleEmergencyAlert(String message) {
    print('📢 Emergency Alert: $message');
    
    if (!mounted) return;

    if (_isEmergencyHandling) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
        ),
      );
      return;
    }

    // Show emergency alert dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.emergency, color: Colors.red, size: 32),
            SizedBox(width: 8),
            Text('EMERGENCY ALERT'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('DISMISS'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _makeEmergencyCall();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('CALL 108', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAccidentConfirmationDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Accident Detected'),
          ],
        ),
        content: const Text(
          'Our sensors detected a possible accident. Are you okay?\n\n'
          'If you need help, we can:\n'
          '• Call emergency services\n'
          '• Send your location to emergency contacts\n'
          '• Log this incident for insurance purposes',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('I\'m OK'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _sendEmergencySMS();
              await _makeEmergencyCall();
            },
            child: const Text('Send Location & Call'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _makeEmergencyCall();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Call Help', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<bool> _makeEmergencyCall({EmergencySOSService? emergencyService}) async {
    print('📞 Calling Emergency Contact Automatically...');

    try {
      final service = emergencyService ?? EmergencySOSService();
      final contacts = service.emergencyContacts;

      if (contacts.isEmpty) {
        print('⚠️ No emergency contacts configured');
        return false;
      }

      final primaryContact = contacts.first;
      print('📞 Auto-calling ${primaryContact.name} at ${primaryContact.phoneNumber}');
      
      final callResult = await service.makeEmergencyCall(primaryContact);

      if (callResult) {
        print('✅ Emergency call initiated automatically to ${primaryContact.name}');
      } else {
        print('⚠️ Emergency call fallback launched for ${primaryContact.name}');
      }

      return callResult;
    } catch (e) {
      print('❌ Failed to make automatic emergency call: $e');
      return false;
    }
  }

  Future<bool> _sendEmergencySMS({
    EmergencySOSService? emergencyService,
    EmergencyLocationData? overrideLocation,
    String? customMessage,
  }) async {
    print('📱 Sending Emergency SMS Automatically...');

    final service = emergencyService ?? EmergencySOSService();

    try {
      await service.setSosEnabled(true);
      await service.setAutoTriggerEnabled(true);

      final location = overrideLocation ?? await _resolveAccidentLocation();
      final message = customMessage ??
          'ACCIDENT DETECTED! I need help at ${location.formattedAddress}. '
              'Google Maps: ${location.googleMapsUrl}';

      final result = await service.triggerEmergencySOS(
        userLocation: location,
        customMessage: message,
      );

      if (result) {
        print('✅ Emergency SMS sent automatically');
      } else {
        print('⚠️ Emergency SMS failed — attempting fallback call.');
      }

      return result;
    } catch (e) {
      print('❌ Failed to send emergency SMS: $e');
      return false;
    }
  }

  Future<EmergencyLocationData> _resolveAccidentLocation() async {
    // Try to use location from accident detector first
    final detectorLocation = _accidentDetector.lastEmergencyLocation;
    if (detectorLocation != null && detectorLocation.isValid) {
      print('📍 Using accident detector location: ${detectorLocation.formattedAddress}');
      return detectorLocation;
    }

    // Fallback to fresh GPS fix
    try {
      print('📍 Fetching fresh GPS location for emergency...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 5));

      return EmergencyLocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        altitude: position.altitude,
        speed: position.speed,
        heading: position.heading,
        address:
            'Lat: ${position.latitude.toStringAsFixed(5)}, Lng: ${position.longitude.toStringAsFixed(5)}',
        timestamp: position.timestamp,
      );
    } catch (e) {
      print('⚠️ Unable to fetch fresh GPS fix for emergency: $e');
      return EmergencyLocationData(
        latitude: 0.0,
        longitude: 0.0,
        address: 'Location unavailable',
      );
    }
  }

  void _showEmergencyStatusDialog({
    required EmergencyLocationData location,
    required bool smsSent,
  }) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.emergency, color: Colors.red, size: 32),
              SizedBox(width: 8),
              Text('Emergency Response Initiated'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'We have automatically placed an emergency call and notified your contacts.',
              ),
              const SizedBox(height: 12),
              Text(
                'Location: ${location.formattedAddress}',
                style: const TextStyle(fontSize: 13),
              ),
              if (!smsSent) ...[
                const SizedBox(height: 12),
                const Text(
                  '⚠️ SMS delivery failed. Please confirm manually.',
                  style: TextStyle(color: Colors.orange, fontSize: 12),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _logSevereAccident() {
    // Log severe accident with full sensor data
    final sensorStatus = _accidentDetector.getSensorStatus();
    print('📝 Logging severe accident: $sensorStatus');
  }

  void _logMinorIncident() {
    // Log minor incident for analytics
    final sensorStatus = _accidentDetector.getSensorStatus();
    print('📝 Logging minor incident: $sensorStatus');
  }

  @override
  void dispose() {
    _accidentDetector.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MultiSensorAccidentDetector>.value(
      value: _accidentDetector,
      child: widget.child,
    );
  }
}