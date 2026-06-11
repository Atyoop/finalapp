import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart' as intl;
import '../main.dart';
import '../l10n/app_localizations.dart';
import '../providers/user_provider.dart';
import '../providers/medicine_provider.dart';
import '../providers/alerts_provider.dart';
import '../providers/notifications_provider.dart';
import '../providers/language_provider.dart';
import '../services/language_service.dart';
import '../services/user_medications_service.dart';
import '../models/medicine.dart';
import '../utils/quantity_helpers.dart';
import 'chatbot_screen.dart';
import 'notifications_screen.dart';
import '../widgets/interaction_warning_badge.dart';
import '../widgets/interaction_bottom_sheet.dart';

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
  String? _currentLanguage;

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

  String _formatDisplayDate(DateTime date, {bool includeYear = false}) {
    final locale = _currentLanguage == 'ar' ? 'ar' : 'en';
    final pattern = includeYear ? 'MMMM d, y' : 'MMMM d';
    return intl.DateFormat(pattern, locale).format(date);
  }

  @override
  void initState() {
    super.initState();
    // Fetch schedules for today on first load
    _fetchSchedulesForDate(_selectedDate);
    // Load unread alerts count
    _loadUnreadAlerts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newLang = Provider.of<LanguageProvider>(context).currentLanguage;
    if (_currentLanguage != null && _currentLanguage != newLang) {
      _currentLanguage = newLang;
      _fetchSchedulesForDate(_selectedDate);
      _loadUnreadAlerts();
    } else {
      _currentLanguage = newLang;
    }
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

  /// Fetch schedules for [date].
  /// Uses today-schedules for calendar-today and schedules-by-date otherwise.
  Future<void> _fetchSchedulesForDate(DateTime date) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = context.read<UserProvider>().token;
      if (token == null || token.isEmpty) {
        setState(() {
          _errorMessage = context.l10n.t('pleaseSignInSchedules');
          _isLoading = false;
        });
        return;
      }

      final uri = _isToday(date)
          ? LanguageService.appendLanguageQuery(
              Uri.parse(
                'https://drugsafe.runasp.net/api/users/me/today-schedules',
              ),
            )
          : LanguageService.appendLanguageQuery(
              Uri.parse(
                'https://drugsafe.runasp.net/api/users/me/schedules-by-date',
              ),
              {'date': _formatDateForApi(date)},
            );

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
          _errorMessage = context.l10n.t('authenticationFailedSignIn');
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = context.l10n.t('failedToLoadSchedules', {
            'code': res.statusCode,
          });
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = context.l10n.t('networkErrorConnection');
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsTaken(int scheduleId) async {
    try {
      final token = context.read<UserProvider>().token;
      if (token == null) return;
      final medicineProvider = context.read<MedicineProvider>();
      final alertsProvider = context.read<AlertsProvider>();
      final notificationsProvider = context.read<NotificationsProvider>();
      final locale = context.read<LanguageProvider>().currentLanguage;
      final schedule = _schedules.where((s) => s.id == scheduleId).firstOrNull;
      final matchedMedicine = schedule == null
          ? null
          : medicineProvider.medicines
                .where((m) => m.id == schedule.userMedId.toString())
                .firstOrNull;

      final result = await SchedulesService.takeDose(token, scheduleId);

      if (result.succeeded) {
        final remaining = result.remainingQuantity ?? result.remainingPills;
        final unit = result.quantityUnit ?? matchedMedicine?.quantityUnit;
        if (remaining != null && matchedMedicine != null) {
          await medicineProvider.updateStockLocally(
            matchedMedicine.id,
            remaining,
          );
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                remaining != null
                    ? '${context.l10n.t('doseTaken')} ${remainingQuantityLabel(remaining, unit, locale: locale)}'
                    : result.lowStockAlertCreated
                    ? context.l10n.t('doseMarkedTakenLowStock')
                    : context.l10n.t('doseMarkedTaken'),
              ),
              backgroundColor: Colors.green[700],
            ),
          );
        }
        // Refresh schedules for the currently selected date (not always today)
        await _fetchSchedulesForDate(_selectedDate);
        // Refresh My Meds so currentPillCount updates
        if (mounted) {
          await medicineProvider.fetchMedicinesFromApi(token);
          // Refresh unread alerts count
          await alertsProvider.refreshUnreadCount(token);
          // Refresh notifications
          await notificationsProvider.refreshNotifications(token);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result.error ?? context.l10n.t('failedMarkDoseTaken'),
              ),
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
          SnackBar(
            content: Text(context.l10n.t('connectionErrorTryAgain')),
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
          content: Text(result.message ?? context.l10n.t('reminderSnoozed')),
          backgroundColor: Colors.orange[700],
        ),
      );
    }
    // Always refresh so the updated scheduledAt is reflected
    await _fetchSchedulesForDate(_selectedDate);
    // Refresh notifications
    if (mounted) {
      await context.read<NotificationsProvider>().refreshNotifications(token);
    }
  }

  /// Skip a dose — called directly from the bottom sheet via callback.
  Future<void> _skipSchedule(int scheduleId) async {
    final token = context.read<UserProvider>().token;
    if (token == null) return;
    final messenger = ScaffoldMessenger.of(context);

    await SchedulesService.skipDose(token, scheduleId);

    if (mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(context.l10n.t('doseSkipped')),
          backgroundColor: Colors.blueGrey,
        ),
      );
    }
    // Refresh so the dose shows as Missed
    await _fetchSchedulesForDate(_selectedDate);
    // Refresh notifications
    if (mounted) {
      await context.read<NotificationsProvider>().refreshNotifications(token);
    }
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
    return _isToday(_selectedDate);
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
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
                                  context.l10n.t('helloName', {
                                    'name': userProvider.name,
                                  }),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                Text(
                                  context.l10n.t('welcome'),
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
                        ? context.l10n.t('todayDate', {
                            'date': _formatDisplayDate(_selectedDate),
                          })
                        : _formatDisplayDate(_selectedDate, includeYear: true),
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
                        Directionality.of(context) == TextDirection.rtl
                            ? Icons.chevron_right
                            : Icons.chevron_left,
                        color: AppColors.textGrey,
                        size: 20,
                      ),
                      ..._weeklyDates.map((date) => _buildDayItem(date)),
                      Icon(
                        Directionality.of(context) == TextDirection.rtl
                            ? Icons.chevron_left
                            : Icons.chevron_right,
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
                            ? context.l10n.t('todaysMedication')
                            : context.l10n.t('medicationForDate', {
                                'date': _formatDisplayDate(_selectedDate),
                              }),
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
                        _filterChip(
                          context.l10n.t('all'),
                          _schedules.length,
                          null,
                        ),
                        _filterChip(
                          context.l10n.t('taken'),
                          _countByStatus('taken'),
                          'taken',
                        ),
                        _filterChip(
                          context.l10n.t('missed'),
                          _countByStatus('missed'),
                          'missed',
                        ),
                        _filterChip(
                          context.l10n.t('pending'),
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
            context.l10n.t('noMedicationsScheduled'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.t('addMedicationToSeeHere'),
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
            _errorMessage ?? context.l10n.t('somethingWentWrong'),
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
            label: Text(context.l10n.t('retry')),
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
    if (diff.inHours >= 24) {
      return '${diff.inDays}d ${diff.inHours.remainder(24)}h';
    }
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
                                (matchedMedicine!.currentQuantity ??
                                        matchedMedicine!.currentPillCount) !=
                                    null) ...[
                              const SizedBox(height: 6),
                              Builder(
                                builder: (context) {
                                  final locale = context
                                      .read<LanguageProvider>()
                                      .currentLanguage;
                                  final stock =
                                      matchedMedicine!.currentQuantity ??
                                      matchedMedicine!.currentPillCount!;
                                  final threshold =
                                      matchedMedicine!.lowStockThreshold;
                                  final needed =
                                      matchedMedicine!.doseQuantity ??
                                      matchedMedicine!.pillsPerDose ??
                                      1;
                                  final unit = matchedMedicine!.quantityUnit;

                                  if (stock < needed) {
                                    return Text(
                                      locale == 'ar'
                                          ? 'الكمية غير كافية لهذه الجرعة'
                                          : 'Not enough ${getQuantityUnitLabel(unit, locale: locale)} for this dose',
                                      style: TextStyle(
                                        color: Colors.red[700],
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  } else if (threshold != null &&
                                      stock <= threshold) {
                                    return Text(
                                      locale == 'ar'
                                          ? 'الكمية منخفضة (${formatQuantityWithUnit(stock, unit, locale: locale)} متبقية)'
                                          : 'Low stock (${formatQuantityWithUnit(stock, unit, locale: locale)} left)',
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

                  // ── Badges (top right) ──
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Row(
                      children: [
                        // Interaction warning badge
                        if (schedule.hasInteractions)
                          InteractionWarningBadge(
                            interactionCount: schedule.interactions.length,
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => InteractionBottomSheet(
                                  medicationName: schedule.medName,
                                  interactions: schedule.interactions,
                                ),
                              );
                            },
                          ),
                        const SizedBox(width: 8),
                        // Countdown badge
                        Container(
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
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Interactions Note ──
            if (schedule.hasInteractions)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFFF9800).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: const Color(0xFFE65100),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tap the warning badge to view interactions',
                        style: TextStyle(
                          fontSize: 11,
                          color: const Color(0xFFE65100),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
    final currentQuantity = med?.currentQuantity ?? med?.currentPillCount;
    if (med != null && currentQuantity != null) {
      final needed = med.doseQuantity ?? med.pillsPerDose ?? 1;
      if (currentQuantity < needed) {
        final locale = context.read<LanguageProvider>().currentLanguage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              locale == 'ar'
                  ? 'الكمية غير كافية. يرجى تحديث المخزون في أدويتي أولاً.'
                  : 'Not enough ${getQuantityUnitLabel(med.quantityUnit, locale: locale)}. Please update stock in My Meds first.',
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
          SnackBar(
            content: Text(context.l10n.t('connectionErrorTryAgain')),
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
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.orange[700],
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.t('connectionErrorTryAgain')),
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
          SnackBar(
            content: Text(context.l10n.t('connectionErrorTryAgain')),
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
    final int? currentQuantity =
        (med?.currentQuantity ?? med?.currentPillCount) as int?;
    final int? initialQuantity =
        (med?.initialQuantity ?? med?.initialPillCount) as int?;
    final DateTime? packageExpiryDate = med?.expiryDate as DateTime?;
    final DateTime? expiryDate = med?.actualExpiryDate as DateTime?;
    final int? doseQuantity = (med?.doseQuantity ?? med?.pillsPerDose) as int?;
    final String? dosage = med?.dosage as String?;
    final String? dosageForm = med?.dosageForm as String?;
    final String? quantityUnit = med?.quantityUnit as String?;
    final locale = context.read<LanguageProvider>().currentLanguage;

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
            if (dosageForm != null && dosageForm.isNotEmpty)
              _infoRow(
                Icons.category_outlined,
                locale == 'ar' ? 'شكل الدواء' : 'Dosage form',
                getMedicationTypeLabel(dosageForm, locale: locale),
              ),
            if (currentQuantity != null)
              _infoRow(
                Icons.inventory_2_outlined,
                locale == 'ar' ? 'الكمية الحالية' : 'Current quantity',
                formatQuantityWithUnit(
                  currentQuantity,
                  quantityUnit,
                  locale: locale,
                ),
              ),
            if (initialQuantity != null)
              _infoRow(
                Icons.inventory_outlined,
                locale == 'ar' ? 'الكمية الكلية' : 'Initial quantity',
                formatQuantityWithUnit(
                  initialQuantity,
                  quantityUnit,
                  locale: locale,
                ),
              ),
            if (doseQuantity != null)
              _infoRow(
                Icons.colorize_rounded,
                locale == 'ar' ? 'كمية الجرعة' : 'Quantity per dose',
                formatQuantityWithUnit(
                  doseQuantity,
                  quantityUnit,
                  locale: locale,
                ),
              ),
            if (packageExpiryDate != null)
              _infoRow(
                Icons.event_outlined,
                context.l10n.t('packageExpiry'),
                _formatDate(packageExpiryDate),
              ),
            if (expiryDate != null)
              _infoRow(
                Icons.verified_outlined,
                context.l10n.t('actualExpiry'),
                _formatDate(expiryDate),
              ),
            if (med?.expiryReason == 'AFTER_OPENING_EXPIRY')
              _infoRow(
                Icons.info_outline_rounded,
                context.l10n.t('reasonLabel'),
                context.l10n.t(
                  'thisMedicationExpiresEarlierBecauseItWasOpened',
                ),
              )
            else if (med?.expiryReason == 'PACKAGE_EXPIRY')
              _infoRow(
                Icons.info_outline_rounded,
                context.l10n.t('reasonLabel'),
                context.l10n.t(
                  'thisMedicationExpiresBasedOnThePackageExpiryDate',
                ),
              ),
            const SizedBox(height: 24),

            // ── Stock Warning in Modal ──
            if (med != null && currentQuantity != null)
              Builder(
                builder: (context) {
                  final stock = currentQuantity;
                  final needed = doseQuantity ?? 1;
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
                                locale == 'ar'
                                    ? 'الكمية غير كافية لهذه الجرعة. يرجى تحديث المخزون في أدويتي.'
                                    : 'Not enough ${getQuantityUnitLabel(quantityUnit, locale: locale)} for this dose. Please update stock in My Meds.',
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

            // ── Drug Interactions Section ──
            if (widget.schedule.hasInteractions) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFFF9800).withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: const Color(0xFFE65100),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Drug Interactions Detected',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFE65100),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...widget.schedule.interactions.map((interaction) {
                      final withMed = interaction['withMedication'] ?? '';
                      final reason = interaction['reason'] ?? '';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.swap_horiz_rounded,
                              size: 14,
                              color: const Color(0xFFFF9800),
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
                    }),
                  ],
                ),
              ),
            ],

            // ── Info Box ──
            if (widget.schedule.hasInteractions)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: Colors.blue[700],
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Consult your healthcare provider before making any changes.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue[900],
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),

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
                        label: Text(
                          context.l10n.t('snooze'),
                          style: const TextStyle(
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
                        label: Text(
                          context.l10n.t('skip'),
                          style: const TextStyle(
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
                  final stock = med?.currentQuantity ?? med?.currentPillCount;
                  final needed = med?.doseQuantity ?? med?.pillsPerDose ?? 1;
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
