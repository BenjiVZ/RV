import 'package:flutter/material.dart';

class AnimatedBottomNavItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  AnimatedBottomNavItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class AnimatedBottomNav extends StatefulWidget {
  final List<AnimatedBottomNavItem> items;

  const AnimatedBottomNav({
    super.key,
    required this.items,
  });

  @override
  State<AnimatedBottomNav> createState() => _AnimatedBottomNavState();
}

class _AnimatedBottomNavState extends State<AnimatedBottomNav>
    with SingleTickerProviderStateMixin {
  int? _activeIndex;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onItemTap(int index) {
    setState(() {
      if (_activeIndex == index) {
        _activeIndex = null;
        _controller.reverse();
      } else {
        _activeIndex = index;
        _controller.forward();
      }
    });

    // Execute the action after a short delay for visual feedback
    Future.delayed(const Duration(milliseconds: 200), () {
      widget.items[index].onTap();
      // Reset animation after action
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _activeIndex = null;
            _controller.reverse();
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              widget.items.length,
              (index) => _buildNavItem(index),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final item = widget.items[index];
    final isActive = _activeIndex == index;

    return GestureDetector(
      onTap: () => _onItemTap(index),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final scale = isActive ? _scaleAnimation.value : 1.0;
          final opacity = isActive ? _fadeAnimation.value : 1.0;

          return Transform.scale(
            scale: scale,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isActive
                    ? item.color.withOpacity(0.15)
                    : item.color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? item.color.withOpacity(0.4)
                      : item.color.withOpacity(0.15),
                  width: isActive ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isActive
                          ? item.color.withOpacity(opacity * 0.2)
                          : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: item.color.withOpacity(0.3 * opacity),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: Icon(
                      item.icon,
                      color: item.color,
                      size: isActive ? 26 : 24,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.label,
                    style: TextStyle(
                      color: isActive ? item.color : Colors.grey.shade700,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                      fontSize: isActive ? 13 : 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
