import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../models/medicine.dart';
import '../providers/medicine_provider.dart';

class AddReminderScreen extends StatefulWidget {
  final String? initialDrugName;
  const AddReminderScreen({super.key, this.initialDrugName});

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

  String _doseAmount = "1 Tablet";
  final int _initialStock = 30;
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialDrugName ?? "Metformin",
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
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
            colorScheme: const ColorScheme.light(
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
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AppColors.textDark,
            size: 20,
          ),
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
                    color: Colors.black.withOpacity(0.04),
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
                      errorBuilder: (context, error, stackTrace) => const Icon(
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
                  Switch(
                    value: _isActive,
                    onChanged: (val) => setState(() => _isActive = val),
                    activeThumbColor: AppColors.primaryTeal,
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
                      // Logic for stock
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            const Text(
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
                  const Icon(
                    Icons.calendar_today,
                    color: AppColors.textGrey,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _noteController,
                      decoration: const InputDecoration(
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
                onPressed: () {
                  final medicine = Medicine(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: _nameController.text,
                    imageUrl:
                        'https://www.metformin.ws/wp-content/uploads/2018/10/metformin-bottle.png',
                    startDate: _startDate,
                    endDate: _endDate,
                    deadlineDate: _expiryDate.subtract(
                      const Duration(days: 14),
                    ), // 2 weeks before
                    expiryDate: _expiryDate,
                    frequency: _frequency,
                    time: _time,
                    doseAmount: _doseAmount,
                    initialStock: _initialStock,
                    note: _noteController.text,
                  );
                  context.read<MedicineProvider>().addMedicine(medicine);
                  Navigator.pop(context); // Go back to Add Medicine screen
                  // Optional: Show a snackbar or small msg!
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Medicine added successfully.'),
                      backgroundColor: AppColors.primaryTeal,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  "Add Medicine",
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
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppColors.textGrey,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(icon, color: AppColors.textGrey, size: 20),
                const SizedBox(width: 8),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
  final int _repeatEvery = 1;
  final String _unit = "Day";
  int _timesPerDay = 3;
  final String _gap = "Every 8 Hours";

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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text("$_repeatEvery"),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _unit,
                    style: const TextStyle(color: AppColors.primaryTeal),
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
                  onPressed: () => setState(() => _timesPerDay--),
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: AppColors.textGrey,
                  ),
                ),
                Text("$_timesPerDay"),
                IconButton(
                  onPressed: () => setState(() => _timesPerDay++),
                  icon: const Icon(
                    Icons.add_circle,
                    color: AppColors.primaryTeal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildRow(
            "Gap between doses:",
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(_gap, style: const TextStyle(fontSize: 12)),
                  const Icon(Icons.unfold_more, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Summary: Take 3 Times A Day, Every 8 Hours.",
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
