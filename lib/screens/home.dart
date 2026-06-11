import 'package:flutter/material.dart';
import '../main.dart';
import '../l10n/app_localizations.dart';
import 'home_screen.dart';
import 'interaction_screen.dart';
import 'saved_medicines_screen.dart';
import 'add_medicine_screen.dart';
import 'profile_screen.dart';

// =============================================================================
// MAIN NAVIGATION SHELL — Bottom Nav with 5 tabs
// =============================================================================
class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});
  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _currentIndex = 0;

  /// Key lets us call HomeScreen's public refreshSchedules() whenever the
  /// user switches back to the Today tab after editing a medicine.
  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeScreen(key: _homeKey),
      const SavedMedicinesScreen(),
      const CheckInteractionsScreen(),
      const AddMedicineScreen(),
      const ProfileScreen(),
    ];
  }

  void _onTabTapped(int index) {
    // When switching back to Today (index 0), refresh schedules so statuses
    // (Taken/Missed) are never overwritten with stale Pending data.
    if (index == 0 && _currentIndex != 0) {
      _homeKey.currentState?.refreshSchedules();
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: context.l10n.t('today'),
                isActive: _currentIndex == 0,
                onTap: () => _onTabTapped(0),
              ),
              _NavItem(
                icon: Icons.medication_outlined,
                activeIcon: Icons.medication_rounded,
                label: context.l10n.t('myMeds'),
                isActive: _currentIndex == 1,
                onTap: () => _onTabTapped(1),
              ),
              // Center Scan Button (slightly different styling if desired)
              _NavItem(
                icon: Icons.document_scanner_outlined,
                activeIcon: Icons.document_scanner_rounded,
                label: context.l10n.t('checkMeds'),
                isActive: _currentIndex == 2,
                onTap: () => _onTabTapped(2),
              ),
              _NavItem(
                icon: Icons.add_box_outlined,
                activeIcon: Icons.add_box_rounded,
                label: context.l10n.t('addMeds'),
                isActive: _currentIndex == 3,
                onTap: () => _onTabTapped(3),
              ),
              _NavItem(
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings_rounded,
                label: context.l10n.t('setting'),
                isActive: _currentIndex == 4,
                onTap: () => _onTabTapped(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Bottom Nav Item ---
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? activeIcon : icon,
            color: isActive
                ? AppColors.primaryTeal
                : AppColors.textGrey.withValues(alpha: 0.6),
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive
                  ? AppColors.primaryTeal
                  : AppColors.textGrey.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
