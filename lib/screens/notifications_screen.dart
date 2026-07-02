import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/alerts_provider.dart';
import '../providers/user_provider.dart';
import '../providers/language_provider.dart';
import '../main.dart';
import '../l10n/app_localizations.dart';
import '../models/alert.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String? _currentLanguage;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newLang = Provider.of<LanguageProvider>(context).currentLanguage;
    if (_currentLanguage != null && _currentLanguage != newLang) {
      _currentLanguage = newLang;
      _refreshAlerts();
    } else {
      _currentLanguage = newLang;
    }
  }

  Future<void> _loadNotifications() async {
    final alertsProvider = context.read<AlertsProvider>();
    final token = context.read<UserProvider>().token;

    if (token == null || token.isEmpty) {
      return;
    }

    // Fetch all alerts
    await alertsProvider.fetchAlerts(token);

    // Mark all as read
    await alertsProvider.markAllAlertsAsRead(token);
  }

  Future<void> _refreshAlerts() async {
    final alertsProvider = context.read<AlertsProvider>();
    final token = context.read<UserProvider>().token;

    if (token == null || token.isEmpty) {
      return;
    }

    await alertsProvider.fetchAlerts(token);
  }

  Future<void> _deleteAlert(int alertId) async {
    final alertsProvider = context.read<AlertsProvider>();
    final token = context.read<UserProvider>().token;

    if (token == null || token.isEmpty) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.t('deleteNotification')),
        content: Text(context.l10n.t('deleteNotificationConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              context.l10n.t('delete'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await alertsProvider.deleteAlert(token, alertId);
    }
  }

  Future<void> _deleteAllAlerts() async {
    final alertsProvider = context.read<AlertsProvider>();
    final token = context.read<UserProvider>().token;

    if (token == null || token.isEmpty) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.t('deleteAllNotifications')),
        content: Text(context.l10n.t('deleteAllNotificationsConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              context.l10n.t('deleteAll'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await alertsProvider.deleteAllAlerts(token);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.t('allNotificationsDeleted')),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return context.l10n.t('unknownTime');

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return context.l10n.t('justNow');
    } else if (difference.inMinutes < 60) {
      return context.l10n.t('minutesAgo', {'count': difference.inMinutes});
    } else if (difference.inHours < 24) {
      return context.l10n.t('hoursAgo', {'count': difference.inHours});
    } else if (difference.inDays < 7) {
      return context.l10n.t('daysAgo', {'count': difference.inDays});
    } else {
      return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    }
  }

  Color _getAlertTypeColor(String? type) {
    if (type == null) return Colors.grey;
    switch (type) {
      case 'TakenConfirmation':
        return Colors.green;
      case 'SkippedConfirmation':
        return Colors.blueGrey;
      case 'SnoozeReminder':
        return Colors.orange;
      case 'AdvanceReminder':
        return Colors.teal;
      case 'DoseReminder':
        return AppColors.primaryTeal;
      case 'MissedDose':
        return Colors.red;
      default:
        final lowerType = type.toLowerCase();
        if (lowerType.contains('warning')) {
          return Colors.orange;
        } else if (lowerType.contains('error') || lowerType.contains('critical')) {
          return Colors.red;
        } else if (lowerType.contains('success')) {
          return Colors.green;
        } else if (lowerType.contains('info') || lowerType.contains('reminder')) {
          return AppColors.primaryTeal;
        }
        return Colors.grey;
    }
  }

  IconData _getAlertTypeIcon(String? type) {
    if (type == null) return Icons.notifications_none;
    switch (type) {
      case 'TakenConfirmation':
        return Icons.check_circle_outline;
      case 'SkippedConfirmation':
        return Icons.remove_circle_outline;
      case 'SnoozeReminder':
        return Icons.snooze_rounded;
      case 'AdvanceReminder':
        return Icons.access_time;
      case 'DoseReminder':
        return Icons.notifications_active_outlined;
      case 'MissedDose':
        return Icons.error_outline;
      default:
        final lowerType = type.toLowerCase();
        if (lowerType.contains('warning')) {
          return Icons.warning_outlined;
        } else if (lowerType.contains('error') || lowerType.contains('critical')) {
          return Icons.error_outline;
        } else if (lowerType.contains('success')) {
          return Icons.check_circle_outline;
        } else if (lowerType.contains('info') || lowerType.contains('reminder')) {
          return Icons.notifications_outlined;
        }
        return Icons.notifications_none;
    }
  }

  String _getAlertTitle(Alert alert) {
    final type = alert.type;
    if (type != null) {
      switch (type) {
        case 'TakenConfirmation':
          return context.l10n.t('alertTakenConfirmation');
        case 'SkippedConfirmation':
          return context.l10n.t('alertSkippedConfirmation');
        case 'SnoozeReminder':
          return context.l10n.t('alertSnoozeReminder');
        case 'AdvanceReminder':
          return context.l10n.t('alertAdvanceReminder');
        case 'DoseReminder':
          return context.l10n.t('alertDoseReminder');
        case 'MissedDose':
          return context.l10n.t('alertMissedDose');
      }
    }
    final title = alert.title;
    if (title != null) {
      switch (title) {
        case 'TakenConfirmation':
          return context.l10n.t('alertTakenConfirmation');
        case 'SkippedConfirmation':
          return context.l10n.t('alertSkippedConfirmation');
        case 'SnoozeReminder':
          return context.l10n.t('alertSnoozeReminder');
        case 'AdvanceReminder':
          return context.l10n.t('alertAdvanceReminder');
        case 'DoseReminder':
          return context.l10n.t('alertDoseReminder');
        case 'MissedDose':
          return context.l10n.t('alertMissedDose');
        default:
          return title;
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundCream,
        elevation: 0,
        leading: IconButton(
          icon: const BackButtonIcon(),
          color: AppColors.textDark,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.l10n.t('notifications'),
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: Consumer<AlertsProvider>(
        builder: (context, alertsProvider, child) {
          if (alertsProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryTeal),
            );
          }

          if (alertsProvider.alerts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.t('noNotificationsYet'),
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Delete all button
              if (alertsProvider.alerts.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: alertsProvider.isDeletingAll
                          ? null
                          : _deleteAllAlerts,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primaryTeal,
                        side: BorderSide(
                          color: AppColors.primaryTeal.withValues(alpha: 0.55),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        disabledForegroundColor: Colors.grey,
                        disabledBackgroundColor: Colors.white,
                      ),
                      child: alertsProvider.isDeletingAll
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  AppColors.primaryTeal,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(context.l10n.t('deleteAllNotifications')),
                              ],
                            ),
                    ),
                  ),
                ),
              // Alerts list
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshAlerts,
                  color: AppColors.primaryTeal,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 8.0,
                    ),
                    itemCount: alertsProvider.alerts.length,
                    itemBuilder: (context, index) {
                      final alert = alertsProvider.alerts[index];
                      final typeColor = _getAlertTypeColor(alert.type);
                      final typeIcon = _getAlertTypeIcon(alert.type);
                      final accentColor = Color.lerp(
                        AppColors.primaryTeal,
                        typeColor,
                        0.25,
                      )!;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header: Icon, Title, and Delete Button
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Type icon
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: AppColors.backgroundCream,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(
                                      typeIcon,
                                      color: accentColor,
                                      size: 26,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  // Title and medication name
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (_getAlertTitle(alert).isNotEmpty)
                                          Text(
                                            _getAlertTitle(alert),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textDark,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        if (alert.medicationName != null &&
                                            alert.medicationName!.isNotEmpty)
                                          Text(
                                            alert.medicationName!,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textGrey,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Delete button
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: Colors.red.shade400,
                                      size: 20,
                                    ),
                                    onPressed: () => _deleteAlert(alert.id),
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Message
                              if (alert.message != null &&
                                  alert.message!.isNotEmpty)
                                Text(
                                  alert.message!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textGrey,
                                    height: 1.5,
                                  ),
                                ),
                              const SizedBox(height: 8),
                              // Footer: Time and read status
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.schedule_rounded,
                                        size: 13,
                                        color: AppColors.textGrey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatDateTime(alert.createdAt),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (!alert.isRead)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryTeal.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        context.l10n.t('newLabel'),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.primaryTeal,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
