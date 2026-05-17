// lib/widgets/seller_bottom_nav_bar.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SellerBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const SellerBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Use secondary color (green) for seller theme
    final sellerColor = theme.colorScheme.secondary;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onTap,
        backgroundColor: Colors.transparent,
        elevation: 0,
        indicatorColor: sellerColor.withValues(alpha: 0.15),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: Icon(LucideIcons.store, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            selectedIcon: Icon(LucideIcons.store, color: sellerColor),
            label: 'My Shop',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.package, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            selectedIcon: Icon(LucideIcons.package, color: sellerColor),
            label: 'Products',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.barChart3, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            selectedIcon: Icon(LucideIcons.barChart3, color: sellerColor),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(LucideIcons.shoppingBag, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                if (currentIndex != 3) // Assuming 3 is orders
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error,
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.colorScheme.surface, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            selectedIcon: Icon(LucideIcons.shoppingBag, color: sellerColor),
            label: 'Orders',
          ),
        ],
      ),
    );
  }
}