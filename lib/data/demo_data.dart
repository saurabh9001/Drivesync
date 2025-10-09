import 'dart:convert';
import '../models/advanced_models.dart';
import '../models/user_profile.dart';
import '../models/location.dart';

class DemoData {
  // Maharashtra coordinates - Pune region5515645508
  static const Location maharashtraCenter = Location(18.5204, 73.8567);

  // Demo weather data for different conditions
  static List<Map<String, dynamic>> get weatherData => [
    {
      "condition": "clear",
      "temperature": 28.5,
      "humidity": 55.0,
      "windSpeed": 12.0,
      "visibility": 2500.0,
      "precipitationProbability": 0.1,
      "timestamp": DateTime.now().toIso8601String()
    },
    {
      "condition": "rain",
      "temperature": 24.0,
      "humidity": 85.0,
      "windSpeed": 25.0,
      "visibility": 800.0,
      "precipitationProbability": 0.8,
      "timestamp": DateTime.now().add(Duration(hours: 1)).toIso8601String()
    },
    {
      "condition": "fog",
      "temperature": 20.0,
      "humidity": 95.0,
      "windSpeed": 5.0,
      "visibility": 200.0,
      "precipitationProbability": 0.3,
      "timestamp": DateTime.now().add(Duration(hours: 2)).toIso8601String()
    },
    {
      "condition": "storm",
      "temperature": 22.0,
      "humidity": 90.0,
      "windSpeed": 45.0,
      "visibility": 500.0,
      "precipitationProbability": 0.95,
      "timestamp": DateTime.now().add(Duration(hours: 3)).toIso8601String()
    }
  ];

  // Demo sensor data with realistic Maharashtra coordinates
  static List<Map<String, dynamic>> get sensorData => [
    {
      "latitude": 18.5204,
      "longitude": 73.8567,
      "speed": 45.2,
      "direction": 90.0,
      "acceleration": 0.5,
      "gyroscopeX": 0.1,
      "gyroscopeY": -0.2,
      "gyroscopeZ": 0.05,
      "timestamp": DateTime.now().toIso8601String()
    },
    {
      "latitude": 18.5314,
      "longitude": 73.8456,
      "speed": 52.8,
      "direction": 125.0,
      "acceleration": 1.2,
      "gyroscopeX": 0.3,
      "gyroscopeY": 0.1,
      "gyroscopeZ": -0.1,
      "timestamp": DateTime.now().subtract(Duration(seconds: 30)).toIso8601String()
    },
    {
      "latitude": 18.5125,
      "longitude": 73.8678,
      "speed": 38.5,
      "direction": 180.0,
      "acceleration": -0.8,
      "gyroscopeX": -0.2,
      "gyroscopeY": 0.4,
      "gyroscopeZ": 0.2,
      "timestamp": DateTime.now().subtract(Duration(minutes: 1)).toIso8601String()
    }
  ];

