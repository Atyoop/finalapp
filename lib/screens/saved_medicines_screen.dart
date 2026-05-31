import 'package:final88/models/medicine.dart';
import 'package:final88/screens/add_reminder_screen.dart';
import 'package:final88/utils/time_helpers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import '../providers/medicine_provider.dart';
import '../providers/user_provider.dart';
import '../providers/language_provider.dart';
import '../utils/quantity_helpers.dart';

class SavedMedicinesScreen extends StatefulWidget {
  const SavedMedicinesScreen({super.key});

  @override
  State<SavedMedicinesScreen> createState() => _SavedMedicinesScreenState();
}

class _SavedMedicinesScreenState extends State<SavedMedicinesScreen> {
  Medicine? selectedMedicine;
  String? _currentLanguage;

  @override
  void initState() {
    super.initState();
    // ✅ Fetch medicines from API when screen loads
    _fetchMedicinesAfterFrame();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newLang = Provider.of<LanguageProvider>(context).currentLanguage;
    if (_currentLanguage != null && _currentLanguage != newLang) {
      _currentLanguage = newLang;
      _fetchMedicinesAfterFrame();
    } else {
      _currentLanguage = newLang;
    }
  }

  void _fetchMedicinesAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
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
          context.l10n.t('myMeds'),
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<MedicineProvider>(
        builder: (context, provider, child) {
          final savedMedicines = provider.medicines;

          // ✅ Show loading spinner while fetching (but keep showing local data if available)
          if (provider.isLoading) {
            if (savedMedicines.isEmpty) {
              return Center(
                child: CircularProgressIndicator(color: AppColors.primaryTeal),
              );
            }
          }

          // ✅ Show error if fetch failed AND no local data
          if (provider.error != null && savedMedicines.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 12),
                  Text(
                    context.l10n.t('failedToLoadMedicines'),
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
                    child: Text(
                      context.l10n.t('retry'),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          }

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
                        context.l10n.t('noMedicinesAdded'),
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
                                  // Schedule summary
                                  Text(
                                    buildScheduleSummary(
                                      med,
                                      locale: _currentLanguage ?? 'en',
                                    ),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textGrey,
                                      height: 1.3,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  // Remaining quantity
                                  Text(
                                    (med.currentQuantity ??
                                                med.currentPillCount) !=
                                            null
                                        ? remainingQuantityLabel(
                                            med.currentQuantity ??
                                                med.currentPillCount,
                                            med.quantityUnit,
                                            locale: _currentLanguage ?? 'en',
                                          )
                                        : context.l10n.t('stockNotSet'),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textGrey,
                                    ),
                                  ),
                                  if (med.dosageForm != null ||
                                      med.initialQuantity != null ||
                                      med.doseQuantity != null ||
                                      med.lowStockThreshold != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        [
                                          if (med.dosageForm != null)
                                            getMedicationTypeLabel(
                                              med.dosageForm,
                                              locale: _currentLanguage ?? 'en',
                                            ),
                                          if (med.initialQuantity != null)
                                            '${_currentLanguage == 'ar' ? 'الكلية' : 'Initial'}: ${formatQuantityWithUnit(med.initialQuantity, med.quantityUnit, locale: _currentLanguage ?? 'en')}',
                                          if (med.doseQuantity != null)
                                            '${_currentLanguage == 'ar' ? 'الجرعة' : 'Dose'}: ${formatQuantityWithUnit(med.doseQuantity, med.quantityUnit, locale: _currentLanguage ?? 'en')}',
                                          if (med.lowStockThreshold != null)
                                            '${_currentLanguage == 'ar' ? 'التنبيه' : 'Low'}: ${formatQuantityWithUnit(med.lowStockThreshold, med.quantityUnit, locale: _currentLanguage ?? 'en')}',
                                        ].join(' • '),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: AppColors.textGrey,
                                        ),
                                      ),
                                    ),
                                  // Stock Warnings
                                  if ((med.currentQuantity ??
                                          med.currentPillCount) !=
                                      null)
                                    Builder(
                                      builder: (context) {
                                        final locale = _currentLanguage ?? 'en';
                                        final stock =
                                            med.currentQuantity ??
                                            med.currentPillCount!;
                                        final threshold = med.lowStockThreshold;
                                        final needed =
                                            med.doseQuantity ??
                                            med.pillsPerDose ??
                                            1;

                                        if (stock < needed) {
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              top: 2,
                                            ),
                                            child: Text(
                                              locale == 'ar'
                                                  ? 'الكمية غير كافية للجرعة التالية'
                                                  : 'Not enough ${getQuantityUnitLabel(med.quantityUnit, locale: locale)} for next dose',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.red[700],
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          );
                                        } else if (threshold != null &&
                                            stock <= threshold) {
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              top: 2,
                                            ),
                                            child: Text(
                                              'Low stock',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.orange[800],
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          );
                                        }
                                        return const SizedBox.shrink();
                                      },
                                    ),
                                  // Expiry date
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      formatExpiryDate(
                                        med.expiryDate,
                                        locale: _currentLanguage ?? 'en',
                                      ),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textGrey,
                                      ),
                                    ),
                                  ),
                                  // --- Interaction Warnings ---
                                  if (med.hasInteractions)
                                    _buildInteractionsSection(context, med),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text(
                                      context.l10n.t('deleteMedicine'),
                                    ),
                                    content: Text(
                                      context.l10n.t('deleteMedicineConfirm', {
                                        'name': med.name,
                                      }),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: Text(
                                          context.l10n.t('cancel'),
                                          style: TextStyle(
                                            color: AppColors.textGrey,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: Text(
                                          context.l10n.t('delete'),
                                          style: const TextStyle(
                                            color: Colors.red,
                                          ),
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
                                                ? context.l10n.t(
                                                    'medicineDeleted',
                                                    {'name': med.name},
                                                  )
                                                : context.l10n.t(
                                                    'failedToDeleteMedicine',
                                                    {'name': med.name},
                                                  ),
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

  Widget _buildInteractionsSection(BuildContext context, Medicine med) {
    final interactions = med.interactions;
    if (interactions.isEmpty) return const SizedBox.shrink();

    const visibleCount = 2;
    final showMore = interactions.length > visibleCount;
    final displayed = interactions.take(visibleCount).toList();

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...displayed.map(
            (inter) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      context.l10n.t('interactsWith', {
                        'name': inter.withMedication,
                      }),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[800],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (showMore)
            GestureDetector(
              onTap: () => _showAllInteractions(context, med),
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  context.l10n.t('moreInteractions', {
                    'count': interactions.length - visibleCount,
                  }),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryTeal,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showAllInteractions(BuildContext context, Medicine med) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              context.l10n.t('interactionsFor', {'name': med.name}),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.t('followingInteractions'),
              style: TextStyle(fontSize: 14, color: AppColors.textGrey),
            ),
            const SizedBox(height: 20),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: med.interactions.length,
                itemBuilder: (context, index) {
                  final inter = med.interactions[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.orange,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              inter.withMedication,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.only(left: 28),
                          child: Text(
                            context.l10n.t('reason', {'reason': inter.reason}),
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textGrey,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  context.l10n.t('close'),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
