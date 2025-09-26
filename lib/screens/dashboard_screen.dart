import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/advanced_models.dart';
import '../services/ai_service.dart';
import '../services/road_condition_detector.dart';
import '../services/multi_sensor_accident_detector.dart';
import '../widgets/dashboard/risk_analysis_card.dart';
import '../widgets/dashboard/enhanced_risk_analysis_card.dart';
import '../widgets/dashboard/live_sensor_data_card.dart';
import '../widgets/dashboard/action_button.dart';
import '../widgets/road_condition_card.dart';
import '../widgets/multi_sensor_dashboard.dart';
import '../utils/weather_colors.dart';

class DashboardScreen extends StatelessWidget {
  final double riskScore;
  final UserProfile? userProfile;
  final bool isTracking;
  final VoidCallback onToggleTracking;
  final AlertLevel alertLevel;
  final List<String> recommendations;
  final AIService aiService;
  final RoadConditionDetector roadConditionDetector;
  final MultiSensorAccidentDetector? multiSensorDetector;

  const DashboardScreen({
    super.key,
    required this.riskScore,
    required this.userProfile,
    required this.isTracking,
    required this.onToggleTracking,
    required this.alertLevel,
    required this.recommendations,
    required this.aiService,
    required this.roadConditionDetector,
    this.multiSensorDetector,
  });

  Color _getRiskColor() {
    if (riskScore >= 8) return const Color(0xFFEF4444); // red-500
    if (riskScore >= 5) return const Color(0xFFF59E0B); // yellow-500
    return const Color(0xFF10B981); // green-500
  }

  String _getRiskLevel() {
    if (riskScore >= 8) return 'HIGH RISK';
    if (riskScore >= 5) return 'MEDIUM RISK';
    return 'SAFE';
  }

  String _getRiskMessage() {
    if (riskScore >= 8) {
      return 'Extreme caution advised. Consider alternative route.';
    } else if (riskScore >= 5) {
      return 'Moderate risk detected. Drive carefully.';
    } else {
      return 'Road conditions are favorable. Safe travels!';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLocation = aiService.getCurrentLocation();
    final weather = aiService.currentWeather;
    final nearbyBlackspots = currentLocation != null 
        ? aiService.getNearbyBlackspots(currentLocation.latitude, currentLocation.longitude)
        : <AdvancedBlackspot>[];
    
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI Alert Banner
            if (alertLevel == AlertLevel.high) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.red, size: 24),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🚨 HIGH RISK ALERT',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.red,
                            ),
                          ),
                          Text(
                            'Immediate attention required',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => aiService.triggerEmergencyAlert(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: const Text('Emergency', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Enhanced Risk Score Card with Live Sensor Data
            EnhancedRiskAnalysisCard(
              riskScore: riskScore,
              riskLevel: _getRiskLevel(),
              riskMessage: _getRiskMessage(),
              riskColor: _getRiskColor(),
              aiService: aiService,
            ),

            const SizedBox(height: 24),

            // Live Sensor Data Card
            LiveSensorDataCard(aiService: aiService),

            const SizedBox(height: 16),

            // Road Condition Detection Card
            RoadConditionCard(detector: roadConditionDetector),

            const SizedBox(height: 16),

            // Multi-Sensor Accident Detection Dashboard
            if (multiSensorDetector != null)
              const MultiSensorDashboard(),

            const SizedBox(height: 24),

            // AI Recommendations Card
            if (recommendations.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.psychology, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'AI Safety Recommendations',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...recommendations.take(3).map((rec) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              rec,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Real-time Sensor Data
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.05),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.sensors,
                        color: isTracking ? Colors.green : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'AI Sensor Monitoring',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Switch(
                        value: isTracking,
                        onChanged: (_) => onToggleTracking(),
                        activeColor: Colors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isTracking
                        ? 'AI analyzing GPS, accelerometer, gyroscope, and environmental data'
                        : 'Tap to start AI-powered monitoring',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF717182),
                    ),
                  ),
                  if (isTracking && aiService.sensorHistory.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Live Data:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildSensorDataRow('Location', '${currentLocation?.latitude.toStringAsFixed(6)}, ${currentLocation?.longitude.toStringAsFixed(6)}'),
                    _buildSensorDataRow('Speed', '${aiService.sensorHistory.last.speed.toStringAsFixed(1)} km/h'),
                    _buildSensorDataRow('Direction', '${aiService.sensorHistory.last.direction.toStringAsFixed(0)}°'),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Enhanced Stats with AI Data
            Row(
              children: [
                Expanded(
                  child: _buildAdvancedStatCard(
                    'Maharashtra\nLocation',
                    '${currentLocation?.latitude.toStringAsFixed(4) ?? "17.0906"}°N\n${currentLocation?.longitude.toStringAsFixed(4) ?? "74.4666"}°E',
                    Icons.my_location,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAdvancedStatCard(
                    'Nearby\nBlackspots',
                    '${nearbyBlackspots.length}\nDetected',
                    Icons.warning,
                    nearbyBlackspots.isEmpty ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildAdvancedStatCard(
                    'Weather\nCondition',
                    '${weather.condition.toUpperCase()}\n${weather.temperature.toStringAsFixed(0)}°C',
                    Icons.wb_sunny,
                    _getWeatherColor(weather.condition),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAdvancedStatCard(
                    'AI Processing\nStatus',
                    isTracking ? 'ACTIVE\nAnalyzing' : 'STANDBY\nReady',
                    Icons.psychology,
                    isTracking ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Enhanced Quick Actions
            const Text(
              'Emergency Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: DashboardActionButton(
                    title: 'Emergency\nCall',
                    icon: Icons.emergency,
                    color: Colors.red,
                    onTap: aiService.triggerEmergencyAlert,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DashboardActionButton(
                    title: 'Weather\nUpdate',
                    icon: Icons.cloud_sync,
                    color: Colors.blue,
                    onTap: aiService.simulateWeatherChange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DashboardActionButton(
                    title: 'Route\nPlanning',
                    icon: Icons.alt_route,
                    color: Colors.green,
                    onTap: () {},
                  ),
                ),
              ],
            ),


          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF717182),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorDataRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF717182),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF717182),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return DashboardActionButton(
      title: title,
      icon: icon,
      color: color,
      onTap: onTap,
    );
  }

  Color _getWeatherColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return const Color(0xFF10B981);
      case 'cloudy':
        return const Color(0xFF3B82F6);
      case 'rain':
        return const Color(0xFF34D399);
      case 'snow':
        return const Color(0xFF60A5FA);
      case 'fog':
        return const Color(0xFF4F46E5);
      default:
        return const Color(0xFF10B981);
    }
  }
}