  // Demo blackspots with real Maharashtra locations
  static List<Map<String, dynamic>> get blackspotsData => [
    {
      "id": "BS001",
      "latitude": 18.5204,
      "longitude": 73.8567,
      "severity": "fatal",
      "type": "highway",
      "title": "Pune-Mumbai Expressway Junction",
      "description": "High-speed collision zone with multiple fatalities. Sharp curves and poor visibility during monsoon.",
      "riskScore": 9.2,
      "fatalAccidents": 8,
      "seriousInjuries": 15,
      "minorIncidents": 32,
      "riskFactors": ["High speed traffic", "Poor lighting", "Sharp curves", "Heavy vehicle zone", "Monsoon flooding"],
      "lastUpdated": DateTime.now().subtract(Duration(days: 2)).toIso8601String()
    },
    {
      "id": "BS002",
      "latitude": 18.5314,
      "longitude": 73.8456,
      "severity": "serious",
      "type": "junction",
      "title": "FC Road - JM Road Intersection",
      "description": "Complex 6-way intersection with frequent signal failures and pedestrian crossings.",
      "riskScore": 7.8,
      "fatalAccidents": 2,
      "seriousInjuries": 12,
      "minorIncidents": 28,
      "riskFactors": ["Signal malfunction", "Pedestrian crossing", "Multiple lanes", "Traffic congestion", "Street vendors"],
      "lastUpdated": DateTime.now().subtract(Duration(days: 1)).toIso8601String()
    },
    {
      "id": "BS003",
      "latitude": 18.5125,
      "longitude": 73.8678,
      "severity": "minor",
      "type": "school",
      "title": "Fergusson College Road - School Zone",
      "description": "Active school zone with children crossing during peak hours (7-9 AM, 3-5 PM).",
      "riskScore": 4.5,
      "fatalAccidents": 0,
      "seriousInjuries": 3,
      "minorIncidents": 18,
      "riskFactors": ["School hours", "Children crossing", "Speed bumps", "Narrow road", "Parked vehicles"],
      "lastUpdated": DateTime.now().subtract(Duration(hours: 6)).toIso8601String()
    },
    {
      "id": "BS004",
      "latitude": 18.5423,
      "longitude": 73.8234,
      "severity": "serious",
      "type": "construction",
      "title": "Baner-Pashan Link Road Construction",
      "description": "Active construction zone with frequent lane changes and heavy machinery.",
      "riskScore": 8.1,
      "fatalAccidents": 3,
      "seriousInjuries": 9,
      "minorIncidents": 21,
      "riskFactors": ["Lane merging", "Construction vehicles", "Reduced visibility", "Uneven surface", "Dust"],
      "lastUpdated": DateTime.now().subtract(Duration(hours: 12)).toIso8601String()
    },
    {
      "id": "BS005",
      "latitude": 18.4965,
      "longitude": 73.8312,
      "severity": "fatal",
      "type": "urban",
      "title": "Sinhagad Road Flyover",
      "description": "Steep gradient flyover with frequent accidents during rain. High traffic density area.",
      "riskScore": 8.9,
      "fatalAccidents": 6,
      "seriousInjuries": 18,
      "minorIncidents": 35,
      "riskFactors": ["Steep gradient", "Wet road issues", "High traffic density", "Speed variations", "Vehicle breakdown zone"],
      "lastUpdated": DateTime.now().subtract(Duration(hours: 18)).toIso8601String()
    },
    {
      "id": "BS006",
      "latitude": 18.5654,
      "longitude": 73.7890,
      "severity": "serious",
      "type": "highway",
      "title": "Katraj Ghat - Hairpin Bend",
      "description": "Dangerous hairpin bends on mountain road with poor guardrails.",
      "riskScore": 7.6,
      "fatalAccidents": 4,
      "seriousInjuries": 11,
      "minorIncidents": 19,
      "riskFactors": ["Hairpin bends", "Mountain road", "Poor guardrails", "Brake failure zone", "Fog conditions"],
      "lastUpdated": DateTime.now().subtract(Duration(days: 3)).toIso8601String()
    },
    {
      "id": "BS007",
      "latitude": 18.5089,
      "longitude": 73.9012,
      "severity": "minor",
      "type": "urban",
      "title": "Koregaon Park Main Road",
      "description": "High pedestrian traffic area with restaurants and shops. Frequent jaywalking.",
      "riskScore": 5.2,
      "fatalAccidents": 1,
      "seriousInjuries": 5,
      "minorIncidents": 24,
      "riskFactors": ["Pedestrian jaywalking", "Restaurant zone", "Parallel parking", "Narrow lanes", "Night traffic"],
      "lastUpdated": DateTime.now().subtract(Duration(hours: 4)).toIso8601String()
    },
    {
      "id": "BS008",
      "latitude": 18.4678,
      "longitude": 73.8567,
      "severity": "serious",
      "type": "junction",
      "title": "Warje-Karve Nagar Bridge",
      "description": "Bridge with merging traffic from multiple directions. Poor lane markings.",
      "riskScore": 6.9,
      "fatalAccidents": 2,
      "seriousInjuries": 8,
      "minorIncidents": 16,
      "riskFactors": ["Traffic merging", "Poor lane markings", "Bridge structure", "Speed differential", "Heavy vehicles"],
      "lastUpdated": DateTime.now().subtract(Duration(days: 1, hours: 6)).toIso8601String()
    }
  ];

