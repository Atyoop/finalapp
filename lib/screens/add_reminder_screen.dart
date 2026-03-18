import 'package:flutter/material.dart';
import '../main.dart';

class AddReminderScreen extends StatefulWidget {
  const AddReminderScreen({super.key});
  @override
  State<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  final _drugController = TextEditingController();
  int _selectedHour = 8;
  int _selectedMinute = 0;
  bool _isAM = true;
  String _frequency = 'Daily';
  int _duration = 7;

  final List<String> _frequencies = [
    'Daily',
    'Every 8 hours',
    'Every 12 hours',
    'Weekly',
    'As needed',
  ];

  void _showTimePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        int tempHour = _selectedHour;
        int tempMinute = _selectedMinute;
        bool tempAM = _isAM;
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              height: 320,
              child: Column(
                children: [
                  const Text(
                    'Set Time',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Row(
                      children: [
                        // Hour
                        Expanded(
                          child: ListWheelScrollView.useDelegate(
                            itemExtent: 48,
                            physics: const FixedExtentScrollPhysics(),
                            controller: FixedExtentScrollController(
                              initialItem: tempHour - 1,
                            ),
                            onSelectedItemChanged: (i) =>
                                setModalState(() => tempHour = i + 1),
                            childDelegate: ListWheelChildBuilderDelegate(
                              childCount: 12,
                              builder: (ctx, i) => Center(
                                child: Text(
                                  '${i + 1}'.padLeft(2, '0'),
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: tempHour == i + 1
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: tempHour == i + 1
                                        ? AppColors.primaryTeal
                                        : AppColors.textGrey,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const Text(
                          ':',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        // Minute
                        Expanded(
                          child: ListWheelScrollView.useDelegate(
                            itemExtent: 48,
                            physics: const FixedExtentScrollPhysics(),
                            controller: FixedExtentScrollController(
                              initialItem: tempMinute,
                            ),
                            onSelectedItemChanged: (i) =>
                                setModalState(() => tempMinute = i),
                            childDelegate: ListWheelChildBuilderDelegate(
                              childCount: 60,
                              builder: (ctx, i) => Center(
                                child: Text(
                                  '$i'.padLeft(2, '0'),
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: tempMinute == i
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: tempMinute == i
                                        ? AppColors.primaryTeal
                                        : AppColors.textGrey,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // AM/PM
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () => setModalState(() => tempAM = true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: tempAM
                                        ? AppColors.primaryTeal
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'AM',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: tempAM ? Colors.white : AppColors.textGrey,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: () => setModalState(() => tempAM = false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: !tempAM
                                        ? AppColors.primaryTeal
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'PM',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          !tempAM ? Colors.white : AppColors.textGrey,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedHour = tempHour;
                          _selectedMinute = tempMinute;
                          _isAM = tempAM;
                        });
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                      child: const Text(
                        'Done',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showFrequencyPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          height: 350,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Set Frequency',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ..._frequencies.map((f) => GestureDetector(
                    onTap: () {
                      setState(() => _frequency = f);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 14),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: _frequency == f
                            ? AppColors.primaryTeal.withOpacity(0.08)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _frequency == f
                              ? AppColors.primaryTeal
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _frequency == f
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: _frequency == f
                                ? AppColors.primaryTeal
                                : AppColors.textGrey,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            f,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: _frequency == f
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: _frequency == f
                                  ? AppColors.primaryTeal
                                  : AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }

  void _showDurationPicker() {
    int tempDuration = _duration;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              height: 300,
              child: Column(
                children: [
                  const Text(
                    'Set Duration',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListWheelScrollView.useDelegate(
                      itemExtent: 48,
                      physics: const FixedExtentScrollPhysics(),
                      controller:
                          FixedExtentScrollController(initialItem: tempDuration - 1),
                      onSelectedItemChanged: (i) =>
                          setModalState(() => tempDuration = i + 1),
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: 90,
                        builder: (ctx, i) => Center(
                          child: Text(
                            '${i + 1} ${i == 0 ? 'day' : 'days'}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: tempDuration == i + 1
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: tempDuration == i + 1
                                  ? AppColors.primaryTeal
                                  : AppColors.textGrey,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() => _duration = tempDuration);
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                      child: const Text(
                        'Done',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _drugController.dispose();
    super.dispose();
  }

  String get _timeString =>
      '${_selectedHour.toString().padLeft(2, '0')}:${_selectedMinute.toString().padLeft(2, '0')} ${_isAM ? 'AM' : 'PM'}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        title: const Text(
          'Add Reminder',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drug name
            const Text(
              'Drug Name',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textGrey,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _drugController,
                decoration: InputDecoration(
                  hintText: 'Enter drug name',
                  hintStyle: TextStyle(color: AppColors.textGrey),
                  prefixIcon:
                      Icon(Icons.medication, color: AppColors.primaryTeal),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Set Time
            _SettingOption(
              icon: Icons.access_time_rounded,
              title: 'Set Time',
              value: _timeString,
              onTap: _showTimePicker,
            ),

            // Frequency
            _SettingOption(
              icon: Icons.repeat_rounded,
              title: 'Frequency',
              value: _frequency,
              onTap: _showFrequencyPicker,
            ),

            // Duration
            _SettingOption(
              icon: Icons.date_range_rounded,
              title: 'Duration',
              value: '$_duration days',
              onTap: _showDurationPicker,
            ),

            const SizedBox(height: 40),

            // Save
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  if (_drugController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a drug name'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Reminder Added Successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 3,
                  shadowColor: AppColors.primaryTeal.withOpacity(0.3),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  const _SettingOption({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primaryTeal.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primaryTeal, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.primaryTeal,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textGrey.withOpacity(0.4),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
