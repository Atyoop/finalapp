import 'package:flutter/material.dart';

class BatteryOptimizationHelper {
  BatteryOptimizationHelper._();

  /// Show a dialog explaining battery optimization for Chinese OEMs
  static void showDialog(BuildContext context) {
    showAdaptiveDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.battery_alert, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Expanded(child: Text('Battery & Permissions')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _section(
                'Why notifications may fail',
                'Xiaomi (MIUI/HyperOS), Oppo (ColorOS), Huawei (HarmonyOS/EMUI), '
                'Honor, Vivo (FuntouchOS), and Samsung aggressively kill background '
                'apps to save battery, which prevents scheduled alarms from firing.',
              ),
              const SizedBox(height: 16),
              _section(
                'Recommended steps',
                '1. Add app to Auto-Start list\n'
                '2. Disable battery optimization for this app\n'
                '3. Lock app in recent tasks (pull down on app card)\n'
                '4. Enable notification permissions\n'
                '5. Allow popup / float window permission',
              ),
              const SizedBox(height: 16),
              _section(
                'Xiaomi / Redmi / POCO (MIUI / HyperOS)',
                'Settings → Apps → Manage apps → DrugSafe\n'
                '→ Battery saver: No restrictions\n'
                '→ Show notifications: Allow\n'
                '→ Autostart: Toggle ON\n'
                '→ Pin app in Recents (long press app card → lock icon)',
              ),
              const SizedBox(height: 12),
              _section(
                'Oppo / Realme (ColorOS)',
                'Settings → Apps → App Management → DrugSafe\n'
                '→ Battery: Allow background activity\n'
                '→ Autostart: Toggle ON\n'
                '→ Floating notification: Allow',
              ),
              const SizedBox(height: 12),
              _section(
                'Huawei / Honor (EMUI / HarmonyOS)',
                'Settings → Apps → Apps → DrugSafe\n'
                '→ Battery: Close after screen lock → Not close\n'
                '→ App launch: Manage manually → Allow auto-launch, '
                'secondary launch, run in background\n'
                '→ Lock app in Recents',
              ),
              const SizedBox(height: 12),
              _section(
                'Samsung (One UI)',
                'Settings → Apps → DrugSafe → Battery\n'
                '→ Unrestricted (no optimization)\n'
                '→ Settings → Device care → Battery → App power management\n'
                '→ Add DrugSafe to "Never sleeping apps"',
              ),
              const SizedBox(height: 12),
              _section(
                'Vivo (FuntouchOS)',
                'Settings → Battery → Background app management\n'
                '→ DrugSafe → Allow background activity\n'
                '→ Settings → Apps → DrugSafe → Autostart: ON',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  static Widget _section(String title, String body) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          body,
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
      ],
    );
  }
}
