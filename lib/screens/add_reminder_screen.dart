import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../models/medicine.dart';
import '../providers/medicine_provider.dart';
import '../providers/user_provider.dart';
import '../utils/time_helpers.dart';
import '../widgets/interaction_warning_dialog.dart';

class AddReminderScreen extends StatefulWidget {
  final String? initialDrugName;
  final Medicine? initialMedicine;

  const AddReminderScreen({
    super.key,
    this.initialDrugName,
    this.initialMedicine,
  });

  @override
  State<AddReminderScreen> createState() => _AddReminderScreenState();
}

// Schedule types for simple selection
enum ScheduleType { everyXHours, xTimesPerDay }

class _ScheduleConfig {
  ScheduleType type;
  int intervalHours; // for everyXHours mode
  List<TimeOfDay> doseTimes; // for xTimesPerDay mode
  DateTime startDate;
  DateTime? endDate;
  TimeOfDay
  firstDoseTime; // mutable: user-selected for interval, or earliest for custom

  /// Alias for backward compatibility with code referencing .value
  int get value => intervalHours;

  _ScheduleConfig({
    this.type = ScheduleType.everyXHours,
    this.intervalHours = 6,
    this.doseTimes = const [],
    required this.startDate,
    this.endDate,
    this.firstDoseTime = const TimeOfDay(hour: 8, minute: 0),
  });

  /// Get the effective first dose time for API
  TimeOfDay get effectiveFirstDoseTime {
    if (type == ScheduleType.xTimesPerDay && doseTimes.isNotEmpty) {
      final sorted = List<TimeOfDay>.from(doseTimes)
        ..sort(
          (a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute),
        );
      return sorted.first;
    }
    return firstDoseTime;
  }

  /// Convert schedule config to API fields
  Map<String, dynamic> toApiFields() {
    if (type == ScheduleType.everyXHours) {
      return {
        'scheduleType': 'Interval',
        'intervalHours': intervalHours,
        'doseTimes': <String>[],
        'dosesPerPeriod': null,
        'periodUnit': null,
        'periodValue': null,
      };
    } else {
      // Sort dose times and get earliest as first dose
      final sortedTimes = List<TimeOfDay>.from(doseTimes)
        ..sort(
          (a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute),
        );

      final doseTimeStrings = normalizeDoseTimesBeforeSave(sortedTimes);

      return {
        'scheduleType': 'CustomTimes',
        'doseTimes': doseTimeStrings,
        'firstDoseTime': doseTimeStrings.isNotEmpty
            ? doseTimeStrings.first
            : null,
        'dosesPerPeriod': doseTimeStrings.length,
        'periodUnit': 'Day',
        'periodValue': 1,
        'intervalHours': null,
      };
    }
  }

  String getDisplayText() {
    if (type == ScheduleType.everyXHours) {
      final h = firstDoseTime.hour.toString().padLeft(2, '0');
      final m = firstDoseTime.minute.toString().padLeft(2, '0');
      return 'Every $intervalHours hours starting $h:$m';
    } else {
      if (doseTimes.isEmpty) {
        return 'Add dose times';
      }
      final sortedTimes = List<TimeOfDay>.from(doseTimes)
        ..sort(
          (a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute),
        );

      final timeStrings = sortedTimes.map((t) {
        final hour = t.hour.toString().padLeft(2, '0');
        final minute = t.minute.toString().padLeft(2, '0');
        return '$hour:$minute';
      }).toList();

      return '${doseTimes.length} times per day: ${timeStrings.join(', ')}';
    }
  }
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  late TextEditingController _nameController;
  late TextEditingController _dosageController;
  late TextEditingController _noteController;

  // Schedule configuration
  late _ScheduleConfig _schedule;

  // Stock management
  int? _stock;
  int? _lowStockThreshold;
  DateTime? _expiryDate;

  // Pills per dose
  int _pillsPerDose = 1;

  // Notifications
  bool _notificationActive = true;

