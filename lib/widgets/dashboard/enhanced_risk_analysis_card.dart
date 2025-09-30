import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/advanced_models.dart';
import '../../services/ai_service.dart';

class EnhancedRiskAnalysisCard extends StatefulWidget {
  final double riskScore;
  final String riskLevel;
  final String riskMessage;
  final Color riskColor;
  final AIService aiService;

  const EnhancedRiskAnalysisCard({
    super.key,
    required this.riskScore,
    required this.riskLevel,
    required this.riskMessage,
    required this.riskColor,
    required this.aiService,
  });

  @override
  State<EnhancedRiskAnalysisCard> createState() => _EnhancedRiskAnalysisCardState();
}

class _EnhancedRiskAnalysisCardState extends State<EnhancedRiskAnalysisCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  SensorData? _currentSensorData;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
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
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Color.fromRGBO(
              widget.riskColor.red,
              widget.riskColor.green,
              widget.riskColor.blue,
              0.1,
            ),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with live indicator and sensor toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'AI Risk Analysis',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  _buildSensorToggle(),
                  const SizedBox(width: 8),
                  _buildLiveIndicator(),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Main risk score display
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: widget.riskScore >= 7 ? _pulseAnimation.value : 1.0,
                child: _buildRiskScoreIndicator(),
              );
            },
          ),
          
          const SizedBox(height: 20),
          
          // Risk level indicator
          _buildRiskLevelIndicator(),
          
          const SizedBox(height: 12),
          
          // Risk message
          Text(
            widget.riskMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF717182),
            ),
          ),
          

        ],
      ),
    );
  }

  Widget _buildSensorToggle() {
    return GestureDetector(
      onTap: () {
        widget.aiService.setUseRealSensors(!widget.aiService.useRealSensors);
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: widget.aiService.useRealSensors 
              ? Colors.green.withOpacity(0.1)
              : Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.aiService.useRealSensors ? Icons.sensors : Icons.developer_mode,
              size: 12,
              color: widget.aiService.useRealSensors ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 4),
            Text(
              widget.aiService.useRealSensors ? 'REAL' : 'DEMO',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: widget.aiService.useRealSensors ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveIndicator() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(33, 150, 243, 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(_animationController.value),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'LIVE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRiskScoreIndicator() {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 140,
          height: 140,
          child: CircularProgressIndicator(
            value: widget.riskScore / 10.0,
            strokeWidth: 8,
            backgroundColor: widget.riskColor.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(widget.riskColor),
          ),
        ),
        Column(
          children: [
            Text(
              widget.riskScore.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: widget.riskColor,
              ),
            ),
            const Text(
              'Risk Score',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF717182),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRiskLevelIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Color.fromRGBO(
          widget.riskColor.red,
          widget.riskColor.green,
          widget.riskColor.blue,
          0.1,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        widget.riskLevel,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: widget.riskColor,
        ),
      ),
    );
  }




}