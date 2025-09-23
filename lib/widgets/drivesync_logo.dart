import 'package:flutter/material.dart';

class DriveSyncLogo extends StatefulWidget {
  final double size;
  final bool showText;
  final bool animate;

  const DriveSyncLogo({
    super.key,
    this.size = 40,
    this.showText = true,
    this.animate = false,
  });

  @override
  State<DriveSyncLogo> createState() => _DriveSyncLogoState();
}

class _DriveSyncLogoState extends State<DriveSyncLogo>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    if (widget.animate) {
      _rotationController.repeat();
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Enhanced Logo Container with animations
        AnimatedBuilder(
          animation: Listenable.merge([_rotationAnimation, _pulseAnimation]),
          builder: (context, child) {
            return Transform.scale(
              scale: widget.animate ? _pulseAnimation.value : 1.0,
              child: Transform.rotate(
                angle: widget.animate ? _rotationAnimation.value * 2 * 3.14159 : 0.0,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF2D2D2D),
                        Color(0xFF1A1A1A),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(widget.size * 0.25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: widget.size * 0.2,
                        offset: Offset(0, widget.size * 0.1),
                      ),
                      BoxShadow(
                        color: const Color(0xFF4285F4).withOpacity(0.3),
                        blurRadius: widget.size * 0.15,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  child: CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: EnhancedDriveSyncLogoPainter(
                      animationValue: widget.animate ? _rotationAnimation.value : 0.0,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        if (widget.showText) ...[
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'DriveSync',
                style: TextStyle(
                  color: const Color(0xFF2D2D2D),
                  fontSize: widget.size * 0.6,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  height: 1.0,
                ),
              ),
              Text(
                'Smart Drive Monitor',
                style: TextStyle(
                  color: const Color(0xFF4285F4),
                  fontSize: widget.size * 0.25,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class EnhancedDriveSyncLogoPainter extends CustomPainter {
  final double animationValue;

  EnhancedDriveSyncLogoPainter({this.animationValue = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final padding = w * 0.15;
    
    // Create the infinity symbol path
    final path = createInfinityPath(size, padding);
    
    // Draw shadow layer
    canvas.save();
    canvas.translate(1, 2);
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.12
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawPath(path, shadowPaint);
    canvas.restore();

    // Draw the white base layer
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.14
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, whitePaint);

    // Create animated gradient
    final gradientColors = [
      const Color(0xFF4285F4),
      const Color(0xFF34A853),
      const Color(0xFF4285F4),
    ];
    
    final gradientStops = [
      0.0,
      0.5 + (animationValue * 0.5),
      1.0,
    ];

    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: gradientColors,
      stops: gradientStops,
    );

    // Draw the blue gradient layer
    final bluePaint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.10
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, bluePaint);

    // Add glowing effect
    final glowPaint = Paint()
      ..color = const Color(0xFF4285F4).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.06
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    
    canvas.drawPath(path, glowPaint);

    // Add center highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, w * 0.08, highlightPaint);
  }

  Path createInfinityPath(Size size, double padding) {
    final w = size.width - (padding * 2);
    final h = size.height - (padding * 2);
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final loopRadius = w * 0.25;
    
    final path = Path();
    
    // Left loop
    final leftCenter = Offset(centerX - loopRadius * 0.8, centerY);
    path.addOval(Rect.fromCenter(
      center: leftCenter,
      width: loopRadius * 1.6,
      height: loopRadius * 1.6,
    ));
    
    // Right loop
    final rightCenter = Offset(centerX + loopRadius * 0.8, centerY);
    path.addOval(Rect.fromCenter(
      center: rightCenter,
      width: loopRadius * 1.6,
      height: loopRadius * 1.6,
    ));
    
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is EnhancedDriveSyncLogoPainter &&
        oldDelegate.animationValue != animationValue;
  }
}