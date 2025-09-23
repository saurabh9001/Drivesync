import 'package:flutter/material.dart';

class WeatherColors {
  static Color getWeatherColor(String condition) {
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