import "package:flutter/material.dart";

// Custom widgets for smooth animations and improved UI

class AnimatedFadeSlide extends StatelessWidget {
  const AnimatedFadeSlide({
    super.key,
    required this.child,
    required this.index,
  });

  final Widget child;
  final int index;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + (index * 100)),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 30),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class HoverEffect extends StatefulWidget {
  const HoverEffect({super.key, required this.child});

  final Widget child;

  @override
  State<HoverEffect> createState() => HoverEffectState();
}

class HoverEffectState extends State<HoverEffect> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          decoration: _isHovered
              ? BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                )
              : null,
          child: widget.child,
        ),
      ),
    );
  }

  void _setHovered(bool value) {
    if (mounted) {
      setState(() => _isHovered = value);
    }
  }
}


class SidebarItem extends StatelessWidget {
  const SidebarItem({
    super.key,
    required this.icon,
    required this.label,
    this.isActive = false,
    this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    return HoverEffect(
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive 
            ? Colors.white 
            : (isDestructive ? const Color(0xFFEF4444) : const Color(0xFF94A3B8)),
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isActive 
              ? Colors.white 
              : (isDestructive ? const Color(0xFFEF4444).withValues(alpha: 0.7) : const Color(0xFFE2E8F0)),
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        trailing: isActive 
          ? Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            )
          : null,
        onTap: onTap,
      ),
    );
  }
}