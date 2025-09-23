import 'package:flutter/material.dart';

class SafeWayLogo extends StatelessWidget {
  final double size;
  final Color? color;
  final bool showText;

  const SafeWayLogo({
    super.key,
    this.size = 32.0,
    this.color,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    final logoColor = color ?? Theme.of(context).primaryColor;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                logoColor,
                logoColor.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: logoColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Road lines
              Positioned(
                left: size * 0.15,
                top: size * 0.3,
                child: Container(
                  width: size * 0.7,
                  height: size * 0.08,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(size * 0.04),
                  ),
                ),
              ),
              Positioned(
                left: size * 0.15,
                top: size * 0.62,
                child: Container(
                  width: size * 0.7,
                  height: size * 0.08,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(size * 0.04),
                  ),
                ),
              ),
              // Center divider (dashed line)
              ...List.generate(3, (index) => Positioned(
                left: size * 0.2 + (index * size * 0.2),
                top: size * 0.46,
                child: Container(
                  width: size * 0.08,
                  height: size * 0.08,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(size * 0.04),
                  ),
                ),
              )),
              // AI Shield
              Positioned(
                right: size * 0.15,
                top: size * 0.15,
                child: Container(
                  width: size * 0.3,
                  height: size * 0.3,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(size * 0.05),
                  ),
                  child: Icon(
                    Icons.security,
                    size: size * 0.2,
                    color: logoColor,
                  ),
                ),
              ),
              // Warning indicator
              Positioned(
                left: size * 0.1,
                bottom: size * 0.1,
                child: Container(
                  width: size * 0.25,
                  height: size * 0.25,
                  decoration: const BoxDecoration(
                    color: Colors.amber,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning,
                    size: size * 0.15,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showText) ...[
          SizedBox(width: size * 0.3),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SafeWay AI',
                style: TextStyle(
                  fontSize: size * 0.5,
                  fontWeight: FontWeight.bold,
                  color: logoColor,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'AI-Powered Safety',
                style: TextStyle(
                  fontSize: size * 0.3,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class AnimatedSafeWayLogo extends StatefulWidget {
  final double size;
  final Color? color;
  final bool showText;

  const AnimatedSafeWayLogo({
    super.key,
    this.size = 32.0,
    this.color,
    this.showText = true,
  });

  @override
  State<AnimatedSafeWayLogo> createState() => _AnimatedSafeWayLogoState();
}

class _AnimatedSafeWayLogoState extends State<AnimatedSafeWayLogo>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _rotateController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _rotateAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_rotateController);
    
    _pulseController.repeat(reverse: true);
    _rotateController.repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _rotateAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: SafeWayLogo(
            size: widget.size,
            color: widget.color,
            showText: widget.showText,
          ),
        );
      },
    );
  }
}