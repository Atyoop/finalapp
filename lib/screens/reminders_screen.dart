import 'package:flutter/material.dart';
import '../main.dart';
import 'add_reminder_screen.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});
  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  DateTime _selectedDate = DateTime.now();
  int _selectedDay = DateTime.now().day;

  // Sample reminders
  final List<Map<String, dynamic>> _reminders = [
    {
      'drug': 'Amoxicillin',
      'dosage': '500mg',
      'time': '08:00 AM',
      'taken': true,
      'color': const Color(0xFF4CAF50),
    },
    {
      'drug': 'Ibuprofen',
      'dosage': '200mg',
      'time': '01:00 PM',
      'taken': false,
      'color': const Color(0xFFFF9800),
    },
    {
      'drug': 'Metformin',
      'dosage': '850mg',
      'time': '06:00 PM',
      'taken': false,
      'color': const Color(0xFF2196F3),
    },
    {
      'drug': 'Omeprazole',
      'dosage': '20mg',
      'time': '09:00 PM',
      'taken': false,
      'color': const Color(0xFF9C27B0),
    },
  ];

  List<String> get _monthNames => [
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
  ];

  int get _daysInMonth =>
      DateUtils.getDaysInMonth(_selectedDate.year, _selectedDate.month);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textDark),
        title: Text(
          'Reminders',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddReminderScreen()),
        ),
        backgroundColor: AppColors.primaryTeal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Calendar Header
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Month selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.chevron_left,
                        color: AppColors.textDark,
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedDate = DateTime(
                            _selectedDate.month == 1
                                ? _selectedDate.year - 1
                                : _selectedDate.year,
                            _selectedDate.month == 1
                                ? 12
                                : _selectedDate.month - 1,
                          );
                          _selectedDay = 1;
                        });
                      },
                    ),
                    Text(
                      '${_monthNames[_selectedDate.month - 1]} ${_selectedDate.year}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.chevron_right,
                        color: AppColors.textDark,
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedDate = DateTime(
                            _selectedDate.month == 12
                                ? _selectedDate.year + 1
                                : _selectedDate.year,
                            _selectedDate.month == 12
                                ? 1
                                : _selectedDate.month + 1,
                          );
                          _selectedDay = 1;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Weekday labels
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
                      .map(
                        (d) => SizedBox(
                          width: 36,
                          child: Center(
                            child: Text(
                              d,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textGrey,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 8),

                // Day grid
                _buildCalendarGrid(),
              ],
            ),
          ),

          // Reminders header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Today\'s Reminders',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  '${_reminders.where((r) => r['taken'] == true).length}/${_reminders.length} taken',
                  style: TextStyle(fontSize: 13, color: AppColors.textGrey),
                ),
              ],
            ),
          ),

          // Reminders list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _reminders.length,
              itemBuilder: (context, index) {
                final r = _reminders[index];
                final taken = r['taken'] as bool;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: (r['color'] as Color).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.medication,
                          color: r['color'],
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r['drug'],
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                                decoration: taken
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${r['dosage']} • ${r['time']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _reminders[index]['taken'] =
                                !(_reminders[index]['taken'] as bool);
                          });
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: taken
                                ? AppColors.primaryTeal
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: taken
                                  ? AppColors.primaryTeal
                                  : AppColors.textGrey.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: taken
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 20,
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstWeekday =
        DateTime(_selectedDate.year, _selectedDate.month, 1).weekday % 7;
    final totalCells = firstWeekday + _daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rows, (row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(7, (col) {
            final cellIndex = row * 7 + col;
            final day = cellIndex - firstWeekday + 1;

            if (day < 1 || day > _daysInMonth) {
              return const SizedBox(width: 36, height: 36);
            }

            final isSelected = day == _selectedDay;
            final isToday =
                day == DateTime.now().day &&
                _selectedDate.month == DateTime.now().month &&
                _selectedDate.year == DateTime.now().year;

            return GestureDetector(
              onTap: () => setState(() => _selectedDay = day),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryTeal
                      : isToday
                      ? AppColors.primaryTeal.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected || isToday
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? Colors.white
                          : isToday
                          ? AppColors.primaryTeal
                          : AppColors.textDark,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      }),
    );
  }
}
