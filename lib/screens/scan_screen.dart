import 'package:flutter/material.dart';
import '../main.dart';
import 'drug_detail_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});
  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

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
    {
      'name': 'Metformin',
      'type': 'Diabetes',
      'form': 'Tablet • 850mg',
      'color': const Color(0xFFF3E5F5),
      'icon': Icons.bloodtype,
      'iconColor': const Color(0xFF9C27B0),
    },
    {
      'name': 'Omeprazole',
      'type': 'Gastric',
      'form': 'Capsule • 20mg',
      'color': const Color(0xFFFCE4EC),
      'icon': Icons.local_pharmacy,
      'iconColor': const Color(0xFFE91E63),
    },
    {
      'name': 'Cetirizine',
      'type': 'Antihistamine',
      'form': 'Tablet • 10mg',
      'color': const Color(0xFFFFF8E1),
      'icon': Icons.air,
      'iconColor': const Color(0xFFFFA726),
    },
  ];

  List<Map<String, dynamic>> get _filtered {
    if (_query.isEmpty) return _drugs;
    return _drugs
        .where(
          (d) =>
              d['name'].toString().toLowerCase().contains(
                _query.toLowerCase(),
              ) ||
              d['type'].toString().toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Text(
                "Search & Scan",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
              child: Text(
                "Find medications or scan a pill",
                style: TextStyle(fontSize: 14, color: AppColors.textGrey),
              ),
            ),
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: "Search drug name...",
                    hintStyle: TextStyle(
                      color: AppColors.textGrey.withOpacity(0.6),
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: AppColors.textGrey.withOpacity(0.5),
                    ),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Scan card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Camera scanner coming soon!"),
                    backgroundColor: AppColors.primaryTeal,
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2C6E72), Color(0xFF3A9EA5)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryTeal.withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.document_scanner_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Scan Medication",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Use camera to identify a pill",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white70,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _query.isEmpty ? "All Medications" : "Results",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Results
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 56,
                            color: AppColors.textGrey.withOpacity(0.3),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "No results found",
                            style: TextStyle(
                              color: AppColors.textGrey,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _filtered.length,
                      itemBuilder: (context, i) {
                        final d = _filtered[i];
                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DrugDetailScreen(
                                drugName: d['name'],
                                drugCategory: d['type'],
                                drugColor: d['color'],
                                drugIcon: d['icon'],
                                drugIconColor: d['iconColor'],
                              ),
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
                                  child: Icon(
                                    d['icon'],
                                    color: d['iconColor'],
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        d['name'],
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "${d['type']} • ${d['form']}",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textGrey,
                                        ),
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
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