  // Sample incidents data for reporting and analysis
  static List<Map<String, dynamic>> get incidentsData => [
    {
      "id": "INC001",
      "latitude": 18.5204,
      "longitude": 73.8567,
      "type": "accident",
      "severity": "serious",
      "description": "Two-vehicle collision at junction. Minor injuries reported.",
      "timestamp": DateTime.now().subtract(Duration(hours: 2)).toIso8601String(),
      "reportedBy": "traffic_police",
      "vehiclesInvolved": 2,
      "injuriesReported": 1,
      "weatherCondition": "clear",
      "trafficCondition": "heavy",
      "roadCondition": "good"
    },
    {
      "id": "INC002",
      "latitude": 18.5314,
      "longitude": 73.8456,
      "type": "breakdown",
      "severity": "minor",
      "description": "Vehicle breakdown blocking left lane during rush hour.",
      "timestamp": DateTime.now().subtract(Duration(minutes: 45)).toIso8601String(),
      "reportedBy": "user_report",
      "vehiclesInvolved": 1,
      "injuriesReported": 0,
      "weatherCondition": "clear",
      "trafficCondition": "heavy",
      "roadCondition": "good"
    },
    {
      "id": "INC003",
      "latitude": 18.5125,
      "longitude": 73.8678,
      "type": "road_hazard",
      "severity": "minor",
      "description": "Large pothole causing vehicle damage. Multiple reports received.",
      "timestamp": DateTime.now().subtract(Duration(hours: 6)).toIso8601String(),
      "reportedBy": "multiple_users",
      "vehiclesInvolved": 0,
      "injuriesReported": 0,
      "weatherCondition": "rain",
      "trafficCondition": "moderate",
      "roadCondition": "poor"
    }
  ];

  // Demo user profiles for testing
  static List<Map<String, dynamic>> get demoUserProfiles => [
    {
      "name": "Demo User",
      "email": "demo.user@email.com",
      "phone": "+91 9876543210",
      "emergencyContact": "+91 9876543211",
      "emergencyContactName": "XYZ",
      "driverExperience": "experienced",
      "vehicleType": "car",
      "enableSoundAlerts": true,
      "enableVibrationAlerts": true,
      "alertSensitivity": 7.0,
      "routePreference": "balanced"
    },
    {
      "name": "User A",
      "email": "usera@email.com",
      "phone": "+91 9876543212",
      "emergencyContact": "+91 9876543213",
      "emergencyContactName": "Emergency Contact A",
      "driverExperience": "beginner",
      "vehicleType": "two_wheeler",
      "enableSoundAlerts": true,
      "enableVibrationAlerts": true,
      "alertSensitivity": 9.0,
      "routePreference": "safest"
    },
    {
      "name": "User B",
      "email": "userb@email.com",
      "phone": "+91 9876543214",
      "emergencyContact": "+91 9876543215",
      "emergencyContactName": "Emergency Contact B",
      "driverExperience": "professional",
      "vehicleType": "truck",
      "enableSoundAlerts": true,
      "enableVibrationAlerts": false,
      "alertSensitivity": 5.0,
      "routePreference": "fastest"
    }
  ];

  // Route suggestions with real Maharashtra roads
  static List<Map<String, dynamic>> get routeSuggestions => [
    {
      "id": "route_001",
      "name": "Pune-Mumbai via Expressway",
      "startLat": 18.5204,
      "startLng": 73.8567,
      "endLat": 19.0760,
      "endLng": 72.8777,
      "distance": 149.2,
      "estimatedTime": "2h 45m",
      "safetyScore": 7.8,
      "blackspotsCount": 3,
      "tollCost": 385,
      "fuelCost": 890,
      "waypoints": [
        {"lat": 18.5204, "lng": 73.8567, "name": "Pune Start"},
        {"lat": 18.6298, "lng": 73.7997, "name": "Lonavala"},
        {"lat": 18.9067, "lng": 73.0167, "name": "Khopoli"},
        {"lat": 19.0760, "lng": 72.8777, "name": "Mumbai End"}
      ]
    },
    {
      "id": "route_002",
      "name": "Pune-Nashik via NH50",
      "startLat": 18.5204,
      "startLng": 73.8567,
      "endLat": 19.9975,
      "endLng": 73.7898,
      "distance": 165.8,
      "estimatedTime": "3h 20m",
      "safetyScore": 6.2,
      "blackspotsCount": 5,
      "tollCost": 185,
      "fuelCost": 985,
      "waypoints": [
        {"lat": 18.5204, "lng": 73.8567, "name": "Pune Start"},
        {"lat": 18.8314, "lng": 73.7903, "name": "Alephata"},
        {"lat": 19.2183, "lng": 73.7898, "name": "Ahmednagar"},
        {"lat": 19.9975, "lng": 73.7898, "name": "Nashik End"}
      ]
    }
  ];

