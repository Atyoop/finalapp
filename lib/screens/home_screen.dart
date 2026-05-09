import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../main.dart';
import '../providers/user_provider.dart';
import '../providers/medicine_provider.dart';
import '../providers/alerts_provider.dart';
import '../services/user_medications_service.dart';
import '../models/medicine.dart';
import 'chatbot_screen.dart';
import 'notifications_screen.dart';

// ─────────────────────────────────────────────
// Schedule Model
// ─────────────────────────────────────────────
class TodaySchedule {
  final int id;
  final int userMedId;
  final int medId;
  final String medName;
  final DateTime scheduledAt;
  final DateTime notificationTime;
  final String status;
  final bool reminderSent;
  final int snoozeCount;
  final bool hasInteractions;
  final List<Map<String, String>> interactions;

  TodaySchedule({
    required this.id,
    required this.userMedId,
    required this.medId,
    required this.medName,
    required this.scheduledAt,
    required this.notificationTime,
    required this.status,
    required this.reminderSent,
    required this.snoozeCount,
    required this.hasInteractions,
    required this.interactions,
  });

  factory TodaySchedule.fromJson(Map<String, dynamic> j) {
    final List<dynamic> rawInteractions =
        j['interactions'] as List<dynamic>? ?? [];
    final interactions = rawInteractions.map((i) {
      final m = i as Map<String, dynamic>;
      return {
        'withMedication': (m['withMedication'] ?? '').toString(),
        'reason': (m['reason'] ?? '').toString(),
      };
    }).toList();

    return TodaySchedule(
      id: j['id'] as int? ?? 0,
      userMedId: j['userMedId'] as int? ?? 0,
      medId: j['medId'] as int? ?? 0,
      medName: (j['medName'] ?? '').toString(),
      scheduledAt:
          DateTime.tryParse(j['scheduledAt']?.toString() ?? '') ??
          DateTime.now(),
      notificationTime:
          DateTime.tryParse(j['notificationTime']?.toString() ?? '') ??
          DateTime.now(),
      status: (j['status'] ?? 'Pending').toString(),
      reminderSent: j['reminderSent'] as bool? ?? false,
      snoozeCount: j['snoozeCount'] as int? ?? 0,
      hasInteractions: j['hasInteractions'] as bool? ?? false,
      interactions: interactions,
    );
  }

  TimeOfDay get timeOfDay => TimeOfDay(
    hour: scheduledAt.toLocal().hour,
    minute: scheduledAt.toLocal().minute,
  );

  bool get isTaken => status.toLowerCase() == 'taken';
  bool get isMissed => status.toLowerCase() == 'missed';
  bool get isPending => status.toLowerCase() == 'pending';
}

// ─────────────────────────────────────────────
// Home Screen
// ─────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

