import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class BatteryOptimizationHelper {
  BatteryOptimizationHelper._();

  /// Show a dialog explaining battery optimization for Chinese OEMs
  static void showDialog(BuildContext context) {
    showAdaptiveDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.battery_alert, color: Colors.orange, size: 28),
            const SizedBox(width: 8),
            Expanded(child: Text(context.l10n.t('batteryPermissions'))),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _section(
                context.l10n.t('whyNotificationsFail'),
                context.l10n.t('batteryWhyBody'),
              ),
              const SizedBox(height: 16),
              _section(
                context.l10n.t('recommendedSteps'),
                context.l10n.t('batteryStepsBody'),
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
            child: Text(context.l10n.t('gotIt')),
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
        Text(body, style: const TextStyle(fontSize: 13, height: 1.4)),
      ],
    );
  }
}
