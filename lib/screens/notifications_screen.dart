import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/alerts_provider.dart';
import '../providers/user_provider.dart';
import '../main.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    _loadNotifications();
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
        title: const Text('Delete Notification'),
        content: const Text(
          'Are you sure you want to delete this notification?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
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
        title: const Text('Delete All Notifications'),
        content: const Text(
          'This will delete all notifications. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete All',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await alertsProvider.deleteAllAlerts(token);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications deleted'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Unknown time';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    }
  }

  Color _getAlertTypeColor(String? type) {
    final lowerType = type?.toLowerCase() ?? '';
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

  IconData _getAlertTypeIcon(String? type) {
    final lowerType = type?.toLowerCase() ?? '';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
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
                    'No notifications yet',
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
                  padding: const EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: alertsProvider.isDeletingAll
                          ? null
                          : _deleteAllAlerts,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.withValues(alpha: 0.1),
                        foregroundColor: Colors.red,
                        disabledForegroundColor: Colors.grey,
                        disabledBackgroundColor: Colors.grey.withValues(
                          alpha: 0.1,
                        ),
                      ),
                      child: alertsProvider.isDeletingAll
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.red),
                              ),
                            )
                          : const Text('Delete All Notifications'),
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
                      horizontal: 12.0,
                      vertical: 8.0,
                    ),
                    itemCount: alertsProvider.alerts.length,
                    itemBuilder: (context, index) {
                      final alert = alertsProvider.alerts[index];
                      final typeColor = _getAlertTypeColor(alert.type);
                      final typeIcon = _getAlertTypeIcon(alert.type);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12.0),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey[200]!, width: 1),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header: Icon, Title, and Delete Button
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Type icon
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: typeColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      typeIcon,
                                      color: typeColor,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Title and medication name
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (alert.title != null &&
                                            alert.title!.isNotEmpty)
                                          Text(
                                            alert.title!,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
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
                                              color: Colors.grey[600],
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
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
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
                                    color: AppColors.textDark.withValues(
                                      alpha: 0.8,
                                    ),
                                    height: 1.5,
                                  ),
                                ),
                              const SizedBox(height: 8),
                              // Footer: Time and read status
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDateTime(alert.createdAt),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
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
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'New',
                                        style: TextStyle(
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
