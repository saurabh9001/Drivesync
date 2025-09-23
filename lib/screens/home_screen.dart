import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../models/user_profile.dart';
import '../models/advanced_models.dart';
import 'dashboard_screen.dart';

// This is now a simplified home screen that just wraps the dashboard
class HomeScreen extends StatelessWidget {
  final double riskScore;
  final UserProfile? userProfile;
  final bool isTracking;
  final VoidCallback onToggleTracking;
  final AlertLevel alertLevel;
  final List<String> recommendations;
  final AIService aiService;

  const HomeScreen({
    super.key,
    required this.riskScore,
    required this.userProfile,
    required this.isTracking,
    required this.onToggleTracking,
    required this.alertLevel,
    required this.recommendations,
    required this.aiService,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardScreen(
      riskScore: riskScore,
      userProfile: userProfile,
      isTracking: isTracking,
      onToggleTracking: onToggleTracking,
      alertLevel: alertLevel,
      recommendations: recommendations,
      aiService: aiService,
    );
  }
}