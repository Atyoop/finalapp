import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../providers/saved_medicines_provider.dart';
import 'drug_detail_screen.dart';

class SavedMedicinesScreen extends StatelessWidget {
  const SavedMedicinesScreen({super.key});

  const SavedMedicinesScreen({super.key});

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
      body: Consumer<SavedMedicinesProvider>(
        builder: (context, provider, child) {
          final savedMedicines = provider.savedMedicines;
          return savedMedicines.isEmpty
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
                  itemCount: savedMedicines.length,
                  itemBuilder: (context, index) {
                    final med = savedMedicines[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
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
                        );
                      },
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
                  ),
                );
              },
            );
        },
      ),
    );
  }
}
