import 'package:flutter/material.dart';

class AiTipsCard extends StatelessWidget {
  final int dataPoints;
  
  const AiTipsCard({
    super.key,
    required this.dataPoints,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF030213),
            Color(0xFF1a1a2e),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: Colors.yellow,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'AI Safety Insight',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Advanced AI algorithms are continuously analyzing your driving patterns, environmental conditions, and road safety data to provide real-time risk assessment.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.analytics,
                color: Colors.blue,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Processing $dataPoints/50 data points',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xCCFFFFFF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}