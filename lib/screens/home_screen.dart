import 'package:flutter/material.dart';
import '../main.dart';
import 'drug_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Sample drug data
  static final List<Map<String, dynamic>> _featuredDrugs = [
    {
      'name': 'Amoxicillin',
      'category': 'Antibiotic',
      'color': const Color(0xFFE8F5E9),
      'icon': Icons.medication,
      'iconColor': const Color(0xFF4CAF50),
    },
    {
      'name': 'Ibuprofen',
      'category': 'Pain Relief',
      'color': const Color(0xFFFFF3E0),
      'icon': Icons.healing,
      'iconColor': const Color(0xFFFF9800),
    },
    {
      'name': 'Metformin',
      'category': 'Diabetes',
      'color': const Color(0xFFE3F2FD),
      'icon': Icons.bloodtype,
      'iconColor': const Color(0xFF2196F3),
    },
    {
      'name': 'Omeprazole',
      'category': 'Gastric',
      'color': const Color(0xFFF3E5F5),
      'icon': Icons.local_pharmacy,
      'iconColor': const Color(0xFF9C27B0),
    },
  ];

  static final List<Map<String, dynamic>> _allMedications = [
    {
      'name': 'Paracetamol',
      'type': 'Analgesic',
      'form': 'Tablet • 500mg',
      'color': const Color(0xFFE8F5E9),
      'icon': Icons.medication_liquid,
      'iconColor': const Color(0xFF66BB6A),
    },
    {
      'name': 'Cetirizine',
      'type': 'Antihistamine',
      'form': 'Tablet • 10mg',
      'color': const Color(0xFFFFF8E1),
      'icon': Icons.medication,
      'iconColor': const Color(0xFFFFA726),
    },
    {
      'name': 'Aspirin',
      'type': 'NSAID',
      'form': 'Tablet • 100mg',
      'color': const Color(0xFFE3F2FD),
      'icon': Icons.local_hospital,
      'iconColor': const Color(0xFF42A5F5),
    },
    {
      'name': 'Lisinopril',
      'type': 'ACE Inhibitor',
      'form': 'Tablet • 20mg',
      'color': const Color(0xFFFCE4EC),
      'icon': Icons.favorite,
      'iconColor': const Color(0xFFEF5350),
    },
    {
      'name': 'Atorvastatin',
      'type': 'Statin',
      'form': 'Tablet • 40mg',
      'color': const Color(0xFFF3E5F5),
      'icon': Icons.science,
      'iconColor': const Color(0xFFAB47BC),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header ---
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primaryTeal.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        color: AppColors.primaryTeal,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Hello, User 👋",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "How are you feeling today?",
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Notification Bell
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        color: AppColors.textDark,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // --- Search Bar ---
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
                    decoration: InputDecoration(
                      hintText: "Search medications...",
                      hintStyle: TextStyle(
                        color: AppColors.textGrey.withOpacity(0.6),
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: AppColors.textGrey.withOpacity(0.5),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // --- Discover Drugs Section ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Discover Drugs",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        "See all",
                        style: TextStyle(
                          color: AppColors.primaryTeal,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Horizontal scroll cards
              SizedBox(
                height: 170,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _featuredDrugs.length,
                  itemBuilder: (context, index) {
                    final drug = _featuredDrugs[index];
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DrugDetailScreen(
                            drugName: drug['name'],
                            drugCategory: drug['category'],
                            drugColor: drug['color'],
                            drugIcon: drug['icon'],
                            drugIconColor: drug['iconColor'],
                          ),
                        ),
                      ),
                      child: Container(
                        width: 140,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
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
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: drug['color'],
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Icon(
                                drug['icon'],
                                color: drug['iconColor'],
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              drug['name'],
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              drug['category'],
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 28),

              // --- All Medications Section ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "All Medications",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        "See all",
                        style: TextStyle(
                          color: AppColors.primaryTeal,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Medications list
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _allMedications.length,
                itemBuilder: (context, index) {
                  final med = _allMedications[index];
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DrugDetailScreen(
                          drugName: med['name'],
                          drugCategory: med['type'],
                          drugColor: med['color'],
                          drugIcon: med['icon'],
                          drugIconColor: med['iconColor'],
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
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: med['color'],
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              med['icon'],
                              color: med['iconColor'],
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  med['name'],
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${med['type']} • ${med['form']}",
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
                            color: AppColors.textGrey.withOpacity(0.5),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
