import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/advanced_models.dart';
import '../../services/ai_service.dart';

class LiveSensorDataCard extends StatefulWidget {
  final AIService aiService;

  const LiveSensorDataCard({
    super.key,
    required this.aiService,
  });

  @override
  State<LiveSensorDataCard> createState() => _LiveSensorDataCardState();
}

class _LiveSensorDataCardState extends State<LiveSensorDataCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  SensorData? _currentSensorData;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    
    _animationController.repeat(reverse: true);
    
    // Listen to real sensor data
    widget.aiService.sensorStream.listen((sensorData) {
      if (mounted) {
        setState(() {
          _currentSensorData = sensorData;
        });
      }
    });
    
    // Get initial sensor data
    if (widget.aiService.sensorHistory.isNotEmpty) {
      _currentSensorData = widget.aiService.sensorHistory.last;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentSensorData == null) {
      return Card(
        elevation: 4,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: const Row(
            children: [
              CircularProgressIndicator(strokeWidth: 2),
              SizedBox(width: 12),
              Text('Initializing sensors...'),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with live indicator
            Row(
              children: [
                Icon(
                  widget.aiService.useRealSensors ? Icons.sensors : Icons.developer_mode,
                  color: widget.aiService.useRealSensors ? Colors.green : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Live Sensor Data',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.5 + (0.5 * _animationController.value)),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.aiService.useRealSensors ? 'REAL' : 'DEMO',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Sensor data in a 2x3 grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              childAspectRatio: 1.8,
              mainAxisSpacing: 3,
              crossAxisSpacing: 3,
              children: [
                _buildSensorTile(
                  icon: Icons.speed,
                  label: 'Speed',
                  value: '${_currentSensorData!.speed.toStringAsFixed(1)} km/h',
                  color: Colors.blue,
                ),
                _buildSensorTile(
                  icon: Icons.navigation,
                  label: 'Direction',
                  value: '${_currentSensorData!.direction.toStringAsFixed(0)}°',
                  color: Colors.purple,
                ),
                _buildSensorTile(
                  icon: Icons.flash_on,
                  label: 'G-Force',
                  value: '${_currentSensorData!.acceleration.toStringAsFixed(2)}G',
                  color: Colors.orange,
                ),
                _buildSensorTile(
                  icon: Icons.rotate_right,
                  label: 'Gyroscope',
                  value: '${_calculateGyroMagnitude().toStringAsFixed(1)}°/s',
                  color: Colors.green,
                ),
                _buildSensorTile(
                  icon: Icons.location_on,
                  label: 'Latitude',
                  value: '${_currentSensorData!.latitude.toStringAsFixed(4)}',
                  color: Colors.red,
                ),
                _buildSensorTile(
                  icon: Icons.location_on,
                  label: 'Longitude',
                  value: '${_currentSensorData!.longitude.toStringAsFixed(4)}',
                  color: Colors.teal,
                ),
              ],
            ),
            
            const SizedBox(height: 4),
            
            // Last update timestamp
            Center(
              child: Text(
                'Updated: ${_formatTimestamp(_currentSensorData!.timestamp)}',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 1),
          Text(
            value,
            style: TextStyle(
              fontSize: 8,
              color: color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  double _calculateGyroMagnitude() {
    if (_currentSensorData == null) return 0.0;
    return sqrt(
      pow(_currentSensorData!.gyroscopeX, 2) +
      pow(_currentSensorData!.gyroscopeY, 2) +
      pow(_currentSensorData!.gyroscopeZ, 2)
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inSeconds < 2) {
      return 'Just now';
    } else if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}