  // Traffic patterns for different times
  static Map<String, dynamic> get trafficPatterns => {
    "rush_hour_morning": {
      "timeRange": "07:00-10:00",
      "trafficMultiplier": 2.5,
      "riskMultiplier": 1.8,
      "averageSpeed": 25.0,
      "description": "Heavy traffic with frequent stops"
    },
    "rush_hour_evening": {
      "timeRange": "17:00-21:00",
      "trafficMultiplier": 2.8,
      "riskMultiplier": 2.1,
      "averageSpeed": 22.0,
      "description": "Peak traffic with aggressive driving"
    },
    "normal_hours": {
      "timeRange": "10:00-17:00",
      "trafficMultiplier": 1.0,
      "riskMultiplier": 1.0,
      "averageSpeed": 45.0,
      "description": "Normal traffic flow"
    },
    "night_hours": {
      "timeRange": "21:00-07:00",
      "trafficMultiplier": 0.3,
      "riskMultiplier": 1.5,
      "averageSpeed": 55.0,
      "description": "Low traffic but reduced visibility"
    }
  };

  // Emergency services data
  static List<Map<String, dynamic>> get emergencyServices => [
    {
      "type": "police",
      "name": "Pune City Police Control Room",
      "phone": "100",
      "location": {"lat": 18.5204, "lng": 73.8567},
      "responseTime": "8-12 minutes"
    },
    {
      "type": "ambulance",
      "name": "108 Emergency Ambulance",
      "phone": "108",
      "location": {"lat": 18.5314, "lng": 73.8456},
      "responseTime": "10-15 minutes"
    },
    {
      "type": "fire",
      "name": "Fire Brigade Pune",
      "phone": "101",
      "location": {"lat": 18.5125, "lng": 73.8678},
      "responseTime": "12-18 minutes"
    },
    {
      "type": "highway_patrol",
      "name": "Highway Police Patrol",
      "phone": "1033",
      "location": {"lat": 18.4965, "lng": 73.8312},
      "responseTime": "15-25 minutes"
    }
  ];

  // Method to get sample data in JSON format
  static String get allDataAsJson {
    final Map<String, dynamic> allData = {
      "weatherData": weatherData,
      "sensorData": sensorData,
      "blackspotsData": blackspotsData,
      "incidentsData": incidentsData,
      "demoUserProfiles": demoUserProfiles,
      "routeSuggestions": routeSuggestions,
      "trafficPatterns": trafficPatterns,
      "emergencyServices": emergencyServices,
      "maharashtraCenter": {
        "latitude": maharashtraCenter.latitude,
        "longitude": maharashtraCenter.longitude
      }
    };
    
    return jsonEncode(allData);
  }

  // Helper methods to create model objects from demo data
  static List<AdvancedBlackspot> getBlackspots() {
    return blackspotsData.map((data) {
      return AdvancedBlackspot(
        id: data['id'],
        latitude: data['latitude'],
        longitude: data['longitude'],
        severity: _parseSeverity(data['severity']),
        type: _parseType(data['type']),
        title: data['title'],
        description: data['description'],
        riskScore: data['riskScore'],
        fatalAccidents: data['fatalAccidents'],
        seriousInjuries: data['seriousInjuries'],
        minorIncidents: data['minorIncidents'],
        riskFactors: List<String>.from(data['riskFactors']),
        lastUpdated: DateTime.parse(data['lastUpdated']),
      );
    }).toList();
  }

  static WeatherData getCurrentWeather() {
    final weatherMap = weatherData.first;
    return WeatherData(
      condition: weatherMap['condition'],
      temperature: weatherMap['temperature'],
      humidity: weatherMap['humidity'],
      windSpeed: weatherMap['windSpeed'],
      visibility: weatherMap['visibility'],
      precipitationProbability: weatherMap['precipitationProbability'],
    );
  }

  static UserProfile getDefaultUserProfile() {
    final profileMap = demoUserProfiles.first;
    return UserProfile.fromJson(profileMap);
  }

  static BlackspotSeverity _parseSeverity(String severity) {
    switch (severity) {
      case 'fatal':
        return BlackspotSeverity.fatal;
      case 'serious':
        return BlackspotSeverity.serious;
      case 'minor':
        return BlackspotSeverity.minor;
      default:
        return BlackspotSeverity.minor;
    }
  }

  static BlackspotType _parseType(String type) {
    switch (type) {
      case 'junction':
        return BlackspotType.junction;
      case 'highway':
        return BlackspotType.highway;
      case 'urban':
        return BlackspotType.urban;
      case 'construction':
        return BlackspotType.construction;
      case 'school':
        return BlackspotType.school;
      default:
        return BlackspotType.urban;
    }
  }
}