import 'package:flutter/material.dart';
import '../main.dart';

class ReminderPreferencesScreen extends StatefulWidget {
  const ReminderPreferencesScreen({super.key});

  @override
  State<ReminderPreferencesScreen> createState() => _ReminderPreferencesScreenState();
}

class _ReminderPreferencesScreenState extends State<ReminderPreferencesScreen> {
  bool _earlyReminder = true;
  bool _missedDose = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Reminder Preferences",
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildActionCard(
              icon: Icons.alarm_rounded,
              title: "Snooze Duration",
              subtitle: "select your Preferred snooze time.",
              onTap: () {},
            ),
            const SizedBox(height: 16),
            _buildToggleCard(
              icon: Icons.phone_android_rounded,
              title: "Early Reminder Alert",
              subtitle: "An alert before your medication is due.",
              value: _earlyReminder,
              onChanged: (v) => setState(() => _earlyReminder = v),
            ),
            const SizedBox(height: 16),
            _buildToggleCard(
              icon: Icons.notifications_active_outlined,
              title: "Missed Dose Notifications",
              subtitle: "If a dose isn't marked within 30 minutes.",
              value: _missedDose,
              onChanged: (v) => setState(() => _missedDose = v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textDark, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.textGrey.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleCard({required IconData icon, required String title, required String subtitle, required bool value, required ValueChanged<bool> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textDark, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: AppColors.primaryTeal,
          ),
        ],
      ),
    );
  }
}
