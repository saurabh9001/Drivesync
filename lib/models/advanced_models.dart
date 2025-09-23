import 'dart:math';
import 'user_profile.dart';

// Enhanced sensor data model
class SensorData {
  final double latitude;
  final double longitude;
  final double speed;
  final double direction;
  final double acceleration;
  final double gyroscopeX;
  final double gyroscopeY;
  final double gyroscopeZ;
  final DateTime timestamp;

  SensorData({
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.direction,
    required this.acceleration,
    required this.gyroscopeX,
    required this.gyroscopeY,
    required this.gyroscopeZ,
    required this.timestamp,
  });
}

// Weather data model
class WeatherData {
  final String condition; // clear, rain, fog, storm
  final double temperature;
  final double humidity;
  final double windSpeed;
  final double visibility;
  final double precipitationProbability;

  WeatherData({
    required this.condition,
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.visibility,
    required this.precipitationProbability,
  });

  double get riskFactor {
    double risk = 0.0;
    
    // Weather condition risk
    switch (condition) {
      case 'clear':
        risk += 0.1;
        break;
      case 'rain':
        risk += 0.6;
        break;
      case 'fog':
        risk += 0.8;
        break;
      case 'storm':
        risk += 0.9;
        break;
    }

    // Visibility risk
    if (visibility < 500) risk += 0.4;
    else if (visibility < 1000) risk += 0.2;

    // Wind speed risk
    if (windSpeed > 50) risk += 0.3;
    else if (windSpeed > 30) risk += 0.1;

    return risk.clamp(0.0, 1.0);
  }
}

// Enhanced blackspot model
class AdvancedBlackspot {
  final String id;
  final double latitude;
  final double longitude;
  final BlackspotSeverity severity;
  final BlackspotType type;
  final String title;
  final String description;
  final double riskScore;
  final int fatalAccidents;
  final int seriousInjuries;
  final int minorIncidents;
  final List<String> riskFactors;
  final DateTime lastUpdated;

  AdvancedBlackspot({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.severity,
    required this.type,
    required this.title,
    required this.description,
    required this.riskScore,
    required this.fatalAccidents,
    required this.seriousInjuries,
    required this.minorIncidents,
    required this.riskFactors,
    required this.lastUpdated,
  });
}

enum BlackspotSeverity { fatal, serious, minor }
enum BlackspotType { junction, highway, urban, construction, school }

// AI Processing Engine
class AIProcessingEngine {
  static const double maharashtraLatMin = 17.0;
  static const double maharashtraLatMax = 17.15;
  static const double maharashtraLngMin = 74.4;
  static const double maharashtraLngMax = 74.5;

  // Blackspot proximity detection
  static double calculateBlackspotProximity(
    double userLat, 
    double userLng, 
    List<AdvancedBlackspot> blackspots
  ) {
    double maxRisk = 0.0;
    
    for (var blackspot in blackspots) {
      double distance = _calculateDistance(userLat, userLng, blackspot.latitude, blackspot.longitude);
      
      // Risk decreases with distance (500m max range)
      if (distance <= 500) {
        double proximityRisk = blackspot.riskScore / 10.0;
        proximityRisk *= (1.0 - (distance / 500.0)); // Closer = higher risk
        
        // Severity multiplier
        switch (blackspot.severity) {
          case BlackspotSeverity.fatal:
            proximityRisk *= 1.5;
            break;
          case BlackspotSeverity.serious:
            proximityRisk *= 1.2;
            break;
          case BlackspotSeverity.minor:
            proximityRisk *= 0.8;
            break;
        }
        
        maxRisk = max(maxRisk, proximityRisk);
      }
    }
    
    return maxRisk.clamp(0.0, 1.0);
  }

  // Driver behavior recognition
  static double analyzeDriverBehavior(List<SensorData> recentData) {
    if (recentData.isEmpty) return 0.0;

    double riskFactor = 0.0;
    
    // Analyze speed patterns
    List<double> speeds = recentData.map((d) => d.speed).toList();
    double avgSpeed = speeds.reduce((a, b) => a + b) / speeds.length;
    double speedVariance = _calculateVariance(speeds);
    
    // High speed variance indicates erratic driving
    if (speedVariance > 100) riskFactor += 0.3;
    
    // Analyze acceleration patterns
    List<double> accelerations = recentData.map((d) => d.acceleration).toList();
    double avgAcceleration = accelerations.reduce((a, b) => a + b) / accelerations.length;
    
    // Harsh acceleration/braking
    if (avgAcceleration.abs() > 3.0) riskFactor += 0.2;
    
    // Analyze gyroscope data for sharp turns
    for (var data in recentData) {
      double gyroMagnitude = sqrt(
        data.gyroscopeX * data.gyroscopeX + 
        data.gyroscopeY * data.gyroscopeY + 
        data.gyroscopeZ * data.gyroscopeZ
      );
      
      if (gyroMagnitude > 2.0) riskFactor += 0.1;
    }
    
    return riskFactor.clamp(0.0, 1.0);
  }

  // Real-time hazard assessment
  static double assessRealTimeHazards(
    SensorData currentData,
    WeatherData weather,
    DateTime currentTime,
  ) {
    double hazardRisk = 0.0;
    
    // Speed-based risk
    if (currentData.speed > 80) hazardRisk += 0.3;
    else if (currentData.speed > 60) hazardRisk += 0.1;
    
    // Time-based risk (night driving)
    int hour = currentTime.hour;
    if (hour >= 22 || hour <= 5) hazardRisk += 0.2;
    
    // Weather risk
    hazardRisk += weather.riskFactor * 0.4;
    
    return hazardRisk.clamp(0.0, 1.0);
  }

