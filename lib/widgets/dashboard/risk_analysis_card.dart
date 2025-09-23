import 'package:flutter/material.dart';

class RiskAnalysisCard extends StatelessWidget {
  final double riskScore;
  final Color riskColor;
  final String riskLevel;
  final String riskMessage;

  const RiskAnalysisCard({
    super.key,
    required this.riskScore,
    required this.riskColor,
    required this.riskLevel,
    required this.riskMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Color.fromRGBO(
              riskColor.red,
              riskColor.green,
              riskColor.blue,
              0.05,
            ),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color.fromRGBO(
            riskColor.red,
            riskColor.green,
            riskColor.blue,
            0.2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(
              riskColor.red,
              riskColor.green,
              riskColor.blue,
              0.1,
            ),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AI Risk Analysis',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              _LiveIndicator(),
            ],
          ),
          const SizedBox(height: 20),
          _RiskScoreIndicator(
            riskScore: riskScore,
            riskColor: riskColor,
          ),
          const SizedBox(height: 20),
          _RiskLevelIndicator(
            riskLevel: riskLevel,
            riskColor: riskColor,
          ),
          const SizedBox(height: 12),
          Text(
            riskMessage,
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
}

class _LiveIndicator extends StatelessWidget {
  const _LiveIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(33, 150, 243, 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'LIVE',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.blue,
        ),
      ),
    );
  }
}

class _RiskScoreIndicator extends StatelessWidget {
  final double riskScore;
  final Color riskColor;

  const _RiskScoreIndicator({
    required this.riskScore,
    required this.riskColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 140,
          height: 140,
          child: CircularProgressIndicator(
            value: riskScore / 10.0,
            strokeWidth: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(riskColor),
          ),
        ),
        Column(
          children: [
            Text(
              riskScore.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: riskColor,
              ),
            ),
            Text(
              '/10',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RiskLevelIndicator extends StatelessWidget {
  final String riskLevel;
  final Color riskColor;

  const _RiskLevelIndicator({
    required this.riskLevel,
    required this.riskColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Color.fromRGBO(
          riskColor.red,
          riskColor.green,
          riskColor.blue,
          0.1,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        riskLevel,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: riskColor,
        ),
      ),
    );
  }
}