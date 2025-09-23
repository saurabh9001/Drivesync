import 'package:flutter/material.dart';
import 'animated_nav_item.dart';

class ModernNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onIndexChanged;

  const ModernNavBar({
    super.key,
    required this.selectedIndex,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 25,
            offset: const Offset(0, -8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: const Color(0xFF4285F4).withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Container(
        height: 80, // Slightly increased height
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              index: 0,
              icon: Icons.dashboard_outlined,
              activeIcon: Icons.dashboard_rounded,
              label: 'Home',
              badge: null,
            ),
            _buildNavItem(
              index: 1,
              icon: Icons.map_outlined,
              activeIcon: Icons.map_rounded,
              label: 'Map',
              badge: null,
            ),
            _buildNavItem(
              index: 2,
              icon: Icons.settings_outlined,
              activeIcon: Icons.settings_rounded,
              label: 'Settings',
              badge: null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    String? badge,
  }) {
    final isSelected = selectedIndex == index;
    
    return Expanded(
      child: AnimatedNavItem(
        icon: isSelected ? activeIcon : icon,
        label: label,
        selected: isSelected,
        onTap: () => onIndexChanged(index),
      ),
    );
  }
}