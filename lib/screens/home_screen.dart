import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';
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
import 'insights_screen.dart';
import 'notifications_screen.dart';
import '../widgets/interaction_warning_badge.dart';
import '../widgets/interaction_bottom_sheet.dart';
import '../widgets/medication_feature_sheets.dart';

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
  final DateTime? snoozedUntil;

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
    this.snoozedUntil,
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

    DateTime parseUtc(String str) {
      if (str.isEmpty) return DateTime.now();
      String normalized = str;
      if (!str.endsWith('Z')) {
        final tIndex = str.indexOf('T');
        final timePart = tIndex != -1 ? str.substring(tIndex) : str;
        if (!timePart.contains('+') && !timePart.contains('-')) {
          normalized = '${str}Z';
        }
      }
      return DateTime.tryParse(normalized) ?? DateTime.now();
    }

    DateTime? parseUtcNullable(String str) {
      if (str.isEmpty) return null;
      String normalized = str;
      if (!str.endsWith('Z')) {
        final tIndex = str.indexOf('T');
        final timePart = tIndex != -1 ? str.substring(tIndex) : str;
        if (!timePart.contains('+') && !timePart.contains('-')) {
          normalized = '${str}Z';
        }
      }
      return DateTime.tryParse(normalized);
    }

    return TodaySchedule(
      id: j['id'] as int? ?? 0,
      userMedId: j['userMedId'] as int? ?? 0,
      medId: j['medId'] as int? ?? 0,
      medName: (j['medName'] ?? '').toString(),
      scheduledAt: parseUtc(j['scheduledAt']?.toString() ?? ''),
      notificationTime: parseUtc(j['notificationTime']?.toString() ?? ''),
      status: (j['status'] ?? 'Pending').toString(),
      reminderSent: j['reminderSent'] as bool? ?? false,
      snoozeCount: j['snoozeCount'] as int? ?? 0,
      hasInteractions: j['hasInteractions'] as bool? ?? false,
      interactions: interactions,
      snoozedUntil: parseUtcNullable(j['snoozedUntil']?.toString() ?? ''),
    );
  }

  TimeOfDay get timeOfDay => TimeOfDay(
    hour: scheduledAt.toLocal().hour,
    minute: scheduledAt.toLocal().minute,
  );

  bool get isTaken => status.toLowerCase() == 'taken';
  bool get isMissed => status.toLowerCase() == 'missed';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isSnoozed => status.toLowerCase() == 'snoozed';
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
class HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  String? _errorMessage;
  List<TodaySchedule> _schedules = [];
  String? _filterStatus; // null = ALL
  String? _currentLanguage;
  Timer? _refreshTimer;

  /// Public method so the nav shell can trigger a refresh when the user
  /// switches back to the Today tab after editing a medicine.
  void refreshSchedules() {
    _fetchSchedulesForDate(_selectedDate);
  }

  late DateTime _startOfWeek;
  late List<DateTime> _weeklyDates;

  void _navigateWeek(int direction) {
    setState(() {
      _startOfWeek = _startOfWeek.add(Duration(days: direction * 7));
      _weeklyDates = List.generate(
        7,
        (index) => _startOfWeek.add(Duration(days: index)),
      );
      // Keep the same weekday index selected in the new week
      final weekdayIndex = _selectedDate.weekday - 1; // 0 to 6
      _selectedDate = _weeklyDates[weekdayIndex];
    });
    _fetchSchedulesForDate(_selectedDate);
  }

  String _formatDisplayDate(DateTime date, {bool includeYear = false}) {
    final locale = _currentLanguage == 'ar' ? 'ar' : 'en';
    final pattern = includeYear ? 'MMMM d, y' : 'MMMM d';
    return intl.DateFormat(pattern, locale).format(date);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final now = DateTime.now();
    _startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    _weeklyDates = List.generate(
      7,
      (index) => _startOfWeek.add(Duration(days: index)),
    );
    // Fetch schedules for today on first load
    _fetchSchedulesForDate(_selectedDate);
    // Load unread alerts count
    _loadUnreadAlerts();
    _startRefreshTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopRefreshTimer();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startRefreshTimer();
      _silentRefresh();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _stopRefreshTimer();
    }
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      _silentRefresh();
    });
  }

  void _stopRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<void> _silentRefresh() async {
    final token = context.read<UserProvider>().token;
    if (token == null || token.isEmpty) return;
    try {
      await Future.wait([
        context.read<AlertsProvider>().refreshUnreadCount(token),
        context.read<NotificationsProvider>().refreshNotifications(token),
      ]);
    } catch (_) {
      // ignore background refresh errors
    }
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

  String _formatTimeNoContext(DateTime dt) {
    final local = dt.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final lang = context.read<LanguageProvider>().currentLanguage;
    final period = local.hour < 12
        ? (lang == 'ar' ? 'ص' : 'AM')
        : (lang == 'ar' ? 'م' : 'PM');
    return '$hour:$minute $period';
  }

  void _rollbackSchedule(
    int scheduleId,
    String previousStatus,
    DateTime? previousSnoozedUntil,
    bool previousIsTaken,
  ) {
    final index = _schedules.indexWhere((s) => s.id == scheduleId);
    if (index != -1) {
      final s = _schedules[index];
      setState(() {
        _schedules[index] = TodaySchedule(
          id: s.id,
          userMedId: s.userMedId,
          medId: s.medId,
          medName: s.medName,
          scheduledAt: s.scheduledAt,
          notificationTime: s.notificationTime,
          status: previousStatus,
          reminderSent: s.reminderSent,
          snoozeCount: s.snoozeCount,
          snoozedUntil: previousSnoozedUntil,
          hasInteractions: s.hasInteractions,
          interactions: s.interactions,
        );
      });
    }
  }

  Future<void> _fetchSchedulesForDateSilently(DateTime date) async {
    try {
      final token = context.read<UserProvider>().token;
      if (token == null || token.isEmpty) return;

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

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final fetched = data
            .map((json) => TodaySchedule.fromJson(json))
            .toList();
        if (mounted) {
          setState(() {
            _schedules = fetched;
          });
        }
      }
    } catch (_) {
      // Ignore background errors
    }
  }

  Future<void> _markAsTaken(int scheduleId) async {
    final token = context.read<UserProvider>().token;
    if (token == null) return;
    final medicineProvider = context.read<MedicineProvider>();
    final alertsProvider = context.read<AlertsProvider>();
    final notificationsProvider = context.read<NotificationsProvider>();
    final locale = context.read<LanguageProvider>().currentLanguage;

    final scheduleIndex = _schedules.indexWhere((s) => s.id == scheduleId);
    if (scheduleIndex == -1) return;
    final schedule = _schedules[scheduleIndex];

    final matchedMedicine = medicineProvider.medicines
        .where((m) => m.id == schedule.userMedId.toString())
        .firstOrNull;

    final previousStatus = schedule.status;
    final previousSnoozedUntil = schedule.snoozedUntil;
    final previousIsTaken = schedule.isTaken;

    // 1. OPTIMISTIC UI UPDATE
    setState(() {
      _schedules[scheduleIndex] = TodaySchedule(
        id: schedule.id,
        userMedId: schedule.userMedId,
        medId: schedule.medId,
        medName: schedule.medName,
        scheduledAt: schedule.scheduledAt,
        notificationTime: schedule.notificationTime,
        status: 'taken',
        reminderSent: schedule.reminderSent,
        snoozeCount: schedule.snoozeCount,
        snoozedUntil: null,
        hasInteractions: schedule.hasInteractions,
        interactions: schedule.interactions,
      );
    });

    // Update stock locally optimistically
    int? optimisticRemaining;
    String? unit;
    if (matchedMedicine != null) {
      final currentStock =
          matchedMedicine.currentQuantity ?? matchedMedicine.currentPillCount;
      final needed =
          matchedMedicine.doseQuantity ?? matchedMedicine.pillsPerDose ?? 1;
      if (currentStock != null) {
        optimisticRemaining = (currentStock - needed).clamp(0, 999999);
        unit = matchedMedicine.quantityUnit;
      }
    }

    // Capture localized strings BEFORE any await to prevent "use_build_context_synchronously" warnings.
    final doseTakenMsgPrefix = context.l10n.t('doseTaken');
    final doseMarkedTakenMsg = context.l10n.t('doseMarkedTaken');
    final failedMarkDoseTakenMsg = context.l10n.t('failedMarkDoseTaken');
    final connectionErrorMsg = context.l10n.t('connectionErrorTryAgain');

    if (matchedMedicine != null && optimisticRemaining != null) {
      await medicineProvider.updateStockLocally(
        matchedMedicine.id,
        optimisticRemaining,
      );
    }

    // 2. SHOW INSTANT TOP OVERLAY FEEDBACK
    final takeMsg = optimisticRemaining != null
        ? '$doseTakenMsgPrefix ${remainingQuantityLabel(optimisticRemaining, unit, locale: locale)}'
        : doseMarkedTakenMsg;

    if (mounted) {
      TopOverlayNotification.show(
        context,
        message: takeMsg,
        type: NotificationType.success,
      );
    }

    // 3. EXECUTE API SILENTLY IN BACKGROUND
    () async {
      try {
        final result = await SchedulesService.takeDose(token, scheduleId);
        if (result.succeeded) {
          final remaining = result.remainingQuantity ?? result.remainingPills;
          if (remaining != null && matchedMedicine != null) {
            await medicineProvider.updateStockLocally(
              matchedMedicine.id,
              remaining,
            );
          }
          if (mounted) {
            await _fetchSchedulesForDateSilently(_selectedDate);
            await medicineProvider.fetchMedicinesFromApi(token);
            await alertsProvider.refreshUnreadCount(token);
            await notificationsProvider.refreshNotifications(token);
          }
        } else {
          // Rollback on failure
          if (mounted) {
            _rollbackSchedule(
              scheduleId,
              previousStatus,
              previousSnoozedUntil,
              previousIsTaken,
            );
            if (matchedMedicine != null) {
              final currentStock =
                  matchedMedicine.currentQuantity ??
                  matchedMedicine.currentPillCount;
              if (currentStock != null) {
                await medicineProvider.updateStockLocally(
                  matchedMedicine.id,
                  currentStock,
                );
              }
            }
            if (mounted) {
              TopOverlayNotification.show(
                context,
                message: result.error ?? failedMarkDoseTakenMsg,
                type: NotificationType.error,
              );
            }
          }
        }
      } catch (e) {
        // Rollback on error
        if (mounted) {
          _rollbackSchedule(
            scheduleId,
            previousStatus,
            previousSnoozedUntil,
            previousIsTaken,
          );
          if (matchedMedicine != null) {
            final currentStock =
                matchedMedicine.currentQuantity ??
                matchedMedicine.currentPillCount;
            if (currentStock != null) {
              await medicineProvider.updateStockLocally(
                matchedMedicine.id,
                currentStock,
              );
            }
          }
          if (mounted) {
            TopOverlayNotification.show(
              context,
              message: e is ApiException ? e.message : connectionErrorMsg,
              type: NotificationType.error,
            );
          }
        }
      }
    }();
  }

  Future<void> _snoozeSchedule(int scheduleId, int minutes) async {
    final token = context.read<UserProvider>().token;
    if (token == null) return;
    final alertsProvider = context.read<AlertsProvider>();
    final notificationsProvider = context.read<NotificationsProvider>();

    final scheduleIndex = _schedules.indexWhere((s) => s.id == scheduleId);
    if (scheduleIndex == -1) return;
    final schedule = _schedules[scheduleIndex];

    final previousStatus = schedule.status;
    final previousSnoozedUntil = schedule.snoozedUntil;
    final previousIsTaken = schedule.isTaken;

    final now = DateTime.now();
    final optimisticSnoozedUntil = now.add(Duration(minutes: minutes));

    // 1. OPTIMISTIC UI UPDATE
    setState(() {
      _schedules[scheduleIndex] = TodaySchedule(
        id: schedule.id,
        userMedId: schedule.userMedId,
        medId: schedule.medId,
        medName: schedule.medName,
        scheduledAt: schedule.scheduledAt,
        notificationTime: schedule.notificationTime,
        status: 'snoozed',
        reminderSent: schedule.reminderSent,
        snoozeCount: schedule.snoozeCount + 1,
        snoozedUntil: optimisticSnoozedUntil,
        hasInteractions: schedule.hasInteractions,
        interactions: schedule.interactions,
      );
    });

    // 2. SHOW INSTANT TOP OVERLAY FEEDBACK
    final formattedTime = _formatTimeNoContext(optimisticSnoozedUntil);
    final snoozeMsg = context.read<LanguageProvider>().currentLanguage == 'ar'
        ? 'تم التأجيل حتى $formattedTime'
        : 'Snoozed until $formattedTime';

    TopOverlayNotification.show(
      context,
      message: snoozeMsg,
      type: NotificationType.success,
    );

    // 3. EXECUTE API SILENTLY IN BACKGROUND
    () async {
      try {
        final result = await SchedulesService.snoozeDose(
          token,
          scheduleId,
          minutes,
        );
        if (result.succeeded) {
          if (mounted) {
            await _fetchSchedulesForDateSilently(_selectedDate);
            await alertsProvider.refreshUnreadCount(token);
            await notificationsProvider.refreshNotifications(token);
          }
        } else {
          // Rollback on failure
          if (mounted) {
            _rollbackSchedule(
              scheduleId,
              previousStatus,
              previousSnoozedUntil,
              previousIsTaken,
            );
            final msg = result.error ?? 'Snooze failed';
            final isWarning =
                msg.toLowerCase().contains('snooze') ||
                msg.toLowerCase().contains('limit') ||
                msg.toLowerCase().contains('already');
            TopOverlayNotification.show(
              context,
              message: msg,
              type: isWarning
                  ? NotificationType.warning
                  : NotificationType.error,
            );
          }
        }
      } catch (e) {
        // Rollback on error
        if (mounted) {
          _rollbackSchedule(
            scheduleId,
            previousStatus,
            previousSnoozedUntil,
            previousIsTaken,
          );
          TopOverlayNotification.show(
            context,
            message: e is ApiException
                ? e.message
                : context.l10n.t('connectionErrorTryAgain'),
            type: NotificationType.error,
          );
        }
      }
    }();
  }

  Future<void> _skipSchedule(
    int scheduleId, {
    String? reason,
    String? note,
  }) async {
    final token = context.read<UserProvider>().token;
    if (token == null) return;
    final alertsProvider = context.read<AlertsProvider>();
    final notificationsProvider = context.read<NotificationsProvider>();

    final scheduleIndex = _schedules.indexWhere((s) => s.id == scheduleId);
    if (scheduleIndex == -1) return;
    final schedule = _schedules[scheduleIndex];

    final previousStatus = schedule.status;
    final previousSnoozedUntil = schedule.snoozedUntil;
    final previousIsTaken = schedule.isTaken;

    // 1. OPTIMISTIC UI UPDATE
    setState(() {
      _schedules[scheduleIndex] = TodaySchedule(
        id: schedule.id,
        userMedId: schedule.userMedId,
        medId: schedule.medId,
        medName: schedule.medName,
        scheduledAt: schedule.scheduledAt,
        notificationTime: schedule.notificationTime,
        status: 'skipped',
        reminderSent: schedule.reminderSent,
        snoozeCount: schedule.snoozeCount,
        snoozedUntil: null,
        hasInteractions: schedule.hasInteractions,
        interactions: schedule.interactions,
      );
    });

    // 2. SHOW INSTANT TOP OVERLAY FEEDBACK
    final skipText = context.l10n.t('doseSkipped');
    TopOverlayNotification.show(
      context,
      message: skipText,
      type: NotificationType.success,
    );

    // 3. EXECUTE API SILENTLY IN BACKGROUND
    () async {
      try {
        await SchedulesService.skipDose(
          token,
          scheduleId,
          reason: reason,
          note: note,
        );
        if (mounted) {
          await _fetchSchedulesForDateSilently(_selectedDate);
          await alertsProvider.refreshUnreadCount(token);
          await notificationsProvider.refreshNotifications(token);
        }
      } catch (e) {
        // Rollback on error
        if (mounted) {
          _rollbackSchedule(
            scheduleId,
            previousStatus,
            previousSnoozedUntil,
            previousIsTaken,
          );
          TopOverlayNotification.show(
            context,
            message: e is ApiException
                ? e.message
                : context.l10n.t('connectionErrorTryAgain'),
            type: NotificationType.error,
          );
        }
      }
    }();
  }

  List<TodaySchedule> get _filtered {
    if (_filterStatus == null) return _schedules;
    if (_filterStatus!.toLowerCase() == 'missed') {
      return _schedules
          .where(
            (s) =>
                s.status.toLowerCase() == 'missed' ||
                s.status.toLowerCase() == 'skipped',
          )
          .toList();
    }
    return _schedules
        .where((s) => s.status.toLowerCase() == _filterStatus!.toLowerCase())
        .toList();
  }

  int _countByStatus(String status) {
    if (status.toLowerCase() == 'missed') {
      return _schedules
          .where(
            (s) =>
                s.status.toLowerCase() == 'missed' ||
                s.status.toLowerCase() == 'skipped',
          )
          .length;
    }
    return _schedules
        .where((s) => s.status.toLowerCase() == status.toLowerCase())
        .length;
  }

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
                                  userProvider.name.trim().isEmpty
                                      ? context.l10n.t('hello')
                                      : context.l10n.t('helloName', {
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
                          IconButton(
                            tooltip: 'Insights',
                            icon: const Icon(
                              Icons.insights_outlined,
                              color: AppColors.primaryTeal,
                              size: 28,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const InsightsScreen(),
                                ),
                              );
                            },
                            constraints: const BoxConstraints(
                              minWidth: 48,
                              minHeight: 48,
                            ),
                          ),
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

                  // ── Weekly Calendar label & Back to Today ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _isSelectedDateToday
                            ? context.l10n.t('todayDate', {
                                'date': _formatDisplayDate(_selectedDate),
                              })
                            : _formatDisplayDate(
                                _selectedDate,
                                includeYear: true,
                              ),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      if (!_isSelectedDateToday)
                        TextButton.icon(
                          onPressed: _resetToToday,
                          icon: Icon(
                            Icons.today_rounded,
                            size: 16,
                            color: AppColors.primaryTeal,
                          ),
                          label: Text(
                            context.l10n.t('today'),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primaryTeal,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: AppColors.primaryTeal.withValues(
                              alpha: 0.1,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(
                          Icons.chevron_left,
                          color: AppColors.textGrey,
                          size: 24,
                        ),
                        onPressed: () {
                          _navigateWeek(-1);
                        },
                      ),
                      ..._weeklyDates.map((date) => _buildDayItem(date)),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(
                          Icons.chevron_right,
                          color: AppColors.textGrey,
                          size: 24,
                        ),
                        onPressed: () {
                          _navigateWeek(1);
                        },
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
                  Row(
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
                              onSnoozeSuccess: (minutes) =>
                                  _snoozeSchedule(s.id, minutes),
                              onSkipSuccess: (reason, note) => _skipSchedule(
                                s.id,
                                reason: reason,
                                note: note,
                              ),
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
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filterStatus = status),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryTeal : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primaryTeal : Colors.grey[200]!,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : AppColors.primaryTeal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "$count",
                  style: TextStyle(
                    fontSize: 9,
                    color: isSelected ? Colors.white : AppColors.primaryTeal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
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

  void _resetToToday() {
    final now = DateTime.now();
    setState(() {
      _selectedDate = now;
      _startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      _weeklyDates = List.generate(
        7,
        (index) => _startOfWeek.add(Duration(days: index)),
      );
    });
    _fetchSchedulesForDate(now);
  }

  Widget _buildDayItem(DateTime date) {
    final isSelected =
        date.day == _selectedDate.day &&
        date.month == _selectedDate.month &&
        date.year == _selectedDate.year;
    final isToday = _isToday(date);

    final weekdaysEn = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final weekdaysAr = ['ن', 'ث', 'ر', 'خ', 'ج', 'س', 'ح'];
    final weekdayLabel = _currentLanguage == 'ar'
        ? weekdaysAr[date.weekday - 1]
        : weekdaysEn[date.weekday - 1];

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() => _selectedDate = date);
              _fetchSchedulesForDate(date);
            },
            borderRadius: BorderRadius.circular(12),
            splashColor: AppColors.primaryTeal.withValues(alpha: 0.15),
            highlightColor: AppColors.primaryTeal.withValues(alpha: 0.08),
            child: Ink(
              height: 60,
              decoration: isSelected
                  ? BoxDecoration(
                      color: AppColors.primaryTeal,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryTeal.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    )
                  : isToday
                  ? BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(
                        color: AppColors.primaryTeal.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    )
                  : BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    weekdayLabel,
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected
                          ? Colors.white
                          : isToday
                          ? AppColors.primaryTeal
                          : AppColors.textGrey,
                      fontWeight: isSelected || isToday
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${date.day}",
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected
                          ? Colors.white
                          : isToday
                          ? AppColors.primaryTeal
                          : AppColors.textDark,
                      fontWeight: isSelected || isToday
                          ? FontWeight.bold
                          : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
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

  String _formatTime(BuildContext context, DateTime dt) {
    final local = dt.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final lang = Provider.of<LanguageProvider>(
      context,
      listen: false,
    ).currentLanguage;
    final period = local.hour < 12
        ? (lang == 'ar' ? 'ص' : 'AM')
        : (lang == 'ar' ? 'م' : 'PM');
    return '$hour:$minute $period';
  }

  String _getCountdown(bool isAr) {
    final now = DateTime.now();
    final scheduled = schedule.scheduledAt.toLocal();

    if (scheduled.isBefore(now)) {
      final diff = now.difference(scheduled);
      if (diff.inHours > 0) {
        return isAr ? 'منذ ${diff.inHours} ساعة' : '${diff.inHours}h ago';
      }
      return isAr ? 'منذ ${diff.inMinutes} دقيقة' : '${diff.inMinutes}m ago';
    }

    final diff = scheduled.difference(now);
    if (diff.inHours >= 24) {
      return isAr
          ? '${diff.inDays} يوم و ${diff.inHours.remainder(24)} ساعة'
          : '${diff.inDays}d ${diff.inHours.remainder(24)}h';
    }
    if (diff.inHours > 0) {
      return isAr
          ? '${diff.inHours} ساعة و ${diff.inMinutes.remainder(60)} دقيقة'
          : '${diff.inHours}h ${diff.inMinutes.remainder(60)}m';
    }
    return isAr ? '${diff.inMinutes} دقيقة' : '${diff.inMinutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final isAr =
        Provider.of<LanguageProvider>(context, listen: false).currentLanguage ==
        'ar';
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                            Text(
                              schedule.medName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
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
                                  _formatTime(context, schedule.scheduledAt),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textGrey,
                                  ),
                                ),
                              ],
                            ),
                            if (schedule.isSnoozed &&
                                schedule.snoozedUntil != null &&
                                schedule.snoozedUntil!.isAfter(
                                  DateTime.now(),
                                )) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.snooze,
                                    size: 13,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    context
                                                .read<LanguageProvider>()
                                                .currentLanguage ==
                                            'ar'
                                        ? 'تم التأجيل حتى ${_formatTime(context, schedule.snoozedUntil!)}'
                                        : 'Snoozed until ${_formatTime(context, schedule.snoozedUntil!)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 4),

                            // Snooze info
                            if (schedule.isPending &&
                                schedule.snoozeCount > 0 &&
                                !(schedule.isSnoozed &&
                                    schedule.snoozedUntil != null &&
                                    schedule.snoozedUntil!.isAfter(
                                      DateTime.now(),
                                    )))
                              Row(
                                children: [
                                  const Icon(
                                    Icons.snooze,
                                    size: 13,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isAr
                                        ? 'غفوة ${schedule.snoozeCount}x'
                                        : 'Snoozed ${schedule.snoozeCount}x',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            // Compact status chip — visible for Taken/Missed;
                            // pending/snoozed items show nothing (card tap opens modal)
                            if (!schedule.isPending && !schedule.isSnoozed)
                              Row(
                                children: [
                                  Icon(
                                    _statusIcon,
                                    color: _statusColor,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isAr
                                        ? (schedule.status.toLowerCase() ==
                                                  'taken'
                                              ? 'تم التناول'
                                              : (schedule.status
                                                            .toLowerCase() ==
                                                        'missed'
                                                    ? 'فائت'
                                                    : (schedule.status
                                                                  .toLowerCase() ==
                                                              'skipped'
                                                          ? 'تم التخطي'
                                                          : schedule.status)))
                                        : schedule.status.toUpperCase(),
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
                  const SizedBox(height: 12),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
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
                                _getCountdown(isAr),
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
                        isAr
                            ? 'اضغط على شارة التحذير لعرض التداخلات'
                            : 'Tap the warning badge to view interactions',
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
  final Future<void> Function(int minutes) onSnoozeSuccess;

  /// Called when user taps Skip. Parent handles API + refresh.
  final Future<void> Function(String? reason, String? note) onSkipSuccess;

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
  bool _interactionsExpanded = false;

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  // ── Action handlers ───────────────────────────────────────────────────────

  void _onTakeTapped() {
    Navigator.pop(context);
    widget.onTakeSuccess();
  }

  void _onSnoozeTapped() async {
    final selectedMinutes = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const _SnoozeDurationSelectorBottomSheet(),
    );

    if (selectedMinutes == null) return; // user cancelled

    int finalMinutes = selectedMinutes;
    if (selectedMinutes == -1) {
      if (!mounted) return;
      final now = DateTime.now();
      final selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(now),
      );
      if (selectedTime == null) return; // user cancelled

      final nowZeroSec = DateTime(
        now.year,
        now.month,
        now.day,
        now.hour,
        now.minute,
      );
      DateTime selectedDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        selectedTime.hour,
        selectedTime.minute,
      );
      if (selectedDateTime.isBefore(nowZeroSec)) {
        selectedDateTime = selectedDateTime.add(const Duration(days: 1));
      }
      final diffMinutes = selectedDateTime.difference(nowZeroSec).inMinutes;
      if (diffMinutes <= 0) {
        if (mounted) {
          TopOverlayNotification.show(
            context,
            message: context.l10n.t('invalidTimeSelected'),
            type: NotificationType.error,
          );
        }
        return;
      }
      finalMinutes = diffMinutes;
    }

    if (mounted) Navigator.pop(context);
    widget.onSnoozeSuccess(finalMinutes);
  }

  Future<void> _onSkipTapped() async {
    final result = await showSkipReasonBottomSheet(context);
    if (result == null) return;
    if (mounted) Navigator.pop(context);
    await widget.onSkipSuccess(result.reason, result.note);
  }

  // ── Compact Info Card Widget ──────────────────────────────────────────────

  Widget _compactInfoCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryTeal.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryTeal.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryTeal, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
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
    final int? doseQuantity = (med?.doseQuantity ?? med?.pillsPerDose) as int?;
    final String? dosage = med?.dosage as String?;
    final String? quantityUnit = med?.quantityUnit as String?;
    final locale = context.read<LanguageProvider>().currentLanguage;

    final bool alreadyHandled =
        s.isTaken || s.isMissed || s.status.toLowerCase() == 'skipped';

    final viewAllText = locale == 'ar'
        ? 'عرض جميع التفاعلات'
        : 'View All Interactions';
    final showLessText = locale == 'ar' ? 'عرض أقل' : 'Show Less';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
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
                locale == 'ar' ? 'تناول الجرعة' : 'Take Dose',
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
                  child: Icon(Icons.close, size: 18, color: AppColors.textGrey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Scrollable Content ──
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                            color: AppColors.primaryTeal.withValues(
                              alpha: 0.12,
                            ),
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
                        // Status chip for already-handled or snoozed schedules
                        if (alreadyHandled || s.isSnoozed)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: s.isTaken
                                  ? Colors.green.withValues(alpha: 0.12)
                                  : (s.isSnoozed
                                        ? Colors.orange.withValues(alpha: 0.12)
                                        : Colors.red.withValues(alpha: 0.12)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              locale == 'ar'
                                  ? (s.isSnoozed
                                        ? 'مؤجل'
                                        : (s.status.toLowerCase() == 'skipped'
                                              ? 'تم التخطي'
                                              : (s.isMissed
                                                    ? 'فائت'
                                                    : 'تم التناول')))
                                  : (s.isSnoozed
                                        ? 'SNOOZED'
                                        : (s.isMissed ||
                                                  s.status.toLowerCase() ==
                                                      'skipped'
                                              ? 'MISSED'
                                              : s.status.toUpperCase())),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: s.isTaken
                                    ? Colors.green[700]
                                    : (s.isSnoozed
                                          ? Colors.orange[700]
                                          : Colors.red[700]),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Compact Info Cards Row ──
                  Row(
                    children: [
                      Expanded(
                        child: _compactInfoCard(
                          Icons.schedule_rounded,
                          locale == 'ar' ? 'وقت الجرعة' : 'Scheduled Time',
                          _formatTime(s.scheduledAt),
                        ),
                      ),
                      if (currentQuantity != null) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: _compactInfoCard(
                            Icons.inventory_2_outlined,
                            locale == 'ar'
                                ? 'الكمية المتبقية'
                                : 'Remaining Qty',
                            formatQuantityWithUnit(
                              currentQuantity,
                              quantityUnit,
                              locale: locale,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Stock Warning in Modal ──
                  if (med != null && currentQuantity != null)
                    Builder(
                      builder: (context) {
                        final stock = currentQuantity;
                        final needed = doseQuantity ?? 1;
                        final threshold = med.lowStockThreshold;
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
                        } else if (threshold != null && stock <= threshold) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.orange.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.warning_rounded,
                                    color: Colors.orange[700],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      locale == 'ar'
                                          ? 'الكمية منخفضة (${formatQuantityWithUnit(stock, quantityUnit, locale: locale)} متبقية)'
                                          : 'Low stock (${formatQuantityWithUnit(stock, quantityUnit, locale: locale)} left)',
                                      style: TextStyle(
                                        color: Colors.orange[900],
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
                                locale == 'ar'
                                    ? 'تم الكشف عن تفاعلات دوائية'
                                    : 'Drug Interactions Detected',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFE65100),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...(() {
                            final list = widget.schedule.interactions;
                            final displayed = _interactionsExpanded
                                ? list
                                : list.take(2).toList();
                            return displayed.map((interaction) {
                              final withMed =
                                  interaction['withMedication'] ?? '';
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                            });
                          })(),
                          if (widget.schedule.interactions.length > 2) ...[
                            const SizedBox(height: 4),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _interactionsExpanded =
                                      !_interactionsExpanded;
                                });
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _interactionsExpanded
                                        ? showLessText
                                        : viewAllText,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFE65100),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    _interactionsExpanded
                                        ? Icons.keyboard_arrow_up_rounded
                                        : Icons.keyboard_arrow_down_rounded,
                                    size: 16,
                                    color: const Color(0xFFE65100),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
                                locale == 'ar'
                                    ? 'استشر مقدم الرعاية الصحية الخاص بك قبل إجراء أي تغييرات.'
                                    : 'Consult your healthcare provider before making any changes.',
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
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Fixed Bottom Action Bar ──
          if (!alreadyHandled) ...[
            Row(
              children: [
                // Snooze button
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _onSnoozeTapped,
                      icon: const Icon(
                        Icons.snooze_rounded,
                        size: 18,
                        color: Colors.orange,
                      ),
                      label: Text(
                        widget.schedule.isSnoozed
                            ? (locale == 'ar'
                                  ? 'تأجيل مرة أخرى'
                                  : 'Snooze Again')
                            : context.l10n.t('snooze'),
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
                      onPressed: _onSkipTapped,
                      icon: const Icon(
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
                  onPressed: alreadyHandled || !canTake ? null : _onTakeTapped,
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
                  child: Text(
                    alreadyHandled
                        ? (locale == 'ar'
                              ? (s.status.toLowerCase() == 'skipped'
                                    ? 'تم التخطي'
                                    : (s.isMissed ? 'فائت' : 'تم التناول'))
                              : ((s.isMissed ||
                                        s.status.toLowerCase() == 'skipped')
                                    ? 'MISSED'
                                    : s.status.toUpperCase()))
                        : !canTake
                        ? (locale == 'ar'
                              ? 'حدث المخزون أولاً'
                              : 'Update stock first')
                        : (locale == 'ar' ? 'تناول الجرعة' : 'Take Dose'),
                    style: TextStyle(
                      color: alreadyHandled ? AppColors.textGrey : Colors.white,
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
    );
  }
}

class _SnoozeDurationSelectorBottomSheet extends StatelessWidget {
  const _SnoozeDurationSelectorBottomSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.t('snoozeDuration'),
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildOption(
              context,
              label: context.l10n.t('snoozeForMinutes', {'minutes': '15'}),
              minutes: 15,
            ),
            const SizedBox(height: 8),
            _buildOption(
              context,
              label: context.l10n.t('snoozeForMinutes', {'minutes': '30'}),
              minutes: 30,
            ),
            const SizedBox(height: 8),
            _buildOption(
              context,
              label: context.l10n.t('snoozeForMinutes', {'minutes': '45'}),
              minutes: 45,
            ),
            const SizedBox(height: 8),
            _buildCustomTimeOption(context),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required String label,
    required int minutes,
  }) {
    return InkWell(
      onTap: () => Navigator.pop(context, minutes),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            const Icon(Icons.snooze_rounded, color: Colors.orange, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTimeOption(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.pop(context, -1);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.access_time_filled_rounded,
              color: AppColors.primaryTeal,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              context.l10n.t('chooseAnotherTime'),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum NotificationType { success, warning, error }

class TopOverlayNotification {
  static OverlayEntry? _currentEntry;

  static void show(
    BuildContext context, {
    required String message,
    required NotificationType type,
  }) {
    // Dismiss any active notification first
    _currentEntry?.remove();
    _currentEntry = null;

    final overlayState = Navigator.of(context, rootNavigator: true).overlay;
    if (overlayState == null) return;

    _currentEntry = OverlayEntry(
      builder: (context) => _TopNotificationWidget(
        message: message,
        type: type,
        onDismiss: () {
          _currentEntry?.remove();
          _currentEntry = null;
        },
      ),
    );

    overlayState.insert(_currentEntry!);
  }
}

class _TopNotificationWidget extends StatefulWidget {
  final String message;
  final NotificationType type;
  final VoidCallback onDismiss;

  const _TopNotificationWidget({
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  @override
  State<_TopNotificationWidget> createState() => _TopNotificationWidgetState();
}

class _TopNotificationWidgetState extends State<_TopNotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    // Auto dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onDismiss());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    IconData icon;

    switch (widget.type) {
      case NotificationType.success:
        backgroundColor = const Color(0xFF2E7D32); // Green
        icon = Icons.check_circle_outline;
        break;
      case NotificationType.warning:
        backgroundColor = const Color(0xFFE65100); // Warning Orange
        icon = Icons.warning_amber_rounded;
        break;
      case NotificationType.error:
        backgroundColor = const Color(0xFFD32F2F); // Red
        icon = Icons.error_outline;
        break;
    }

    String displayMessage = widget.message;
    if (widget.type == NotificationType.success &&
        !displayMessage.startsWith('✓')) {
      displayMessage = '✓ $displayMessage';
    } else if ((widget.type == NotificationType.warning ||
            widget.type == NotificationType.error) &&
        !displayMessage.startsWith('⚠')) {
      displayMessage = '⚠ $displayMessage';
    }

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: SlideTransition(
            position: _offsetAnimation,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        displayMessage,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
