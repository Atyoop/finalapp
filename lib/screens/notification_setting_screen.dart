import 'package:flutter/material.dart';
import '../main.dart';

class NotificationSettingScreen extends StatefulWidget {
  const NotificationSettingScreen({super.key});

  @override
  State<NotificationSettingScreen> createState() => _NotificationSettingScreenState();
}

class _NotificationSettingScreenState extends State<NotificationSettingScreen> {
  bool _appNotification = true;
  bool _vibration = true;
  bool _showOnLockScreen = true;
  String _notificationSound = "Default app sound";

  void _showSoundBottomSheet() {
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
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 48),
                  const Text("Notification Sound", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  IconButton(icon: const Icon(Icons.close, color: AppColors.textDark), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Center(child: Text("Default app sound", style: TextStyle(fontSize: 16, color: AppColors.textDark))),
                onTap: () {
                  setState(() => _notificationSound = "Default app sound");
                  Navigator.pop(context);
                },
              ),
              const Divider(height: 1, indent: 24, endIndent: 24),
              ListTile(
                title: const Center(child: Text("Silent", style: TextStyle(fontSize: 16, color: AppColors.textGrey))),
                onTap: () {
                  setState(() => _notificationSound = "Silent");
                  Navigator.pop(context);
                },
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text("Done", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
          "Notification Setting",
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildActionCard(
              icon: Icons.notifications_active_outlined,
              title: "Notification Sound",
              subtitle: "Change How notifications Sound.",
              onTap: _showSoundBottomSheet,
            ),
            const SizedBox(height: 16),
            _buildToggleCard(
              icon: Icons.phone_android_rounded,
              title: "App Notification",
              subtitle: "Receive mobile app notifications.",
              value: _appNotification,
              onChanged: (v) => setState(() => _appNotification = v),
            ),
            const SizedBox(height: 16),
            _buildToggleCard(
              icon: Icons.vibration_rounded,
              title: "Vibration",
              subtitle: "Vibrate device when a reminder is due.",
              value: _vibration,
              onChanged: (v) => setState(() => _vibration = v),
            ),
            const SizedBox(height: 16),
            _buildToggleCard(
              icon: Icons.screen_lock_portrait_rounded,
              title: "Show on lock screen",
              subtitle: "Display medication reminder on lock screen.",
              value: _showOnLockScreen,
              onChanged: (v) => setState(() => _showOnLockScreen = v),
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
