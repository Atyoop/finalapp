import 'package:final88/models/medicine.dart';
import 'package:final88/screens/add_reminder_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../providers/medicine_provider.dart';
import '../providers/user_provider.dart';

class SavedMedicinesScreen extends StatefulWidget {
  const SavedMedicinesScreen({super.key});

  @override
  State<SavedMedicinesScreen> createState() => _SavedMedicinesScreenState();
}

class _SavedMedicinesScreenState extends State<SavedMedicinesScreen> {
  Medicine? selectedMedicine;
  @override
  void initState() {
    super.initState();
    // ✅ Fetch medicines from API when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<UserProvider>().token;
      if (token != null && token.isNotEmpty) {
        context.read<MedicineProvider>().fetchMedicinesFromApi(token);
      }
    });
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
          'My Meds',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<MedicineProvider>(
        builder: (context, provider, child) {
          // ✅ Show loading spinner while fetching
          if (provider.isLoading) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.primaryTeal),
            );
          }

          // ✅ Show error if fetch failed
          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 12),
                  Text(
                    'Failed to load medicines',
                    style: TextStyle(color: AppColors.textGrey),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      final token = context.read<UserProvider>().token;
                      if (token != null && token.isNotEmpty) {
                        context.read<MedicineProvider>().fetchMedicinesFromApi(
                          token,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                    ),
                    child: const Text(
                      'Retry',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          }

          final savedMedicines = provider.medicines;

          return savedMedicines.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bookmark_border_rounded,
                        size: 64,
                        color: AppColors.textGrey.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No medicines added yet',
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
                            builder: (_) =>
                                AddReminderScreen(initialMedicine: med),
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
                              color: Colors.black.withValues(alpha: 0.03),
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
                                color: AppColors.primaryTeal.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              // ✅ Show medicine image from API if available
                              child: med.imageUrl.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Image.network(
                                        med.imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Icon(
                                          Icons.medication,
                                          color: AppColors.primaryTeal,
                                          size: 26,
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      Icons.medication,
                                      color: AppColors.primaryTeal,
                                      size: 26,
                                    ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ✅ med.name now correctly populated from API
                                  Text(
                                    med.name.isNotEmpty
                                        ? med.name
                                        : med.doseAmount,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    med.doseAmount,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete medicine'),
                                    content: Text('Delete ${med.name}?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: Text(
                                          'Cancel',
                                          style: TextStyle(
                                            color: AppColors.textGrey,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: const Text(
                                          'Delete',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed == true && context.mounted) {
                                  final token = context
                                      .read<UserProvider>()
                                      .token;
                                  if (token != null && token.isNotEmpty) {
                                    // ✅ Delete from API, not just locally
                                    final success = await context
                                        .read<MedicineProvider>()
                                        .deleteMedicineFromApi(token, med.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            success
                                                ? '${med.name} deleted.'
                                                : 'Failed to delete ${med.name}.',
                                          ),
                                          backgroundColor: success
                                              ? AppColors.primaryTeal
                                              : Colors.red,
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                              icon: const Icon(
                                Icons.delete,
                                color: Color(0xFF2C6E72),
                              ),
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
