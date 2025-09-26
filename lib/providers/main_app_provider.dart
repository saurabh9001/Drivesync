import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/multi_sensor_accident_detector.dart';

class MainAppProvider extends StatefulWidget {
  final Widget child;

  const MainAppProvider({super.key, required this.child});

  @override
  State<MainAppProvider> createState() => _MainAppProviderState();
}

class _MainAppProviderState extends State<MainAppProvider> {
  late MultiSensorAccidentDetector _accidentDetector;

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
        _handleMinorAccident();
        break;
      case AccidentSeverity.none:
        break;
    }
  }

  void _handleSevereAccident() {
    // Severe accident - automatic emergency procedures
    print('🚨 SEVERE ACCIDENT - INITIATING EMERGENCY PROCEDURES');
    
    // 1. Start countdown for automatic emergency call
    _showEmergencyCountdown();
    
    // 2. Send immediate SMS to emergency contacts
    _sendEmergencySMS();
    
    // 3. Log the incident with full sensor data
    _logSevereAccident();
  }

  void _handleModerateAccident() {
    // Moderate accident - user confirmation required
    print('⚠️ MODERATE ACCIDENT - USER CONFIRMATION REQUIRED');
    
    _showAccidentConfirmationDialog();
  }

  void _handleMinorAccident() {
    // Minor accident - silent logging
    print('ℹ️ MINOR IMPACT DETECTED - LOGGING INCIDENT');
    
    _logMinorIncident();
  }

  void _handleEmergencyAlert(String message) {
    print('📢 Emergency Alert: $message');
    
    // Show emergency alert dialog
    if (mounted) {
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
  }

  void _showEmergencyCountdown() {
    // Show 10-second countdown before automatic emergency call
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EmergencyCountdownDialog(
        onCallEmergency: _makeEmergencyCall,
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  void _showAccidentConfirmationDialog() {
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
            onPressed: () {
              Navigator.pop(context);
              _sendEmergencySMS();
            },
            child: const Text('Send Location'),
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

  void _makeEmergencyCall() {
    // Implement emergency call functionality
    print('📞 Calling Emergency Services (108/112)...');
    // You would implement actual phone call here using url_launcher
    // await launch('tel:108');
  }

  void _sendEmergencySMS() {
    // Implement emergency SMS functionality
    print('📱 Sending emergency SMS with location...');
    // You would implement SMS sending here
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

class EmergencyCountdownDialog extends StatefulWidget {
  final VoidCallback onCallEmergency;
  final VoidCallback onCancel;

  const EmergencyCountdownDialog({
    super.key,
    required this.onCallEmergency,
    required this.onCancel,
  });

  @override
  State<EmergencyCountdownDialog> createState() => _EmergencyCountdownDialogState();
}

class _EmergencyCountdownDialogState extends State<EmergencyCountdownDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  int _countdown = 10;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );

    _animationController.addListener(() {
      setState(() {
        _countdown = (10 - (_animationController.value * 10)).ceil();
      });
    });

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Auto-call emergency after countdown
        widget.onCallEmergency();
        Navigator.pop(context);
      }
    });

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.emergency, color: Colors.red, size: 32),
          SizedBox(width: 8),
          Text('EMERGENCY DETECTED'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Severe accident detected!\n\nCalling emergency services in:',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: _animationController.value,
                  strokeWidth: 6,
                  color: Colors.red,
                  backgroundColor: Colors.red.withOpacity(0.3),
                ),
              ),
              Text(
                '$_countdown',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Press "I\'m OK" if this was a false alarm',
            style: TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            _animationController.stop();
            widget.onCancel();
          },
          child: const Text('I\'M OK'),
        ),
        ElevatedButton(
          onPressed: () {
            _animationController.stop();
            widget.onCallEmergency();
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('CALL NOW', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}