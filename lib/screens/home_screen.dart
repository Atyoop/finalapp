import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../main.dart';
import '../providers/user_provider.dart';
import 'chatbot_screen.dart';

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
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  String? _errorMessage;
  List<TodaySchedule> _schedules = [];
  String? _filterStatus; // null = ALL

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
    _fetchTodaySchedules();
  }

  Future<void> _fetchTodaySchedules() async {
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

      final res = await http
          .get(
            Uri.parse(
              'https://drugsafe.runasp.net/api/users/me/today-schedules',
            ),
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

  Future<void> _markAsTaken(TodaySchedule schedule) async {
    try {
      final token = context.read<UserProvider>().token;
      if (token == null) return;

      final res = await http
          .post(
            Uri.parse(
              'https://drugsafe.runasp.net/api/schedules/${schedule.id}/take',
            ),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        await _fetchTodaySchedules();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update status')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Network error. Please try again.')),
        );
      }
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
                  Consumer<UserProvider>(
                    builder: (context, userProvider, _) {
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
                          Column(
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
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // ── Weekly Calendar ──
                  Text(
                    "Today, $_monthName ${_selectedDate.day}",
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
                        "Today's Medication",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      if (!_isLoading)
                        GestureDetector(
                          onTap: _fetchTodaySchedules,
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
                    ..._filtered.map(
                      (s) => _ScheduleCard(
                        schedule: s,
                        onTake: () => _markAsTaken(s),
                      ),
                    ),

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
            onPressed: _fetchTodaySchedules,
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
      onTap: () => setState(() => _selectedDate = date),
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
  final VoidCallback onTake;

  const _ScheduleCard({required this.schedule, required this.onTake});

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
                          const SizedBox(height: 10),

                          // Status Badge or Take Button
                          if (schedule.isPending)
                            SizedBox(
                              width: double.infinity,
                              height: 38,
                              child: ElevatedButton(
                                onPressed: onTake,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryTeal,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Take Now',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            )
                          else
                            Row(
                              children: [
                                Icon(
                                  _statusIcon,
                                  color: _statusColor,
                                  size: 16,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  schedule.status.toUpperCase(),
                                  style: TextStyle(
                                    color: _statusColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
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
                          color: const Color(0xFFFF9800).withValues(alpha: 0.2),
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
      ),
    );
  }
}
