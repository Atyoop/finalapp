import 'package:flutter/material.dart';
import '../main.dart';
import 'scan_screen.dart';
import 'add_reminder_screen.dart';

class AddMedicineScreen extends StatefulWidget {
  const AddMedicineScreen({super.key});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  // Sample drug data for manual search results
  final List<Map<String, dynamic>> _drugs = [
    {
      'name': 'Amoxicillin',
      'type': 'Antibiotic',
      'form': 'Capsule • 500mg',
      'color': const Color(0xFFE8F5E9),
      'icon': Icons.medication,
      'iconColor': const Color(0xFF4CAF50),
    },
    {
      'name': 'Ibuprofen',
      'type': 'Pain Relief',
      'form': 'Tablet • 200mg',
      'color': const Color(0xFFFFF3E0),
      'icon': Icons.healing,
      'iconColor': const Color(0xFFFF9800),
    },
    {
      'name': 'Paracetamol',
      'type': 'Analgesic',
      'form': 'Tablet • 500mg',
      'color': const Color(0xFFE3F2FD),
      'icon': Icons.medication_liquid,
      'iconColor': const Color(0xFF2196F3),
    },
  ];

  List<Map<String, dynamic>> get _filtered {
    if (_query.isEmpty) return [];
    return _drugs
        .where(
          (d) =>
              d['name'].toString().toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textDark),
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
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Identify Your Medication",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Choose a method to add your medication",
              style: TextStyle(fontSize: 14, color: AppColors.textGrey),
            ),
            const SizedBox(height: 32),

            // Scan Option
            _buildOptionCard(
              title: "Scan Prescription",
              subtitle: "Use camera to identify medication (OCR)",
              icon: Icons.camera_alt_rounded,
              color: AppColors.primaryTeal,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ScanCameraScreen()),
              ),
            ),
            const SizedBox(height: 16),

            // Manual Search Option
            Text(
              "Or search manually",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        hintText: "Type medication name...",
                        hintStyle: TextStyle(
                          color: AppColors.textGrey.withOpacity(0.6),
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: AppColors.textDark,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 18,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ScanCameraScreen(),
                      ),
                    ),
                    child: Container(
                      width: 65,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.primaryTeal,
                        borderRadius: BorderRadius.horizontal(
                          right: Radius.circular(28),
                        ),
                      ),
                      child: const Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (_query.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                "Search Results",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              ..._filtered.map((d) => _buildResultTile(d)),
              if (_filtered.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      "No results found",
                      style: TextStyle(color: AppColors.textGrey),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.1), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textGrey.withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultTile(Map<String, dynamic> d) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddReminderScreen(initialDrugName: d['name']),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: d['color'],
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(d['icon'], color: d['iconColor'], size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d['name'],
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${d['type']} • ${d['form']}",
                    style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.add_circle_outline_rounded,
              color: AppColors.primaryTeal.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }
}