  // UI state
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialMedicine?.name ?? widget.initialDrugName ?? "Panadol",
    );
    _dosageController = TextEditingController(
      text: widget.initialMedicine?.dosage ?? '',
    );
    _noteController = TextEditingController(
      text: widget.initialMedicine?.note ?? '',
    );

    // Initialize schedule with proper dose times loading
    final med = widget.initialMedicine;

    // Determine schedule type from the medicine
    ScheduleType scheduleType = ScheduleType.everyXHours;
    List<TimeOfDay> doseTimes = const [];

    if (med != null) {
      if (med.scheduleType == 'CustomTimes' &&
          med.doseTimes != null &&
          med.doseTimes!.isNotEmpty) {
        scheduleType = ScheduleType.xTimesPerDay;
        // Convert API time strings to TimeOfDay
        doseTimes = med.doseTimes!
            .map((timeStr) => parseApiTimeToTimeOfDay(timeStr))
            .toList();
      } else if (med.scheduleType == 'Interval' || med.intervalHours != null) {
        scheduleType = ScheduleType.everyXHours;
      }
    }

    _schedule = _ScheduleConfig(
      type: scheduleType,
      intervalHours: med?.intervalHours ?? 6,
      doseTimes: doseTimes,
      startDate: med?.startDate ?? DateTime.now(),
      endDate: med?.endDate,
      firstDoseTime: med?.time ?? const TimeOfDay(hour: 8, minute: 0),
    );

    // Initialize stock
    _stock = med?.currentPillCount ?? 30;
    _lowStockThreshold = med?.lowStockThreshold;
    _expiryDate = med?.expiryDate;

    // Initialize pills per dose
    _pillsPerDose = med?.pillsPerDose ?? 1;

    _notificationActive = med?.notificationActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _showScheduleSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ScheduleSelector(
        config: _schedule,
        onSave: (newConfig) {
          setState(() {
            _schedule = newConfig;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  /// Validate all required fields
  String? _validate() {
    if (_nameController.text.trim().isEmpty) {
      return 'Please enter medication name';
    }
    if (_schedule.type == ScheduleType.everyXHours &&
        _schedule.intervalHours <= 0) {
      return 'Interval hours must be greater than 0';
    }
    if (_schedule.type == ScheduleType.xTimesPerDay &&
        _schedule.doseTimes.isEmpty) {
      return 'Please add at least one dose time';
    }
    if (_stock != null && _stock! < 0) {
      return 'Stock cannot be negative';
    }
    if (_lowStockThreshold != null && _lowStockThreshold! < 0) {
      return 'Low stock threshold cannot be negative';
    }
    if (_lowStockThreshold != null &&
        _stock != null &&
        _lowStockThreshold! > _stock!) {
      return 'Low stock threshold cannot be greater than current stock';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Add Medicine',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Medication Name Card
            _buildCardSection(
              title: 'Medication',
              icon: Icons.medication_rounded,
              child: GestureDetector(
                onTap: () {
                  // Show name editor
                  showDialog(
                    context: context,
                    builder: (context) {
                      final controller = TextEditingController(
                        text: _nameController.text,
                      );
                      return AlertDialog(
                        title: const Text('Medication Name'),
                        content: TextField(
                          controller: controller,
                          decoration: InputDecoration(
                            hintText: 'e.g. Panadol 500mg',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Cancel',
                              style: TextStyle(color: AppColors.textGrey),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _nameController.text = controller.text;
                              });
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryTeal,
                            ),
                            child: const Text(
                              'Save',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.textGrey.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _nameController.text.isNotEmpty
                                  ? _nameController.text
                                  : 'Tap to enter medication name',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.edit_outlined,
                        color: AppColors.primaryTeal,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 2. Dosage Card
            _buildCardSection(
              title: 'Dosage',
              icon: Icons.medication_liquid,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          final controller = TextEditingController(
                            text: _dosageController.text,
                          );
                          return AlertDialog(
                            title: const Text('Dosage Strength'),
                            content: TextField(
                              controller: controller,
                              decoration: InputDecoration(
                                hintText: 'e.g. 500mg',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(color: AppColors.textGrey),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _dosageController.text = controller.text;
                                  });
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryTeal,
                                ),
                                child: const Text(
                                  'Save',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.textGrey.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Strength',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textGrey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _dosageController.text.isNotEmpty
                                    ? _dosageController.text
                                    : 'Not set',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.edit_outlined,
                            color: AppColors.primaryTeal,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Pills Per Dose stepper
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.textGrey.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pills per dose',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textGrey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Pills deducted per scheduled dose',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textGrey.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: _pillsPerDose > 1
                                  ? () => setState(() => _pillsPerDose--)
                                  : null,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _pillsPerDose > 1
                                      ? AppColors.primaryTeal.withValues(
                                          alpha: 0.1)
                                      : Colors.grey[100],
                                ),
                                child: Icon(
                                  Icons.remove,
                                  size: 18,
                                  color: _pillsPerDose > 1
                                      ? AppColors.primaryTeal
                                      : Colors.grey[400],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12),
                              child: Text(
                                '$_pillsPerDose pill${_pillsPerDose > 1 ? 's' : ''}',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _pillsPerDose++),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primaryTeal
                                      .withValues(alpha: 0.1),
                                ),
                                child: Icon(
                                  Icons.add,
                                  size: 18,
                                  color: AppColors.primaryTeal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. Schedule Card
            _buildCardSection(
              title: 'Schedule',
              icon: Icons.schedule_rounded,
              child: GestureDetector(
                onTap: _showScheduleSheet,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.textGrey.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _schedule.getDisplayText(),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start: ${DateFormat('MMM d, yyyy').format(_schedule.startDate)}'
                              '${_schedule.endDate != null ? ' • End: ${DateFormat('MMM d, yyyy').format(_schedule.endDate!)}' : ''}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.edit_outlined,
                        color: AppColors.primaryTeal,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 4. Stock Card
            _buildCardSection(
              title: 'Stock Management',
              icon: Icons.inventory_2_outlined,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      _showNumberInputDialog(
                        title: 'Current Stock',
                        initialValue: _stock,
                        onSave: (val) => setState(() => _stock = val),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.textGrey.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current Stock',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textGrey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _stock != null ? '$_stock pills' : 'Not set',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.edit_outlined,
                            color: AppColors.primaryTeal,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      _showNumberInputDialog(
                        title: 'Low Stock Alert',
                        initialValue: _lowStockThreshold,
                        onSave: (val) =>
                            setState(() => _lowStockThreshold = val),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.textGrey.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Low Stock Alert',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textGrey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _lowStockThreshold != null
                                    ? 'Remind at $_lowStockThreshold pills'
                                    : 'Not set',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.edit_outlined,
                            color: AppColors.primaryTeal,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _expiryDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2101),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: AppColors.primaryTeal,
                                onPrimary: Colors.white,
                                onSurface: AppColors.textDark,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (!mounted) return;
                      if (picked != null) {
                        setState(() => _expiryDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.textGrey.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Expiry Date',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textGrey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _expiryDate != null
                                    ? DateFormat(
                                        'MMM d, yyyy',
                                      ).format(_expiryDate!)
                                    : 'Not set',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.edit_outlined,
                            color: AppColors.primaryTeal,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 5. Notifications Card
            _buildCardSection(
              title: 'Notifications',
              icon: Icons.notifications_active_rounded,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.textGrey.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _notificationActive ? 'Enabled' : 'Disabled',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    Switch(
                      value: _notificationActive,
                      activeThumbColor: AppColors.primaryTeal,
                      onChanged: (val) =>
                          setState(() => _notificationActive = val),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 6. Notes Card
            _buildCardSection(
              title: 'Notes',
              icon: Icons.note_alt_outlined,
              child: GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      final controller = TextEditingController(
                        text: _noteController.text,
                      );
                      return AlertDialog(
                        title: const Text('Notes'),
                        content: TextField(
                          controller: controller,
                          minLines: 3,
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText: 'Optional notes about this medication',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Cancel',
                              style: TextStyle(color: AppColors.textGrey),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _noteController.text = controller.text;
                              });
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryTeal,
                            ),
                            child: const Text(
                              'Save',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.textGrey.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _noteController.text.isNotEmpty
                                  ? _noteController.text
                                  : 'Tap to add notes',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.edit_outlined,
                        color: AppColors.primaryTeal,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveMedicine,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  disabledBackgroundColor: AppColors.primaryTeal.withValues(
                    alpha: 0.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Save Medicine',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildCardSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primaryTeal, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textGrey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }

  void _showNumberInputDialog({
    required String title,
    int? initialValue,
    required Function(int?) onSave,
  }) {
    final controller = TextEditingController(
      text: initialValue?.toString() ?? '',
    );
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Enter a number',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.textGrey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final val = int.tryParse(controller.text);
                onSave(val);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
              ),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showSafetyAlert(List<String> warnings) async {
    await showInteractionWarningDialog(context, warnings);
  }

  Future<void> _saveMedicine() async {
    final validation = _validate();
    if (validation != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validation)));
      return;
    }

    final userProvider = context.read<UserProvider>();
    final medProvider = context.read<MedicineProvider>();
    final token = userProvider.token;

    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to save medication')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Get schedule fields with new API format
      final scheduleFields = _schedule.toApiFields();

      // Determine first dose time based on schedule type
      final TimeOfDay firstDoseTime = _schedule.effectiveFirstDoseTime;

      // Build medicine object with all fields
      final medicine = Medicine(
        id: widget.initialMedicine?.id ?? '',
        name: _nameController.text.trim(),
        startDate: _schedule.startDate,
        endDate:
            _schedule.endDate ??
            _schedule.startDate.add(const Duration(days: 30)),
        deadlineDate: DateTime.now(),
        expiryDate:
            _expiryDate ?? DateTime.now().add(const Duration(days: 365)),
        frequency: _schedule.getDisplayText(),
        time: firstDoseTime,
        doseAmount: '$_pillsPerDose Tablet${_pillsPerDose != 1 ? 's' : ''}',
        initialStock: _stock ?? 0,
        note: _noteController.text.trim(),
        dosage: _dosageController.text.isNotEmpty
            ? _dosageController.text.trim()
            : null,
        currentPillCount: _stock,
        initialPillCount: _stock,
        lowStockThreshold: _lowStockThreshold,
        dosesPerPeriod: scheduleFields['dosesPerPeriod'] as int?,
        periodUnit: scheduleFields['periodUnit'] as String?,
        periodValue: scheduleFields['periodValue'] as int?,
        intervalHours: scheduleFields['intervalHours'] as int?,
        notificationActive: _notificationActive,
        status: widget.initialMedicine?.status ?? MedicineStatus.scheduled,
        scheduleType: scheduleFields['scheduleType'] as String?,
        doseTimes: scheduleFields['doseTimes'] as List<String>?,
        pillsPerDose: _pillsPerDose,
      );

      if (widget.initialMedicine != null) {
        // --- Edit existing medication ---
        final success = await medProvider.updateMedicineOnApi(token, medicine);
        if (success) {
          await medProvider.fetchMedicinesFromApi(token);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Medicine updated successfully')),
            );
            Navigator.pop(context);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(medProvider.error ?? 'Failed to update')),
            );
          }
        }
      } else {
        // --- Add new medication ---
        final response = await medProvider.addMedicineToApi(token, medicine);
        if (response != null) {
          // Check for interaction warnings
          if (response.hasInteractionWarnings) {
            await _showSafetyAlert(response.interactionWarnings);
          }

          // Refresh My Meds
          await medProvider.fetchMedicinesFromApi(token);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Medicine added successfully')),
            );
            Navigator.pop(context);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(medProvider.error ?? 'Failed to add')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

/// Schedule selector bottom sheet
class _ScheduleSelector extends StatefulWidget {
  final _ScheduleConfig config;
  final Function(_ScheduleConfig) onSave;

  const _ScheduleSelector({required this.config, required this.onSave});

  @override
  State<_ScheduleSelector> createState() => _ScheduleSelectorState();
}

class _ScheduleSelectorState extends State<_ScheduleSelector> {
  late ScheduleType _selectedType;
  late int _intervalHours;
  late List<TimeOfDay> _doseTimes;
  late DateTime _startDate;
  late DateTime? _endDate;
  late TimeOfDay _firstDoseTime;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.config.type;
    _intervalHours = widget.config.intervalHours;
    _doseTimes =
        _selectedType == ScheduleType.xTimesPerDay &&
            widget.config.doseTimes.isNotEmpty
        ? List<TimeOfDay>.from(widget.config.doseTimes)
        : <TimeOfDay>[const TimeOfDay(hour: 8, minute: 0)];
    _startDate = widget.config.startDate;
    _endDate = widget.config.endDate;
    _firstDoseTime = widget.config.firstDoseTime;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Schedule',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Schedule Type',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textGrey,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundCream,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _selectedType = ScheduleType.everyXHours;
                        // Clear dose times when switching to Interval
                        _doseTimes = <TimeOfDay>[];
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedType == ScheduleType.everyXHours
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Every X Hours',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _selectedType == ScheduleType.everyXHours
                                ? AppColors.primaryTeal
                                : AppColors.textGrey,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _selectedType = ScheduleType.xTimesPerDay;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedType == ScheduleType.xTimesPerDay
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'X Times Per Day',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _selectedType == ScheduleType.xTimesPerDay
                                ? AppColors.primaryTeal
                                : AppColors.textGrey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_selectedType == ScheduleType.everyXHours) ...[
              const Text(
                'Interval (hours)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.textGrey.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: _intervalHours > 1
                          ? () => setState(() => _intervalHours--)
                          : null,
                      icon: Icon(
                        Icons.remove_circle_outline,
                        color: _intervalHours > 1
                            ? AppColors.primaryTeal
                            : Colors.grey[300],
                      ),
                    ),
                    Text(
                      '$_intervalHours hours',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _intervalHours++),
                      icon: Icon(
                        Icons.add_circle,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'First Dose Time',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _firstDoseTime,
                    builder: (ctx, child) => Theme(
                      data: Theme.of(ctx).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: AppColors.primaryTeal,
                          onPrimary: Colors.white,
                          onSurface: AppColors.textDark,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) setState(() => _firstDoseTime = picked);
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.textGrey.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _firstDoseTime.format(context),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(Icons.access_time, color: AppColors.primaryTeal),
                    ],
                  ),
                ),
              ),
            ] else ...[
              const Text(
                'Dose Times',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 12),
              ..._doseTimes
                  .asMap()
                  .entries
                  .map(
                    (entry) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.textGrey.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            entry.value.format(context),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.redAccent,
                            ),
                            onPressed: () {
                              setState(() {
                                _doseTimes.removeAt(entry.key);
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              TextButton.icon(
                onPressed: () async {
                  final TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 8, minute: 0),
                  );
                  if (!mounted) return;
                  if (picked != null) {
                    final exists = _doseTimes.any(
                      (t) => t.hour == picked.hour && t.minute == picked.minute,
                    );
                    if (!exists) {
                      setState(() {
                        _doseTimes.add(picked);
                        _doseTimes.sort(
                          (a, b) => a.hour != b.hour
                              ? a.hour - b.hour
                              : a.minute - b.minute,
                        );
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('This time is already added.'),
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(
                  Icons.add_circle,
                  color: AppColors.primaryTeal,
                ),
                label: const Text('Add dose time'),
              ),
              if (_doseTimes.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Please add at least one dose time.',
                    style: TextStyle(color: Colors.redAccent, fontSize: 13),
                  ),
                ),
              const SizedBox(height: 20),
            ],
            const Text(
              'Start Date',

              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textGrey,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2101),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: AppColors.primaryTeal,
                          onPrimary: Colors.white,
                          onSurface: AppColors.textDark,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (!mounted) return;
                if (picked != null) {
                  setState(() => _startDate = picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.textGrey.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('MMM d, yyyy').format(_startDate),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      Icons.calendar_today_outlined,
                      color: AppColors.primaryTeal,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'End Date (Optional)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textGrey,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate:
                      _endDate ?? _startDate.add(const Duration(days: 30)),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2101),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: AppColors.primaryTeal,
                          onPrimary: Colors.white,
                          onSurface: AppColors.textDark,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (!mounted) return;
                if (picked != null) {
                  setState(() => _endDate = picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.textGrey.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _endDate != null
                          ? DateFormat('MMM d, yyyy').format(_endDate!)
                          : 'Not set',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _endDate != null
                            ? AppColors.textDark
                            : AppColors.textGrey,
                      ),
                    ),
                    Icon(
                      Icons.calendar_today_outlined,
                      color: AppColors.primaryTeal,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed:
                    (_selectedType == ScheduleType.everyXHours &&
                            _intervalHours > 0) ||
                        (_selectedType == ScheduleType.xTimesPerDay &&
                            _doseTimes.isNotEmpty)
                    ? () {
                        final config = _selectedType == ScheduleType.everyXHours
                            ? _ScheduleConfig(
                                type: _selectedType,
                                intervalHours: _intervalHours,
                                startDate: _startDate,
                                endDate: _endDate,
                                firstDoseTime: _firstDoseTime,
                              )
                            : _ScheduleConfig(
                                type: _selectedType,
                                doseTimes: List<TimeOfDay>.from(_doseTimes),
                                startDate: _startDate,
                                endDate: _endDate,
                              );
                        widget.onSave(config);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Save Schedule',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
