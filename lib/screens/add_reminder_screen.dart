import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../models/medicine.dart';
import '../providers/medicine_provider.dart';
import '../providers/user_provider.dart';

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

class _AddReminderScreenState extends State<AddReminderScreen> {
  late TextEditingController _nameController;
  bool _isActive = true;

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 45);
  String _frequency = "Every 6 Hours , 3 times a day";
  DateTime _expiryDate = DateTime(2026, 7, 19);
  dynamic get time => _time = time;
  set time(value) => _time = value;

  String _doseAmount = "1 Tablet";
  int _initialStock = 30;
  final TextEditingController _noteController = TextEditingController();

  // Additional fields from Medicine model
  final TextEditingController _dosageController = TextEditingController();
  int? _currentPillCount;
  int? _lowStockThreshold;
  int? _dosesPerPeriod;
  String? _periodUnit;
  int? _periodValue;
  int? _intervalHours;
  bool _notificationActive = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text:
          widget.initialMedicine?.name ?? widget.initialDrugName ?? "Metformin",
    );

    // If editing an existing medicine, populate fields
    if (widget.initialMedicine != null) {
      final m = widget.initialMedicine!;
      _isActive =
          m.status == MedicineStatus.scheduled ||
          m.status == MedicineStatus.taken;
      _startDate = m.startDate;
      _endDate = m.endDate;
      _time = m.time;
      _frequency = m.frequency;
      _expiryDate = m.expiryDate;
      _doseAmount = m.doseAmount;
      _initialStock = m.initialStock;
      _noteController.text = m.note;
      _dosageController.text = m.dosage ?? '';
      _currentPillCount = m.currentPillCount;
      _lowStockThreshold = m.lowStockThreshold;
      _dosesPerPeriod = m.dosesPerPeriod;
      _periodUnit = m.periodUnit;
      _periodValue = m.periodValue;
      _intervalHours = m.intervalHours;
      _notificationActive = m.notificationActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(
    BuildContext context,
    DateTime initialDate,
    Function(DateTime) onPicked,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
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
    if (picked != null && picked != initialDate) {
      setState(() {
        onPicked(picked);
      });
    }
  }

  void _showFrequencyBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FrequencySelector(
        onDone: (freq) {
          setState(() {
            _frequency = freq;
          });
        },
      ),
    );
  }

  void _showDoseBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _DoseSelector(
        onDone: (dose) {
          setState(() {
            _doseAmount = dose;
          });
        },
      ),
    );
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Medicine Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundCream,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Image.network(
                      'https://www.metformin.ws/wp-content/uploads/2018/10/metformin-bottle.png', // Placeholder
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.medication,
                        color: AppColors.primaryTeal,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _nameController.text,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            const Text(
              "Schedule",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    title: "Start date",
                    value: DateFormat('d MMMM').format(_startDate),
                    icon: Icons.calendar_today_outlined,
                    onTap: () =>
                        _selectDate(context, _startDate, (d) => _startDate = d),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoCard(
                    title: "End date",
                    value: DateFormat('d MMMM').format(_endDate),
                    icon: Icons.calendar_today_outlined,
                    onTap: () =>
                        _selectDate(context, _endDate, (d) => _endDate = d),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildInfoCard(
              title: "Time",
              value: _time.format(context),
              icon: Icons.access_time,
              onTap: () async {
                final TimeOfDay? picked = await showTimePicker(
                  context: context,
                  initialTime: _time,
                );
                if (picked != null) setState(() => _time = picked);
              },
            ),
            const SizedBox(height: 16),

            _buildInfoCard(
              title: "Frequency",
              value: _frequency,
              icon: Icons.alarm,
              onTap: _showFrequencyBottomSheet,
            ),
            const SizedBox(height: 16),

            _buildInfoCard(
              title: "Expiry date",
              value: DateFormat('d MMMM y').format(_expiryDate),
              icon: Icons.calendar_today_outlined,
              onTap: () =>
                  _selectDate(context, _expiryDate, (d) => _expiryDate = d),
            ),

            const SizedBox(height: 32),
            const Text(
              "Dose",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    title: "Dose amount",
                    value: _doseAmount,
                    icon: Icons.medication_rounded,
                    onTap: _showDoseBottomSheet,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoCard(
                    title: "Initial stock",
                    value: "$_initialStock Pills",
                    icon: Icons.track_changes,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          final TextEditingController stockController =
                              TextEditingController(
                                text: _initialStock.toString(),
                              );
                          return AlertDialog(
                            title: const Text("Initial stock"),
                            content: TextField(
                              controller: stockController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: "Enter number of pills",
                                border: OutlineInputBorder(),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  "Cancel",
                                  style: TextStyle(color: AppColors.textGrey),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _initialStock =
                                        int.tryParse(stockController.text) ?? 0;
                                  });
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryTeal,
                                ),
                                child: const Text(
                                  "Save",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Dosage field
            Text(
              "Dosage",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textGrey,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.medication_liquid,
                    color: AppColors.textGrey,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _dosageController,
                      decoration: InputDecoration(
                        hintText: "e.g. 500mg",
                        hintStyle: TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Stock & Threshold
            const Text(
              "Stock Management",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    title: "Current pills",
                    value: _currentPillCount != null
                        ? "$_currentPillCount Pills"
                        : "Not set",
                    icon: Icons.inventory_2_outlined,
                    onTap: () {
                      _showNumberInputDialog(
                        title: "Current Pill Count",
                        initialValue: _currentPillCount,
                        onSave: (val) =>
                            setState(() => _currentPillCount = val),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoCard(
                    title: "Low stock alert",
                    value: _lowStockThreshold != null
                        ? "$_lowStockThreshold Pills"
                        : "Not set",
                    icon: Icons.warning_amber_rounded,
                    onTap: () {
                      _showNumberInputDialog(
                        title: "Low Stock Threshold",
                        initialValue: _lowStockThreshold,
                        onSave: (val) =>
                            setState(() => _lowStockThreshold = val),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Scheduling details
            const Text(
              "Advanced Scheduling",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    title: "Doses / period",
                    value: _dosesPerPeriod != null
                        ? "$_dosesPerPeriod"
                        : "Not set",
                    icon: Icons.repeat,
                    onTap: () {
                      _showNumberInputDialog(
                        title: "Doses Per Period",
                        initialValue: _dosesPerPeriod,
                        onSave: (val) => setState(() => _dosesPerPeriod = val),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoCard(
                    title: "Period value",
                    value: _periodValue != null ? "$_periodValue" : "Not set",
                    icon: Icons.timelapse,
                    onTap: () {
                      _showNumberInputDialog(
                        title: "Period Value",
                        initialValue: _periodValue,
                        onSave: (val) => setState(() => _periodValue = val),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    title: "Period unit",
                    value: _periodUnit ?? "Not set",
                    icon: Icons.calendar_view_day,
                    onTap: () {
                      _showPeriodUnitPicker();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoCard(
                    title: "Interval hours",
                    value: _intervalHours != null
                        ? "$_intervalHours hrs"
                        : "Not set",
                    icon: Icons.hourglass_bottom,
                    onTap: () {
                      _showNumberInputDialog(
                        title: "Interval Hours",
                        initialValue: _intervalHours,
                        onSave: (val) => setState(() => _intervalHours = val),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Notification toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.notifications_active,
                        color: AppColors.textGrey,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Notifications",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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
            const SizedBox(height: 16),

            Text(
              "Note",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textGrey,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.note_alt_outlined,
                    color: AppColors.textGrey,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        hintText: "Optional note about the medication",
                        hintStyle: TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving
                    ? null
                    : () async {
                        final userProvider = context.read<UserProvider>();
                        final medProvider = context.read<MedicineProvider>();
                        final token = userProvider.token;

                        if (token == null || token.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please sign in to save medication',
                              ),
                            ),
                          );
                          return;
                        }

                        setState(() => _isSaving = true);

                        // Build medicine object preserving id when editing
                        final medicine = Medicine(
                          id: widget.initialMedicine?.id ?? '',
                          name: _nameController.text.trim(),
                          startDate: _startDate,
                          endDate: _endDate,
                          deadlineDate: DateTime.now(),
                          expiryDate: _expiryDate,
                          frequency: _frequency,
                          time: _time,
                          doseAmount: _doseAmount,
                          initialStock: _initialStock,
                          note: _noteController.text.trim(),
                          dosage: _dosageController.text.isNotEmpty
                              ? _dosageController.text.trim()
                              : null,
                          currentPillCount: _currentPillCount,
                          initialPillCount: null,
                          lowStockThreshold: _lowStockThreshold,
                          dosesPerPeriod: _dosesPerPeriod,
                          periodUnit: _periodUnit,
                          periodValue: _periodValue,
                          intervalHours: _intervalHours,
                          notificationActive: _notificationActive,
                          status:
                              widget.initialMedicine?.status ??
                              MedicineStatus.scheduled,
                        );

                        // If this screen was opened with an existing medicine, update it
                        final success = widget.initialMedicine != null
                            ? await medProvider.updateMedicineOnApi(
                                token,
                                medicine,
                              )
                            : await medProvider.addMedicineToApi(
                                token,
                                medicine,
                              );

                        // Always refresh medicines after add
                        if (success) {
                          await medProvider.fetchMedicinesFromApi(token);
                        }

                        // Ensure local list reflects the changes immediately when editing
                        if (success && widget.initialMedicine != null) {
                          medProvider.updateMedicine(medicine);
                        }

                        setState(() => _isSaving = false);

                        if (success) {
                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Failed to save medication. Try again.',
                              ),
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
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
                        "Save",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
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

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(Icons.chevron_right, size: 18, color: AppColors.textGrey),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(icon, color: AppColors.textGrey, size: 20),
                const SizedBox(width: 8),
                Text(
                  value,
                  style: TextStyle(fontSize: 14, color: AppColors.textDark),
                ),
              ],
            ),
          ],
        ),
      ),
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
              hintText: "Enter a number",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
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
              child: const Text("Save", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showPeriodUnitPicker() {
    final units = ["day", "week", "month"];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Select Period Unit",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...units.map(
                (unit) => ListTile(
                  title: Text(unit),
                  trailing: _periodUnit == unit
                      ? Icon(Icons.check, color: AppColors.primaryTeal)
                      : null,
                  onTap: () {
                    setState(() => _periodUnit = unit);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FrequencySelector extends StatefulWidget {
  final Function(String) onDone;
  const _FrequencySelector({required this.onDone});

  @override
  State<_FrequencySelector> createState() => _FrequencySelectorState();
}

class _FrequencySelectorState extends State<_FrequencySelector> {
  final TextEditingController _repeatController = TextEditingController(
    text: "1",
  );
  String _unit = "Day";
  int _timesPerDay = 3;
  String _gap = "Every 8 Hours";

  final List<String> _units = ["Day", "Week", "Month"];
  final List<String> _gaps = [
    "Every 4 Hours",
    "Every 6 Hours",
    "Every 8 Hours",
    "Every 12 Hours",
    "Every 24 Hours",
  ];

  @override
  void dispose() {
    _repeatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom:
            MediaQuery.of(context).viewInsets.bottom +
            24, // adjust for keyboard
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 40),
              Text(
                "Set frequency",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryTeal,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildRow(
            "Repeat every:",
            Row(
              children: [
                SizedBox(
                  width: 50,
                  height: 36,
                  child: TextField(
                    controller: _repeatController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    onChanged: (val) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _unit,
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.primaryTeal,
                      ),
                      style: TextStyle(
                        color: AppColors.primaryTeal,
                        fontWeight: FontWeight.bold,
                      ),
                      onChanged: (String? newValue) {
                        setState(() {
                          _unit = newValue!;
                        });
                      },
                      items: _units.map<DropdownMenuItem<String>>((
                        String value,
                      ) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildRow(
            "Times per day:",
            Row(
              children: [
                IconButton(
                  onPressed: _timesPerDay > 1
                      ? () => setState(() => _timesPerDay--)
                      : null,
                  icon: Icon(
                    Icons.remove_circle_outline,
                    color: _timesPerDay > 1
                        ? AppColors.textGrey
                        : Colors.grey[300],
                  ),
                ),
                Text(
                  "$_timesPerDay",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _timesPerDay++),
                  icon: Icon(Icons.add_circle, color: AppColors.primaryTeal),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildRow(
            "Gap between doses:",
            Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _gap,
                  icon: const Icon(Icons.unfold_more, size: 16),
                  style: const TextStyle(fontSize: 12, color: Colors.black),
                  onChanged: (String? newValue) {
                    setState(() {
                      _gap = newValue!;
                    });
                  },
                  items: _gaps.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Summary: Take $_timesPerDay Times A Day, $_gap.",
            style: TextStyle(color: AppColors.textGrey, fontSize: 12),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                widget.onDone("Every $_gap, $_timesPerDay times a day");
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text("Done", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, Widget child) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        child,
      ],
    );
  }
}

class _DoseSelector extends StatefulWidget {
  final Function(String) onDone;
  const _DoseSelector({required this.onDone});

  @override
  State<_DoseSelector> createState() => _DoseSelectorState();
}

class _DoseSelectorState extends State<_DoseSelector> {
  double _dose = 1.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 40),
              const Text(
                "Select Dosage",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 150,
            child: ListWheelScrollView.useDelegate(
              itemExtent: 50,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: (i) =>
                  setState(() => _dose = (i + 1) * 0.5),
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: 20,
                builder: (context, index) => Center(
                  child: Text(
                    "${(index + 1) * 0.5}",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: _dose == (index + 1) * 0.5
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: _dose == (index + 1) * 0.5
                          ? AppColors.primaryTeal
                          : AppColors.textGrey,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                widget.onDone("$_dose Tablet");
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text("Done", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
