import 'package:flutter/material.dart';
import '../main.dart';
import 'chatbot_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _selectedDate = DateTime.now();
  final List<DateTime> _weeklyDates = List.generate(
    7,
    (index) => DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1)).add(Duration(days: index)),
  );

  // Sample medications for "Scheduled for this day"
  final List<Map<String, dynamic>> _medications = []; // Empty to show the mockup's empty state

  String get _monthName => [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ][_selectedDate.month - 1];

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
                  // --- Header ---
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.primaryTeal.withOpacity(0.1),
                          shape: BoxShape.circle,
                          image: const DecorationImage(
                            image: NetworkImage('https://i.pravatar.cc/150?u=hanie'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Hello, Hanie",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            "Welcome !",
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textGrey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // --- Date & Weekly Calendar ---
                  Text(
                    "Today , $_monthName ${_selectedDate.day}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(Icons.chevron_left, color: AppColors.textGrey, size: 20),
                      ..._weeklyDates.map((date) => _buildDayItem(date)),
                      const Icon(Icons.chevron_right, color: AppColors.textGrey, size: 20),
                    ],
                  ),
                  const SizedBox(height: 48),

                  // --- Medication List / Empty State ---
                  if (_medications.isEmpty)
                    Center(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.medication_liquid_rounded,
                            size: 120,
                            color: AppColors.primaryTeal,
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            "No Medications are\nScheduled for this day",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "If you haven't added a medication,please do so now.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textGrey.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () {
                                // Logic to navigate or switch tab to Add Meds
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2D6E72),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                "Add",
                                style: TextStyle(color: Colors.white, fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const SizedBox.shrink(),

                  const SizedBox(height: 100),
                ],
              ),
            ),

            // --- Floating AI Chatbot Button ---
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

  Widget _buildDayItem(DateTime date) {
    final isSelected = date.day == _selectedDate.day;
    final weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    
    return GestureDetector(
      onTap: () => setState(() => _selectedDate = date),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                border: Border.all(color: AppColors.primaryTeal.withOpacity(0.3)),
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
