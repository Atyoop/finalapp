import 'package:flutter/material.dart';
import '../main.dart';

class SavedMedicinesScreen extends StatelessWidget {
  const SavedMedicinesScreen({super.key});

  static final List<Map<String, dynamic>> _savedMedicines = [
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        title: const Text(
          'Saved Medicines',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _savedMedicines.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bookmark_border_rounded,
                    size: 64,
                    color: AppColors.textGrey.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No saved medicines yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _savedMedicines.length,
              itemBuilder: (context, index) {
                final med = _savedMedicines[index];
                return Container(
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
                          color: med['color'],
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          med['icon'],
                          color: med['iconColor'],
                          size: 26,
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
                              '${med['type']} • ${med['form']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.bookmark_rounded,
                        color: AppColors.primaryTeal,
                        size: 24,
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