// Public so MainNavScreen can hold a GlobalKey<HomeScreenState> and call
// refreshSchedules() when the user switches back to the Today tab.
class HomeScreenState extends State<HomeScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  String? _errorMessage;
  List<TodaySchedule> _schedules = [];
  String? _filterStatus; // null = ALL

  /// Public method so the nav shell can trigger a refresh when the user
  /// switches back to the Today tab after editing a medicine.
  void refreshSchedules() {
    _fetchSchedulesForDate(_selectedDate);
  }

  final List<DateTime> _weeklyDates = List.generate(
    7,
    (index) => DateTime.now()
        .subtract(Duration(days: DateTime.now().weekday - 1))
        .add(Duration(days: index)),
  );

  String get _monthName => [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][_selectedDate.month - 1];

  @override
  void initState() {
    super.initState();
    // Fetch schedules for today on first load
    _fetchSchedulesForDate(_selectedDate);
    // Load unread alerts count
    _loadUnreadAlerts();
  }

  /// Load unread alerts count
  Future<void> _loadUnreadAlerts() async {
    final token = context.read<UserProvider>().token;
    if (token == null || token.isEmpty) {
      return;
    }
    await context.read<AlertsProvider>().fetchUnreadCount(token);
  }

  /// Format a DateTime to the API-required format: yyyy-MM-dd (zero-padded).
  String _formatDateForApi(DateTime date) {
    final y = date.year.toString();
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Fetch schedules for [date] from GET /api/users/me/schedules-by-date?date=yyyy-MM-dd.
  /// Replaces the old _fetchTodaySchedules that always hit today-schedules.
  Future<void> _fetchSchedulesForDate(DateTime date) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = context.read<UserProvider>().token;
      if (token == null || token.isEmpty) {
        setState(() {
          _errorMessage = 'Please sign in to view your schedules';
          _isLoading = false;
        });
        return;
      }

      final dateStr = _formatDateForApi(date);
      final uri = Uri.parse(
        'https://drugsafe.runasp.net/api/users/me/schedules-by-date',
      ).replace(queryParameters: {'date': dateStr});

      final res = await http
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(res.body) as List<dynamic>;
        setState(() {
          _schedules = data
              .map((e) => TodaySchedule.fromJson(e as Map<String, dynamic>))
              .toList();
          _isLoading = false;
        });
      } else if (res.statusCode == 401) {
        setState(() {
          _errorMessage = 'Authentication failed. Please sign in again.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load schedules (${res.statusCode}).';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error. Please check your connection.';
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsTaken(int scheduleId) async {
    try {
      final token = context.read<UserProvider>().token;
      if (token == null) return;

      final result = await SchedulesService.takeDose(token, scheduleId);

      if (result.succeeded) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result.lowStockAlertCreated
                    ? 'Dose marked as taken · Low stock alert created'
                    : 'Dose marked as taken',
              ),
              backgroundColor: Colors.green[700],
            ),
          );
        }
        // Refresh schedules for the currently selected date (not always today)
        await _fetchSchedulesForDate(_selectedDate);
        // Refresh My Meds so currentPillCount updates
        if (mounted) {
          await context.read<MedicineProvider>().fetchMedicinesFromApi(token);
          // Refresh unread alerts count
          await context.read<AlertsProvider>().refreshUnreadCount(token);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error ?? 'Failed to mark dose as taken'),
              backgroundColor: Colors.red[700],
            ),
          );
        }
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red[700]),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connection error. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Snooze a dose — called directly from the bottom sheet via callback.
  Future<void> _snoozeSchedule(int scheduleId) async {
    final token = context.read<UserProvider>().token;
    if (token == null) return;
    final messenger = ScaffoldMessenger.of(context);

    final result = await SchedulesService.snoozeDose(token, scheduleId);

    if (mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Reminder snoozed for 1 hour'),
          backgroundColor: Colors.orange[700],
        ),
      );
    }
    // Always refresh so the updated scheduledAt is reflected
    await _fetchSchedulesForDate(_selectedDate);
  }

  /// Skip a dose — called directly from the bottom sheet via callback.
  Future<void> _skipSchedule(int scheduleId) async {
    final token = context.read<UserProvider>().token;
    if (token == null) return;
    final messenger = ScaffoldMessenger.of(context);

    await SchedulesService.skipDose(token, scheduleId);

    if (mounted) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Dose skipped'),
          backgroundColor: Colors.blueGrey,
        ),
      );
    }
    // Refresh so the dose shows as Missed
    await _fetchSchedulesForDate(_selectedDate);
  }

  List<TodaySchedule> get _filtered {
    if (_filterStatus == null) return _schedules;
    return _schedules
        .where((s) => s.status.toLowerCase() == _filterStatus!.toLowerCase())
        .toList();
  }

  int _countByStatus(String status) => _schedules
      .where((s) => s.status.toLowerCase() == status.toLowerCase())
      .length;

  /// True when the calendar's selected date is calendar-today.
  bool get _isSelectedDateToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // ── Header ──
                  Consumer2<UserProvider, AlertsProvider>(
                    builder: (context, userProvider, alertsProvider, _) {
                      return Row(
                        children: [
                          if (userProvider.imagePath != null)
                            CircleAvatar(
                              radius: 25,
                              backgroundImage: FileImage(
                                File(userProvider.imagePath!),
                              ),
                            )
                          else
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: userProvider.currentAvatarColor
                                    .withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                userProvider.currentAvatarIcon,
                                color: userProvider.currentAvatarColor,
                                size: 28,
                              ),
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Hello, ${userProvider.name}",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                Text(
                                  "Welcome!",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Notifications icon with badge
                          Stack(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.notifications_outlined,
                                  color: AppColors.primaryTeal,
                                  size: 28,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const NotificationsScreen(),
                                    ),
                                  );
                                },
                                constraints: const BoxConstraints(
                                  minWidth: 48,
                                  minHeight: 48,
                                ),
                              ),
                              // Badge with unread count
                              if (alertsProvider.unreadCount > 0)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      alertsProvider.unreadCount > 99
                                          ? '99+'
                                          : alertsProvider.unreadCount
                                                .toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // ── Weekly Calendar label ──
                  Text(
                    _isSelectedDateToday
                        ? 'Today, $_monthName ${_selectedDate.day}'
                        : '$_monthName ${_selectedDate.day}, ${_selectedDate.year}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                        Icons.chevron_left,
                        color: AppColors.textGrey,
                        size: 20,
                      ),
                      ..._weeklyDates.map((date) => _buildDayItem(date)),
                      Icon(
                        Icons.chevron_right,
                        color: AppColors.textGrey,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // ── Title & Refresh ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _isSelectedDateToday
                            ? "Today's Medication"
                            : '$_monthName ${_selectedDate.day} Medication',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      if (!_isLoading)
                        GestureDetector(
                          onTap: () => _fetchSchedulesForDate(_selectedDate),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryTeal.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.refresh,
                              color: AppColors.primaryTeal,
                              size: 18,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Filter Chips ──
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _filterChip("ALL", _schedules.length, null),
                        _filterChip("Taken", _countByStatus('taken'), 'taken'),
                        _filterChip(
                          "Missed",
                          _countByStatus('missed'),
                          'missed',
                        ),
                        _filterChip(
                          "Pending",
                          _countByStatus('pending'),
                          'pending',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Content ──
                  if (_isLoading)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryTeal,
                          ),
                        ),
                      ),
                    )
                  else if (_errorMessage != null)
                    _buildErrorState()
                  else if (_filtered.isEmpty)
                    _buildEmptyState()
                  else
                    ..._filtered.map((s) {
                      final matched = context
                          .read<MedicineProvider>()
                          .medicines
                          .where((m) => m.id == s.userMedId.toString())
                          .firstOrNull;
                      return _ScheduleCard(
                        schedule: s,
                        matchedMedicine: matched,
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => _TakeDoseBottomSheet(
                              schedule: s,
                              matchedMedicine: matched,
                              onTakeSuccess: () => _markAsTaken(s.id),
                              onSnoozeSuccess: () => _snoozeSchedule(s.id),
                              onSkipSuccess: () => _skipSchedule(s.id),
                            ),
                          );
                        },
                      );
                    }),

                  const SizedBox(height: 100),
                ],
              ),
            ),

            // ── Floating Chatbot Button ──
            Positioned(
              bottom: 20,
              right: 24,
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChatbotScreen()),
                ),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2D6E72),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.smart_toy_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, int count, String? status) {
    final isSelected = _filterStatus == status;
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = status),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryTeal : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryTeal : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textGrey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : AppColors.primaryTeal.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Text(
                "$count",
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? Colors.white : AppColors.primaryTeal,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.medication_liquid_rounded,
            size: 120,
            color: AppColors.primaryTeal,
          ),
          const SizedBox(height: 24),
          Text(
            "No Medications Scheduled",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Add a medication to see it here.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textGrey.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'Something went wrong',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _fetchSchedulesForDate(_selectedDate),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayItem(DateTime date) {
    final isSelected =
        date.day == _selectedDate.day && date.month == _selectedDate.month;
    final weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return GestureDetector(
      onTap: () {
        setState(() => _selectedDate = date);
        _fetchSchedulesForDate(date);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                border: Border.all(
                  color: AppColors.primaryTeal.withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Column(
          children: [
            Text(
              weekdays[date.weekday - 1],
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? AppColors.textDark : AppColors.textGrey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "${date.day}",
              style: TextStyle(
                fontSize: 14,
                color: isSelected ? AppColors.textDark : AppColors.textGrey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Schedule Card
// ─────────────────────────────────────────────
class _ScheduleCard extends StatelessWidget {
  final TodaySchedule schedule;
  final Medicine? matchedMedicine;
  final VoidCallback onTap; // opens the bottom sheet

  const _ScheduleCard({
    required this.schedule,
    required this.matchedMedicine,
    required this.onTap,
  });

  Color get _statusColor {
    switch (schedule.status.toLowerCase()) {
      case 'taken':
        return Colors.green;
      case 'missed':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData get _statusIcon {
    switch (schedule.status.toLowerCase()) {
      case 'taken':
        return Icons.check_circle_rounded;
      case 'missed':
        return Icons.cancel_rounded;
      default:
        return Icons.access_time_rounded;
    }
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _getCountdown() {
    final now = DateTime.now();
    final scheduled = schedule.scheduledAt.toLocal();

    if (scheduled.isBefore(now)) {
      final diff = now.difference(scheduled);
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      return '${diff.inMinutes}m ago';
    }

    final diff = scheduled.difference(now);
    if (diff.inHours > 0) {
      return '${diff.inHours}h ${diff.inMinutes.remainder(60)}m';
    }
    return '${diff.inMinutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        child: Column(
          children: [
            // ── Main Card Content ──
            Padding(
              padding: const EdgeInsets.all(16),
              child: Stack(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Med Icon
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundCream,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.medication_rounded,
                          color: AppColors.primaryTeal,
                          size: 36,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name
                            Padding(
                              padding: const EdgeInsets.only(right: 80),
                              child: Text(
                                schedule.medName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),

                            // Scheduled Time
                            Row(
                              children: [
                                Icon(
                                  Icons.schedule,
                                  size: 13,
                                  color: AppColors.textGrey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatTime(schedule.scheduledAt),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textGrey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),

                            // Snooze info
                            if (schedule.snoozeCount > 0)
                              Row(
                                children: [
                                  Icon(
                                    Icons.snooze,
                                    size: 13,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Snoozed ${schedule.snoozeCount}x',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            // Compact status chip — visible for Taken/Missed;
                            // pending items show nothing (card tap opens modal)
                            if (!schedule.isPending)
                              Row(
                                children: [
                                  Icon(
                                    _statusIcon,
                                    color: _statusColor,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    schedule.status.toUpperCase(),
                                    style: TextStyle(
                                      color: _statusColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),

                            // ── Stock Warnings ──
                            if (matchedMedicine != null &&
                                matchedMedicine!.currentPillCount != null) ...[
                              const SizedBox(height: 6),
                              Builder(
                                builder: (context) {
                                  final stock =
                                      matchedMedicine!.currentPillCount!;
                                  final threshold =
                                      matchedMedicine!.lowStockThreshold;
                                  final needed =
                                      matchedMedicine!.pillsPerDose ?? 1;

                                  if (stock < needed) {
                                    return Text(
                                      'Not enough pills for this dose',
                                      style: TextStyle(
                                        color: Colors.red[700],
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  } else if (threshold != null &&
                                      stock <= threshold) {
                                    return Text(
                                      'Low stock ($stock left)',
                                      style: TextStyle(
                                        color: Colors.orange[800],
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  // ── Countdown Badge (top right) ──
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTeal,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getCountdown(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Interactions Warning ──
            if (schedule.hasInteractions) ...[
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFFF9800).withValues(alpha: 0.4),
                  ),
                ),
                child: Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 0,
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                    leading: const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFFF9800),
                      size: 20,
                    ),
                    title: Text(
                      '${schedule.interactions.length} Interaction${schedule.interactions.length > 1 ? 's' : ''} Detected',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE65100),
                      ),
                    ),
                    children: schedule.interactions.map((interaction) {
                      final withMed = interaction['withMedication'] ?? '';
                      final reason = interaction['reason'] ?? '';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(
                              0xFFFF9800,
                            ).withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.swap_horiz_rounded,
                              size: 16,
                              color: Color(0xFFFF9800),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    withMed,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    reason,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ],
        ), // Column
      ), // Container
    ); // GestureDetector
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Take Dose Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

/// Bottom sheet shown when the user taps a schedule card.
/// Displays dose details and Take / Snooze / Skip action buttons.
class _TakeDoseBottomSheet extends StatefulWidget {
  final TodaySchedule schedule;

  /// Matched medicine from MedicineProvider — used for stock / expiry / dose info.
  final dynamic matchedMedicine;

  /// Called when user taps Take. Parent handles API + refresh.
  final Future<void> Function() onTakeSuccess;

  /// Called when user taps Snooze. Parent handles API + refresh.
  final Future<void> Function() onSnoozeSuccess;

  /// Called when user taps Skip. Parent handles API + refresh.
  final Future<void> Function() onSkipSuccess;

  const _TakeDoseBottomSheet({
    required this.schedule,
    required this.matchedMedicine,
    required this.onTakeSuccess,
    required this.onSnoozeSuccess,
    required this.onSkipSuccess,
  });

  @override
  State<_TakeDoseBottomSheet> createState() => _TakeDoseBottomSheetState();
}

class _TakeDoseBottomSheetState extends State<_TakeDoseBottomSheet> {
  bool _isLoading = false;

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  // ── Action handlers ───────────────────────────────────────────────────────

  Future<void> _onTakeTapped() async {
    if (_isLoading) return;

    // ── Stock Check ──
    final med = widget.matchedMedicine as Medicine?;
    if (med != null && med.currentPillCount != null) {
      final needed = med.pillsPerDose ?? 1;
      if (med.currentPillCount! < needed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Not enough pills. Please update stock in My Meds first.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      await widget.onTakeSuccess();
      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red[700]),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connection error. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onSnoozeTapped() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await widget.onSnoozeSuccess();
      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.orange[700]),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connection error. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onSkipTapped() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await widget.onSkipSuccess();
      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red[700]),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connection error. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Info row widget ───────────────────────────────────────────────────────

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryTeal.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primaryTeal, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s = widget.schedule;
    final med = widget.matchedMedicine;

    // Pull extra info from matched medicine when available
    final int? currentPillCount = med?.currentPillCount as int?;
    final DateTime? expiryDate = med?.expiryDate as DateTime?;
    final int? pillsPerDose = med?.pillsPerDose as int?;
    final String? dosage = med?.dosage as String?;

    final bool alreadyHandled = !s.isPending;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Handle bar ──
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Header row ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Take Dose',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundCream,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      size: 18,
                      color: AppColors.textGrey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Medicine hero card ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundCream,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.medication_rounded,
                      color: AppColors.primaryTeal,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.medName,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        if (dosage != null && dosage.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            dosage,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textGrey,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Status chip for already-handled schedules
                  if (alreadyHandled)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: s.isTaken
                            ? Colors.green.withValues(alpha: 0.12)
                            : Colors.red.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        s.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: s.isTaken
                              ? Colors.green[700]
                              : Colors.red[700],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Info rows ──
            _infoRow(
              Icons.schedule_rounded,
              'Scheduled Time',
              _formatTime(s.scheduledAt),
            ),
            if (currentPillCount != null)
              _infoRow(
                Icons.inventory_2_outlined,
                'Stock Remaining',
                '$currentPillCount pill${currentPillCount != 1 ? 's' : ''} remaining',
              ),
            if (pillsPerDose != null)
              _infoRow(
                Icons.colorize_rounded,
                'Pills Per Dose',
                '$pillsPerDose pill${pillsPerDose != 1 ? 's' : ''} will be deducted',
              ),
            if (expiryDate != null)
              _infoRow(
                Icons.event_outlined,
                'Expiry Date',
                'Expires: ${_formatDate(expiryDate)}',
              ),
            const SizedBox(height: 24),

            // ── Stock Warning in Modal ──
            if (med != null && med.currentPillCount != null)
              Builder(
                builder: (context) {
                  final stock = med.currentPillCount!;
                  final needed = med.pillsPerDose ?? 1;
                  if (stock < needed) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_rounded,
                              color: Colors.red[700],
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Not enough pills for this dose. Please update stock in My Meds.',
                                style: TextStyle(
                                  color: Colors.red[900],
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

            // ── Snooze & Skip row (only for pending doses) ──
            if (!alreadyHandled) ...[
              Row(
                children: [
                  // Snooze button
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _onSnoozeTapped,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.orange,
                                ),
                              )
                            : const Icon(
                                Icons.snooze_rounded,
                                size: 18,
                                color: Colors.orange,
                              ),
                        label: const Text(
                          'Snooze',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.orange),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Skip button
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _onSkipTapped,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.redAccent,
                                ),
                              )
                            : const Icon(
                                Icons.skip_next_rounded,
                                size: 18,
                                color: Colors.redAccent,
                              ),
                        label: const Text(
                          'Skip',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.redAccent,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.redAccent),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // ── Take button ──
            SizedBox(
              width: double.infinity,
              height: 56,
              child: Builder(
                builder: (context) {
                  final stock = med?.currentPillCount;
                  final needed = med?.pillsPerDose ?? 1;
                  final canTake = stock == null || stock >= needed;

                  return ElevatedButton(
                    onPressed: alreadyHandled || _isLoading || !canTake
                        ? null
                        : _onTakeTapped,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: alreadyHandled
                          ? Colors.grey[300]
                          : const Color(0xFF2E7D32),
                      disabledBackgroundColor: alreadyHandled
                          ? Colors.grey[300]
                          : !canTake
                          ? Colors.red[200]
                          : const Color(0xFF2E7D32).withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            alreadyHandled
                                ? s.status.toUpperCase()
                                : !canTake
                                ? 'Update stock first'
                                : 'Take Dose',
                            style: TextStyle(
                              color: alreadyHandled
                                  ? AppColors.textGrey
                                  : Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
