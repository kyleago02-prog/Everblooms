// lib/widgets/bottom_nav_bar.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.06),
            spreadRadius: 0,
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: primary.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      child: Theme(
        data: theme.copyWith(
          navigationBarTheme: NavigationBarThemeData(
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final isSelected = states.contains(WidgetState.selected);
              return TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? primary
                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              );
            }),
          ),
        ),
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: onTap,
          backgroundColor: Colors.transparent,
          elevation: 0,
          animationDuration: const Duration(milliseconds: 300),
          indicatorColor: primary.withValues(alpha: 0.12),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: Icon(LucideIcons.home,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5), size: 22),
              selectedIcon: Icon(LucideIcons.home, color: primary, size: 22),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(LucideIcons.search,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5), size: 22),
              selectedIcon: Icon(LucideIcons.search, color: primary, size: 22),
              label: 'Search',
            ),
            NavigationDestination(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(LucideIcons.shoppingBag,
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5), size: 22),
                  if (currentIndex != 2)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: theme.colorScheme.surface, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              selectedIcon: Icon(LucideIcons.shoppingBag, color: primary, size: 22),
              label: 'Orders',
            ),
            NavigationDestination(
              icon: Icon(LucideIcons.user,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5), size: 22),
              selectedIcon: Icon(LucideIcons.user, color: primary, size: 22),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}