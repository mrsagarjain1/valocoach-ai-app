import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    _NavItem(icon: Icons.home_rounded, label: 'HOME'),
    _NavItem(icon: Icons.bar_chart_rounded, label: 'STATS'),
    _NavItem(icon: Icons.military_tech_rounded, label: 'PASS'),
    _NavItem(icon: Icons.settings_rounded, label: 'MORE'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68 + MediaQuery.of(context).padding.bottom,
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        border: const Border(top: BorderSide(color: AppTheme.borderColor, width: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(_items.length, (i) {
            final selected = currentIndex == i;
            return Expanded(
              child: GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon with indicator pill
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          if (selected)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              width: 44,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryRed.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          Icon(
                            _items[i].icon,
                            size: 22,
                            color: selected ? AppTheme.primaryRed : AppTheme.textMuted,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _items[i].label,
                        style: AppTheme.krona(
                          size: 8,
                          color: selected ? AppTheme.primaryRed : AppTheme.textMuted,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
