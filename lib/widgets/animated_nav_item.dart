import 'package:flutter/material.dart';

class AnimatedNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const AnimatedNavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF4285F4);
    final inactiveColor = const Color(0xFF9CA3AF);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 70, // Slightly increased height
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon Container with simple animation
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: 46, // Slightly larger width
              height: 46, // Slightly larger height
              decoration: BoxDecoration(
                color: selected
                    ? primaryColor.withOpacity(0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(13), // Slightly larger radius
              ),
              child: Icon(
                icon,
                color: selected ? primaryColor : inactiveColor,
                size: 26, // Slightly larger icon size
              ),
            ),
            // Label with simple color animation - single line only
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? primaryColor : inactiveColor,
                fontSize: 13, // Slightly increased font size
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: 0.3,
                height: 1.0, // Tight line height
              ),
            ),
          ],
        ),
      ),
    );
  }
}
