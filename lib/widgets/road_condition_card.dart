import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/road_condition_detector.dart';

class RoadConditionCard extends StatefulWidget {
  final RoadConditionDetector detector;

  const RoadConditionCard({
    super.key,
    required this.detector,
  });

  @override
  State<RoadConditionCard> createState() => _RoadConditionCardState();
}

class _RoadConditionCardState extends State<RoadConditionCard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getConditionColor(RoadConditionLevel condition) {
    switch (condition) {
      case RoadConditionLevel.smooth:
        return Colors.green;
      case RoadConditionLevel.moderate:
        return Colors.orange;
      case RoadConditionLevel.rough:
        return Colors.red;
    }
  }

  String _getConditionText(RoadConditionLevel condition) {
    switch (condition) {
      case RoadConditionLevel.smooth:
        return 'Smooth Road';
      case RoadConditionLevel.moderate:
        return 'Moderate Bumps';
      case RoadConditionLevel.rough:
        return 'Rough Road';
    }
  }

  String _getConditionDescription(RoadConditionLevel condition) {
    switch (condition) {
      case RoadConditionLevel.smooth:
        return 'Road conditions are optimal for safe driving';
      case RoadConditionLevel.moderate:
        return 'Minor road irregularities detected - drive carefully';
      case RoadConditionLevel.rough:
        return 'Poor road conditions - reduce speed and increase following distance';
    }
  }

  IconData _getConditionIcon(RoadConditionLevel condition) {
    switch (condition) {
      case RoadConditionLevel.smooth:
        return Icons.check_circle;
      case RoadConditionLevel.moderate:
        return Icons.warning;
      case RoadConditionLevel.rough:
        return Icons.error;
    }
  }

  void _showRecommendations() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.directions_car,
                          color: _getConditionColor(widget.detector.currentCondition),
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Road Condition Tips',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _getConditionText(widget.detector.currentCondition),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _getConditionColor(widget.detector.currentCondition),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: ListView(
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.directions_car,
                                color: Colors.blue,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Driving Recommendations',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _getConditionColor(widget.detector.currentCondition).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getConditionColor(widget.detector.currentCondition).withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.lightbulb_outline,
                                      color: Colors.orange,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Current Condition Tips',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _getConditionDescription(widget.detector.currentCondition),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildStatisticRow('Vibration Level', '${widget.detector.averageVibration.toStringAsFixed(2)} g', Icons.show_chart),
                          _buildStatisticRow('Samples Analyzed', '${widget.detector.accelerometerData.length}', Icons.trending_up),
                          _buildStatisticRow('Detection Active', widget.detector.isMonitoring ? 'Yes' : 'No', Icons.warning_amber),
                          if (kIsWeb) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.withOpacity(0.3)),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.blue, size: 16),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Running in demo mode on web browser. Real sensor data available on mobile devices.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.tips_and_updates, size: 20),
                        label: const Text('Got it!'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _getConditionColor(widget.detector.currentCondition),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.blue,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.detector,
      builder: (context, child) {
        return ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  _getConditionColor(widget.detector.currentCondition).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _getConditionColor(widget.detector.currentCondition).withOpacity(0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: _getConditionColor(widget.detector.currentCondition).withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getConditionIcon(widget.detector.currentCondition),
                          color: _getConditionColor(widget.detector.currentCondition),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Road Condition',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.detector.isMonitoring ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.detector.isMonitoring 
                          ? (kIsWeb ? 'DEMO' : 'ACTIVE')
                          : 'INACTIVE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: widget.detector.isMonitoring ? Colors.green : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: _getConditionColor(widget.detector.currentCondition).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Icon(
                        Icons.tips_and_updates,
                        color: _getConditionColor(widget.detector.currentCondition),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getConditionText(widget.detector.currentCondition),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _getConditionColor(widget.detector.currentCondition),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Avg: ${widget.detector.averageVibration.toStringAsFixed(2)}g',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF717182),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _showRecommendations,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getConditionColor(widget.detector.currentCondition),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: const Text(
                        'Tips',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}