  // Dynamic risk score calculation
  static double calculateDynamicRiskScore(
    SensorData currentData,
    List<SensorData> recentData,
    List<AdvancedBlackspot> blackspots,
    WeatherData weather,
    UserProfile userProfile,
    DateTime currentTime,
  ) {
    // Component weights based on AI analysis
    double blackspotProximity = calculateBlackspotProximity(
      currentData.latitude, 
      currentData.longitude, 
      blackspots
    );
    
    double driverBehavior = analyzeDriverBehavior(recentData);
    double hazardAssessment = assessRealTimeHazards(currentData, weather, currentTime);
    
    // User profile risk adjustment
    double profileRisk = _calculateProfileRisk(userProfile);
    
    // Weighted combination
    double finalRisk = (blackspotProximity * 0.4) +
                      (weather.riskFactor * 0.2) +
                      (driverBehavior * 0.2) +
                      (hazardAssessment * 0.1) +
                      (profileRisk * 0.1);
    
    // Convert to 0-10 scale
    return finalRisk * 10.0;
  }

  // Alert level classification
  static AlertLevel classifyAlertLevel(double riskScore) {
    if (riskScore >= 8.0) return AlertLevel.high;
    if (riskScore >= 5.0) return AlertLevel.medium;
    return AlertLevel.safe;
  }

  // Safety recommendations
  static List<String> generateSafetyRecommendations(
    double riskScore,
    WeatherData weather,
    SensorData currentData,
    List<AdvancedBlackspot> nearbyBlackspots,
  ) {
    List<String> recommendations = [];
    
    if (riskScore >= 8.0) {
      recommendations.add("⚠️ EXTREME CAUTION: Consider alternative route");
      recommendations.add("🚗 Reduce speed immediately");
      recommendations.add("📱 Alert emergency contact");
    } else if (riskScore >= 5.0) {
      recommendations.add("⚡ Moderate risk detected - drive carefully");
      recommendations.add("🐌 Maintain safe following distance");
    } else {
      recommendations.add("✅ Road conditions are favorable");
      recommendations.add("🛣️ Safe travels ahead");
    }
    
    // Weather-specific recommendations
    if (weather.condition == 'rain') {
      recommendations.add("🌧️ Wet roads - reduce speed by 20%");
      recommendations.add("💡 Turn on headlights");
    } else if (weather.condition == 'fog') {
      recommendations.add("🌫️ Low visibility - use fog lights");
      recommendations.add("👀 Maintain extra distance");
    }
    
    // Speed recommendations
    if (currentData.speed > 70) {
      recommendations.add("⬇️ Consider reducing speed");
    }
    
    // Blackspot warnings
    for (var blackspot in nearbyBlackspots) {
      double distance = _calculateDistance(
        currentData.latitude, 
        currentData.longitude, 
        blackspot.latitude, 
        blackspot.longitude
      );
      
      if (distance <= 200) {
        recommendations.add("⚠️ Approaching ${blackspot.title}");
        recommendations.add("📍 ${blackspot.description}");
      }
    }
    
    return recommendations;
  }

  // Helper methods
  static double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371000; // meters
    double dLat = (lat2 - lat1) * pi / 180;
    double dLng = (lng2 - lng1) * pi / 180;
    
    double a = sin(dLat / 2) * sin(dLat / 2) +
               cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
               sin(dLng / 2) * sin(dLng / 2);
    
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _calculateVariance(List<double> values) {
    if (values.isEmpty) return 0.0;
    
    double mean = values.reduce((a, b) => a + b).toDouble() / values.length;
    double sumSquaredDiffs = values
        .map((value) => pow(value - mean, 2))
        .reduce((a, b) => a + b).toDouble();
    
    return sumSquaredDiffs / values.length;
  }

  static double _calculateProfileRisk(UserProfile profile) {
    double risk = 0.0;
    
    // Experience factor
    switch (profile.driverExperience) {
      case 'beginner':
        risk += 0.3;
        break;
      case 'intermediate':
        risk += 0.1;
        break;
      case 'experienced':
        risk += 0.0;
        break;
      case 'professional':
        risk -= 0.1;
        break;
    }
    
    // Vehicle type factor
    switch (profile.vehicleType) {
      case 'two_wheeler':
        risk += 0.2;
        break;
      case 'truck':
        risk += 0.1;
        break;
      default:
        risk += 0.0;
    }
    
    return risk.clamp(0.0, 1.0);
  }
}

enum AlertLevel { safe, medium, high }

// Route planning model
class RouteOption {
  final String id;
  final String name;
  final double distance;
  final Duration estimatedTime;
  final double safetyScore;
  final List<AdvancedBlackspot> blackspotsOnRoute;
  final List<LatLng> waypoints;
  final String description;

  RouteOption({
    required this.id,
    required this.name,
    required this.distance,
    required this.estimatedTime,
    required this.safetyScore,
    required this.blackspotsOnRoute,
    required this.waypoints,
    required this.description,
  });
}

class LatLng {
  final double latitude;
  final double longitude;

  LatLng(this.latitude, this.longitude);
}