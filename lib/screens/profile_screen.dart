import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/notifications_provider.dart';
import '../providers/premium_provider.dart';
import '../providers/language_provider.dart';
import '../providers/medicine_provider.dart';
import '../providers/saved_medicines_provider.dart';
import '../providers/alerts_provider.dart';
import '../providers/support_provider.dart';

import 'edit_profile_screen.dart';
import 'notification_setting_screen.dart';
import 'reminder_preferences_screen.dart';
import 'auth_screens.dart'; // To log out to WelcomeScreen if needed
import 'appearance_screen.dart';
import 'privacy_security_screen.dart';
import 'support_screen.dart';
import 'premium_screen.dart';
import 'find_pharmacy_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showAccountCenterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 48),
                  Text(
                    context.l10n.t('accountCenter'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: AppColors.textDark),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage(
                          'https://randomuser.me/api/portraits/women/44.jpg',
                        ),
                      ),
                      title: Text(
                        "El joo",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.add, color: AppColors.textDark),
                      title: Text(
                        context.l10n.t('addAnotherAccount'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textDark,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context); // close bottom sheet
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      context.l10n.t('done'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  void _showAppearanceModeBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        Widget option({
          required IconData icon,
          required String label,
          required VoidCallback onTap,
        }) {
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primaryTeal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primaryTeal, size: 22),
            ),
            title: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            onTap: onTap,
          );
        }

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 48),
                    Text(
                      context.l10n.t('appearance'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: AppColors.textDark),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.backgroundCream,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        option(
                          icon: Icons.light_mode_rounded,
                          label: context.l10n.t('light'),
                          onTap: () => Navigator.pop(context),
                        ),
                        Divider(height: 1, indent: 64, color: Colors.grey[200]),
                        option(
                          icon: Icons.dark_mode_rounded,
                          label: context.l10n.t('dark'),
                          onTap: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          context.l10n.t('setting'),
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Row(
              children: [
                Consumer<UserProvider>(
                  builder: (context, userProvider, child) {
                    if (userProvider.imagePath != null) {
                      return CircleAvatar(
                        radius: 35,
                        backgroundImage: FileImage(
                          File(userProvider.imagePath!),
                        ),
                      );
                    }
                    return Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: userProvider.currentAvatarColor.withValues(
                          alpha: 0.15,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primaryTeal.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        userProvider.currentAvatarIcon,
                        color: userProvider.currentAvatarColor,
                        size: 36,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Consumer<UserProvider>(
                      builder: (context, userProvider, child) {
                        return Text(
                          context.l10n.t('helloName', {
                            'name': userProvider.name,
                          }),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        );
                      },
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditProfileScreen(),
                        ),
                      ),
                      child: Text(
                        context.l10n.t('editProfile'),
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.primaryTeal,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),

            _buildSectionHeader(context.l10n.t('profile')),
            _buildSettingsCard([
              _buildTile(
                icon: Icons.person_outline,
                title: context.l10n.t('accountCenter'),
                subtitle: context.l10n.t('manageAccountDetails'),
                onTap: () => _showAccountCenterBottomSheet(context),
              ),
            ]),

            const SizedBox(height: 24),
            _buildSectionHeader(context.l10n.t('remindersAlarm')),
            _buildSettingsCard([
              _buildTile(
                icon: Icons.notifications_none_rounded,
                title: context.l10n.t('notificationSettings'),
                subtitle: context.l10n.t('enableDisableNotifications'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationSettingScreen(),
                  ),
                ),
              ),
              const Divider(height: 1, indent: 56, color: Color(0xFFEEEEEE)),
              _buildTile(
                icon: Icons.volume_up_outlined,
                title: context.l10n.t('reminderPreferences'),
                subtitle: context.l10n.t('chooseReminderSound'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ReminderPreferencesScreen(),
                  ),
                ),
              ),
            ]),

            const SizedBox(height: 24),
            _buildSectionHeader(context.l10n.t('general')),
            _buildSettingsCard([
              Consumer<LanguageProvider>(
                builder: (context, languageProvider, child) {
                  final selectedLanguage = languageProvider.isArabic
                      ? context.l10n.t('arabic')
                      : context.l10n.t('english');
                  return _buildTile(
                    icon: Icons.language_rounded,
                    title: context.l10n.t('language'),
                    subtitle: context.l10n.t('selectedLanguage', {
                      'language': selectedLanguage,
                    }),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AppearanceScreen(),
                      ),
                    ),
                  );
                },
              ),
              const Divider(height: 1, indent: 56, color: Color(0xFFEEEEEE)),
              _buildTile(
                icon: Icons.remove_red_eye_outlined,
                title: context.l10n.t('appearance'),
                subtitle: context.l10n.t('chooseAppearanceMode'),
                onTap: () => _showAppearanceModeBottomSheet(context),
              ),
            ]),

            const SizedBox(height: 24),
            _buildSectionHeader(context.l10n.t('services')),
            _buildSettingsCard([
              Consumer<PremiumProvider>(
                builder: (context, premium, child) {
                  final isPremium = premium.isPremiumActive;
                  return _buildTile(
                    icon: isPremium
                        ? Icons.workspace_premium
                        : Icons.star_outline_rounded,
                    title: isPremium
                        ? context.l10n.t('premiumMembership')
                        : context.l10n.t('goPremium'),
                    subtitle: isPremium
                        ? context.l10n.t('managePremiumSubscription')
                        : context.l10n.t('unlockPremium'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PremiumScreen()),
                    ),
                  );
                },
              ),
              const Divider(height: 1, indent: 56, color: Color(0xFFEEEEEE)),
              _buildTile(
                icon: Icons.local_pharmacy_outlined,
                title: context.l10n.t('findPharmacy'),
                subtitle: context.l10n.t('findNearbyPharmacies'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FindPharmacyScreen()),
                ),
              ),
              const Divider(height: 1, indent: 56, color: Color(0xFFEEEEEE)),
              _buildTile(
                icon: Icons.support_agent_outlined,
                title: context.l10n.t('itSupport'),
                subtitle: context.l10n.t('contactSupport'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SupportScreen()),
                ),
              ),
            ]),

            const SizedBox(height: 24),
            _buildSectionHeader(context.l10n.t('debugTest')),
            _buildSettingsCard([
              _buildTile(
                icon: Icons.notifications_active_outlined,
                title: context.l10n.t('testInstantNotification'),
                subtitle: context.l10n.t('sendTestNotification'),
                onTap: () {
                  context
                      .read<NotificationsProvider>()
                      .testInstantNotification();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.l10n.t('testNotificationSent')),
                    ),
                  );
                },
              ),
              const Divider(height: 1, indent: 56, color: Color(0xFFEEEEEE)),
              _buildTile(
                icon: Icons.schedule_outlined,
                title: '${context.l10n.t('testDelayedNotification')} (30s)',
                subtitle: '${context.l10n.t('sendDelayedNotification')} (30s delay)',
                onTap: () async {
                  await context
                      .read<NotificationsProvider>()
                      .testNotificationAfterDelay();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Test notification scheduled for 30s from now. Please close/swipe away the app completely now!',
                        ),
                        duration: Duration(seconds: 5),
                      ),
                    );
                  }
                },
              ),
            ]),

            const SizedBox(height: 24),
            _buildSectionHeader(context.l10n.t('security')),
            _buildSettingsCard([
              _buildTile(
                icon: Icons.lock_outline_rounded,
                title: context.l10n.t('privacySecurity'),
                subtitle: context.l10n.t('managePasswordPrivacy'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PrivacySecurityScreen(),
                  ),
                ),
              ),
              const Divider(height: 1, indent: 56, color: Color(0xFFEEEEEE)),
              _buildTile(
                icon: Icons.logout_rounded,
                title: context.l10n.t('logout'),
                subtitle: context.l10n.t('signOutAccount'),
                isDestructive: true,
                onTap: () => _showLogoutDialog(context),
              ),
            ]),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          context.l10n.t('logout'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(context.l10n.t('logoutConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              context.l10n.t('cancel'),
              style: TextStyle(color: AppColors.textGrey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              Navigator.pop(context);

              // Capture states and providers before the async gap
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              final loggedOutText = context.l10n.t('loggedOut');

              UserProvider? userProv;
              MedicineProvider? medProv;
              SavedMedicinesProvider? savedMedProv;
              AlertsProvider? alertsProv;
              NotificationsProvider? notifProv;
              PremiumProvider? premiumProv;
              SupportProvider? supportProv;

              try { userProv = context.read<UserProvider>(); } catch (_) {}
              try { medProv = context.read<MedicineProvider>(); } catch (_) {}
              try { savedMedProv = context.read<SavedMedicinesProvider>(); } catch (_) {}
              try { alertsProv = context.read<AlertsProvider>(); } catch (_) {}
              try { notifProv = context.read<NotificationsProvider>(); } catch (_) {}
              try { premiumProv = context.read<PremiumProvider>(); } catch (_) {}
              try { supportProv = context.read<SupportProvider>(); } catch (_) {}

              // Perform logout cleanup across all providers
              try { userProv?.logout(); } catch (_) {}
              try { medProv?.clearLocalData(); } catch (_) {}
              try { savedMedProv?.clear(); } catch (_) {}
              try { alertsProv?.clear(); } catch (_) {}
              try {
                if (notifProv != null) {
                  await notifProv.clearAll();
                }
              } catch (_) {}
              try { premiumProv?.clear(); } catch (_) {}
              try { supportProv?.clear(); } catch (_) {}

              navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                (r) => false,
              );
              messenger.showSnackBar(
                SnackBar(
                  content: Text(loggedOutText),
                  backgroundColor: AppColors.primaryTeal,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              context.l10n.t('logout'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildSectionHeader(String title) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12, left: 4),
    child: Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
      ),
    ),
  );
}

Widget _buildSettingsCard(List<Widget> children) {
  return Container(
    decoration: BoxDecoration(
      color: AppColors.cardColor,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(children: children),
  );
}

Widget _buildTile({
  required IconData icon,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
  bool isDestructive = false,
}) {
  final color = isDestructive ? Colors.red : AppColors.textDark;
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textGrey.withValues(alpha: 0.5),
          ),
        ],
      ),
    ),
  );
}
