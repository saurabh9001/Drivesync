import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/multi_sensor_accident_detector.dart';

class MultiSensorDashboard extends StatelessWidget {
  const MultiSensorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MultiSensorAccidentDetector>(
      builder: (context, detector, child) {
        final sensorStatus = detector.getSensorStatus();
        
        return Card(
          elevation: 4,
          margin: const EdgeInsets.all(8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with status indicator
                Row(
                  children: [
                    Icon(
                      detector.isMonitoring ? Icons.sensors : Icons.sensors_off,
                      color: detector.isMonitoring ? Colors.green : Colors.red,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Multi-Sensor Protection',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getSeverityColor(detector.currentSeverity),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        detector.currentSeverity.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Current severity description
                if (detector.currentSeverity != AccidentSeverity.none)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getSeverityColor(detector.currentSeverity).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getSeverityColor(detector.currentSeverity).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      detector.currentSeverity.description,
                      style: TextStyle(
                        color: _getSeverityColor(detector.currentSeverity),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                // Sensor data grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 1.5,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: [
                    _buildSensorTile(
                      icon: Icons.speed,
                      title: 'G-Force',
                      value: '${sensorStatus['lastG']}G',
                      color: Colors.blue,
                      samples: sensorStatus['accelerometerSamples'],
                    ),
                    _buildSensorTile(
                      icon: Icons.rotate_right,
                      title: 'Rotation',
                      value: '${sensorStatus['lastRotation']}°/s',
                      color: Colors.orange,
                      samples: sensorStatus['gyroscopeSamples'],
                    ),
                    _buildSensorTile(
                      icon: Icons.navigation,
                      title: 'Speed',
                      value: sensorStatus['currentSpeed'],
                      color: Colors.green,
                      samples: sensorStatus['locationSamples'],
                    ),
                    _buildSensorTile(
                      icon: Icons.shield,
                      title: 'Protection',
                      value: detector.isMonitoring ? 'ACTIVE' : 'INACTIVE',
                      color: detector.isMonitoring ? Colors.green : Colors.red,
                      samples: null,
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Emergency contact button (for severe accidents)
                if (detector.currentSeverity == AccidentSeverity.severe)
                  Container(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _callEmergency(context),
                      icon: const Icon(Icons.emergency, color: Colors.white),
                      label: const Text(
                        'CALL EMERGENCY SERVICES',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSensorTile({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    int? samples,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (samples != null) ...[
            const SizedBox(height: 2),
            Text(
              '$samples samples',
              style: TextStyle(
                color: color.withOpacity(0.7),
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getSeverityColor(AccidentSeverity severity) {
    switch (severity) {
      case AccidentSeverity.none:
        return Colors.green;
      case AccidentSeverity.minor:
        return Colors.yellow.shade700;
      case AccidentSeverity.moderate:
        return Colors.orange;
      case AccidentSeverity.severe:
        return Colors.red;
    }
  }

  void _callEmergency(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.emergency, color: Colors.red),
            SizedBox(width: 8),
            Text('Emergency Alert'),
          ],
        ),
        content: const Text(
          'Severe accident detected!\n\n'
          'Would you like to:\n'
          '• Call Emergency Services (108/112)\n'
          '• Send location to emergency contacts\n'
          '• Cancel if this was a false alarm',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement emergency contact SMS
              _sendEmergencySMS();
            },
            child: const Text('Send SMS'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement emergency call
              _makeEmergencyCall();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Call 108', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _sendEmergencySMS() {
    // Implement SMS to emergency contacts
    print('📱 Sending emergency SMS with location...');
  }

  void _makeEmergencyCall() {
    // Implement emergency call
    print('📞 Calling emergency services...');
  }
}

class SensorStatsPage extends StatelessWidget {
  const SensorStatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensor Statistics'),
        elevation: 0,
      ),
      body: Consumer<MultiSensorAccidentDetector>(
        builder: (context, detector, child) {
          final status = detector.getSensorStatus();
          
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Overall Status Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'System Status',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      _buildStatusRow('Monitoring Active', status['isMonitoring']),
                      _buildStatusRow('Current Alert Level', status['currentSeverity']),
                      _buildStatusRow('Accelerometer Samples', status['accelerometerSamples']),
                      _buildStatusRow('Gyroscope Samples', status['gyroscopeSamples']),
                      _buildStatusRow('Location Samples', status['locationSamples']),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Current Readings Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Sensor Readings',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      _buildStatusRow('G-Force', '${status['lastG']}G'),
                      _buildStatusRow('Rotation Speed', '${status['lastRotation']}°/s'),
                      _buildStatusRow('Vehicle Speed', status['currentSpeed']),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Thresholds Information Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detection Thresholds',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      _buildThresholdRow('Accident G-Force', '10.0G+', Colors.orange),
                      _buildThresholdRow('Severe Accident', '20.0G+', Colors.red),
                      _buildThresholdRow('Rotation Alert', '300°/s+', Colors.blue),
                      _buildThresholdRow('Speed Change', '30 km/h+', Colors.green),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildThresholdRow(String label, String threshold, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              threshold,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}