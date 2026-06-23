import 'package:final88/models/medicine.dart';
import 'package:final88/models/medication_features.dart';
import 'package:final88/screens/cabinet_health_screen.dart';
import 'package:final88/screens/add_reminder_screen.dart';
import 'package:final88/utils/time_helpers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import '../providers/medicine_provider.dart';
import '../providers/user_provider.dart';
import '../providers/language_provider.dart';
import '../services/user_medications_service.dart';
import '../utils/quantity_helpers.dart';
import '../widgets/interaction_warning_badge.dart';
import '../widgets/medication_feature_sheets.dart';

class SavedMedicinesScreen extends StatefulWidget {
  const SavedMedicinesScreen({super.key});

  @override
  State<SavedMedicinesScreen> createState() => _SavedMedicinesScreenState();
}

class _SavedMedicinesScreenState extends State<SavedMedicinesScreen> {
  Medicine? selectedMedicine;
  String? _currentLanguage;
  CabinetHealthModel? _cabinetHealth;
  bool _cabinetLoading = false;

  String _formatDate(DateTime? date, {String locale = 'en'}) {
    if (date == null) return '';
    return DateFormat('MMM d, yyyy', locale).format(date);
  }

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
        _loadCabinetHealth(token);
      }
    });
  }

  Future<void> _loadCabinetHealth(String token) async {
    setState(() => _cabinetLoading = true);
    try {
      final health = await UserMedicationsService.getCabinetHealth(token);
      if (!mounted) return;
      setState(() => _cabinetHealth = health);
    } catch (_) {
      if (!mounted) return;
      setState(() => _cabinetHealth = null);
    } finally {
      if (mounted) setState(() => _cabinetLoading = false);
    }
  }

  int? _userMedicationId(Medicine med) => int.tryParse(med.id);

  Future<void> _reloadMedicationData() async {
    final token = context.read<UserProvider>().token;
    if (token == null || token.isEmpty) return;
    await context.read<MedicineProvider>().fetchMedicinesFromApi(token);
    await _loadCabinetHealth(token);
  }

  Future<void> _handleTakeNow(Medicine med) async {
    final token = context.read<UserProvider>().token;
    final id = _userMedicationId(med);
    if (token == null || token.isEmpty || id == null) return;
    final result = await showTakeNowReasonBottomSheet(context);
    if (result == null) return;
    try {
      await UserMedicationsService.takeNow(
        token,
        id,
        reason: result.reason,
        notes: result.note,
      );
      await _reloadMedicationData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dose recorded successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is ApiException ? e.message : e.toString())),
      );
    }
  }

  Future<void> _handleRefill(Medicine med) async {
    final token = context.read<UserProvider>().token;
    final id = _userMedicationId(med);
    if (token == null || token.isEmpty || id == null) return;
    final quantity = await showRefillBottomSheet(context);
    if (quantity == null) return;
    try {
      await UserMedicationsService.refillMedication(token, id, quantity);
      await _reloadMedicationData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Refill added successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is ApiException ? e.message : e.toString())),
      );
    }
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
              ? ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildMyPharmacyCard(),
                    const SizedBox(height: 40),
                    Icon(
                      Icons.bookmark_border_rounded,
                      size: 64,
                      color: AppColors.textGrey.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        context.l10n.t('noMedicinesAdded'),
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: savedMedicines.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) return _buildMyPharmacyCard();
                    final med = savedMedicines[index - 1];
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
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                  if (med.isAsNeeded) ...[
                                    const SizedBox(height: 6),
                                    _buildBadge(
                                      'As needed',
                                      AppColors.primaryTeal,
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Text(
                                    med.isAsNeeded
                                        ? _buildAsNeededSummary(med)
                                        : buildScheduleSummary(
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
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      '${context.l10n.t('actualExpiry')}: ${_formatDate(med.actualExpiryDate, locale: _currentLanguage ?? 'en')}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textGrey,
                                      ),
                                    ),
                                  ),
                                  if (_forecastText(med).isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        _forecastText(med),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: med.refillWarning
                                              ? Colors.orange
                                              : AppColors.textGrey,
                                          fontWeight: med.refillWarning
                                              ? FontWeight.w700
                                              : FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      if (med.isAsNeeded)
                                        TextButton.icon(
                                          onPressed: () => _handleTakeNow(med),
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                            visualDensity:
                                                VisualDensity.compact,
                                            foregroundColor:
                                                AppColors.primaryTeal,
                                          ),
                                          icon: const Icon(
                                            Icons.flash_on_rounded,
                                            size: 16,
                                          ),
                                          label: const Text(
                                            'Take Now',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      TextButton.icon(
                                        onPressed: () =>
                                            _showMedicineDetailsSheet(med),
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          visualDensity: VisualDensity.compact,
                                          foregroundColor:
                                              AppColors.primaryTeal,
                                        ),
                                        icon: const Icon(
                                          Icons.info_outline_rounded,
                                          size: 16,
                                        ),
                                        label: Text(
                                          context.l10n.t('moreInfo'),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (med.interactions.isNotEmpty)
                                  InteractionWarningBadge(
                                    interactionCount: med.interactions.length,
                                    onTap: () => _showMedicineDetailsSheet(med),
                                  ),
                                const SizedBox(height: 6),
                                IconButton(
                                  onPressed: () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: Text(
                                          context.l10n.t('deleteMedicine'),
                                        ),
                                        content: Text(
                                          context.l10n.t(
                                            'deleteMedicineConfirm',
                                            {'name': med.name},
                                          ),
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
                                            .deleteMedicineFromApi(
                                              token,
                                              med.id,
                                            );
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
                                              duration: const Duration(
                                                seconds: 2,
                                              ),
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

  Widget _buildMyPharmacyCard() {
    final attention = _cabinetHealth?.attentionCount ?? 0;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CabinetHealthScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
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
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primaryTeal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.health_and_safety_rounded,
                color: AppColors.primaryTeal,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Pharmacy',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _cabinetLoading
                        ? 'Checking cabinet health...'
                        : attention == 0
                        ? 'No cabinet warnings right now'
                        : '$attention medication(s) need attention',
                    style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.textGrey),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _buildAsNeededSummary(Medicine med) {
    final parts = <String>[];
    if (med.maxDosesPerDay != null) {
      parts.add('max ${med.maxDosesPerDay}/day');
    }
    if (med.minimumHoursBetweenDoses != null) {
      parts.add('every ${med.minimumHoursBetweenDoses!.toStringAsFixed(0)}h');
    }
    return parts.isEmpty ? 'Take only when needed' : parts.join(' - ');
  }

  String _forecastText(Medicine med) {
    final parts = <String>[];
    if (med.dosesRemaining != null) {
      parts.add('${med.dosesRemaining!.toStringAsFixed(0)} doses left');
    }
    if (med.daysUntilEmpty != null) {
      parts.add('runs out in ${med.daysUntilEmpty} days');
    }
    if (med.refillWarning) {
      parts.add('refill soon');
    }
    return parts.join(' - ');
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textGrey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12,
                color: valueColor ?? AppColors.textDark,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInteractionsDetailSection(BuildContext context, Medicine med) {
    if (med.isCustomMedication || med.supportsInteractions == false) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.18)),
        ),
        child: Text(
          med.customMedicationWarning ??
              context.l10n.t('databaseFeatureUnavailableManual'),
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textDark,
            height: 1.45,
          ),
        ),
      );
    }

    if (med.interactions.isEmpty) {
      return Text(
        context.l10n.t('noKnownInteractions'),
        style: TextStyle(fontSize: 12, color: AppColors.textGrey),
      );
    }

    return Column(
      children: med.interactions.map((inter) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      inter.withMedication,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                context.l10n.t('reason', {'reason': inter.reason}),
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textGrey,
                  height: 1.35,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildIntakeHistorySection(BuildContext context, Medicine med) {
    final token = context.read<UserProvider>().token;
    final id = _userMedicationId(med);
    if (token == null || token.isEmpty || id == null) {
      return const SizedBox.shrink();
    }
    return FutureBuilder<List<MedicationIntakeLogModel>>(
      future: UserMedicationsService.getIntakeHistory(token, id),
      builder: (context, snapshot) {
        Widget child;
        if (snapshot.connectionState == ConnectionState.waiting) {
          child = Center(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: CircularProgressIndicator(color: AppColors.primaryTeal),
            ),
          );
        } else if (snapshot.hasError) {
          child = Text(
            'Could not load intake history.',
            style: TextStyle(fontSize: 12, color: AppColors.textGrey),
          );
        } else {
          final logs = snapshot.data ?? const <MedicationIntakeLogModel>[];
          if (logs.isEmpty) {
            child = Text(
              'No intake history yet.',
              style: TextStyle(fontSize: 12, color: AppColors.textGrey),
            );
          } else {
            child = Column(
              children: logs.take(10).map((log) {
                final date = log.takenAt == null
                    ? ''
                    : DateFormat('MMM d, h:mm a').format(log.takenAt!);
                final detail = [
                  if ((log.reason ?? '').isNotEmpty) log.reason,
                  if ((log.notes ?? '').isNotEmpty) log.notes,
                ].join(' - ');
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FAFA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        date.isEmpty ? 'Dose recorded' : date,
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      if (detail.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          detail,
                          style: TextStyle(
                            color: AppColors.textGrey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            );
          }
        }
        return _buildDetailSection(title: 'Intake history', children: [child]);
      },
    );
  }

  Future<void> _showMedicineDetailsSheet(Medicine med) async {
    final locale = _currentLanguage ?? 'en';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFFDFBF7),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 12, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              med.name.isNotEmpty ? med.name : med.doseAmount,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              buildScheduleSummary(med, locale: locale),
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailSection(
                          title: context.l10n.t('medicationDetails'),
                          children: [
                            if (med.dosageForm != null)
                              _buildDetailRow(
                                context,
                                context.l10n.t('dosageFormLabel'),
                                getMedicationTypeLabel(
                                  med.dosageForm,
                                  locale: locale,
                                ),
                              ),
                            if (med.initialQuantity != null)
                              _buildDetailRow(
                                context,
                                context.l10n.t('initial'),
                                formatQuantityWithUnit(
                                  med.initialQuantity,
                                  med.quantityUnit,
                                  locale: locale,
                                ),
                              ),
                            if (med.doseQuantity != null)
                              _buildDetailRow(
                                context,
                                context.l10n.t('dose'),
                                formatQuantityWithUnit(
                                  med.doseQuantity,
                                  med.quantityUnit,
                                  locale: locale,
                                ),
                              ),
                            _buildDetailRow(
                              context,
                              context.l10n.t('packageExpiry'),
                              _formatDate(med.expiryDate, locale: locale),
                            ),
                            _buildDetailRow(
                              context,
                              context.l10n.t('actualExpiry'),
                              _formatDate(med.actualExpiryDate, locale: locale),
                            ),
                            if (med.afterOpeningExpiryDate != null)
                              _buildDetailRow(
                                context,
                                context.l10n.t('expiryAfterOpening'),
                                _formatDate(
                                  med.afterOpeningExpiryDate,
                                  locale: locale,
                                ),
                              ),
                            _buildDetailRow(
                              context,
                              context.l10n.t('openingTracking'),
                              med.isOpened
                                  ? context.l10n.t('openedMedication')
                                  : context.l10n.t('notOpened'),
                            ),
                            if (med.isOpened && med.openedDate != null)
                              _buildDetailRow(
                                context,
                                context.l10n.t('openedDateLabel'),
                                _formatDate(med.openedDate, locale: locale),
                              ),
                            if (med.lowStockThreshold != null)
                              _buildDetailRow(
                                context,
                                context.l10n.t('lowStockThreshold'),
                                formatQuantityWithUnit(
                                  med.lowStockThreshold,
                                  med.quantityUnit,
                                  locale: locale,
                                ),
                              ),
                          ],
                        ),
                        _buildDetailSection(
                          title: 'Stock info',
                          children: [
                            _buildDetailRow(
                              context,
                              'Current quantity',
                              formatQuantityWithUnit(
                                med.currentQuantity ?? med.currentPillCount,
                                med.quantityUnit,
                                locale: locale,
                              ),
                            ),
                            if (med.dosesRemaining != null)
                              _buildDetailRow(
                                context,
                                'Doses remaining',
                                med.dosesRemaining!.toStringAsFixed(0),
                                valueColor: med.refillWarning
                                    ? Colors.orange
                                    : AppColors.textDark,
                              ),
                            if (med.daysUntilEmpty != null)
                              _buildDetailRow(
                                context,
                                'Days until empty',
                                '${med.daysUntilEmpty}',
                                valueColor: med.refillWarning
                                    ? Colors.orange
                                    : AppColors.textDark,
                              ),
                            if (med.estimatedRunOutDate != null)
                              _buildDetailRow(
                                context,
                                'Estimated run out',
                                _formatDate(
                                  med.estimatedRunOutDate,
                                  locale: locale,
                                ),
                              ),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _handleRefill(med),
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Add Refill'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryTeal,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (med.isAsNeeded)
                          _buildDetailSection(
                            title: 'As needed',
                            children: [
                              if (med.maxDosesPerDay != null)
                                _buildDetailRow(
                                  context,
                                  'Max doses per day',
                                  '${med.maxDosesPerDay}',
                                ),
                              if (med.minimumHoursBetweenDoses != null)
                                _buildDetailRow(
                                  context,
                                  'Minimum spacing',
                                  '${med.minimumHoursBetweenDoses!.toStringAsFixed(0)} hours',
                                ),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => _handleTakeNow(med),
                                  icon: const Icon(Icons.flash_on_rounded),
                                  label: const Text('Take Now'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primaryTeal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        if (med.isAsNeeded)
                          _buildIntakeHistorySection(context, med),
                        _buildDetailSection(
                          title: context.l10n.t('fullInteractionDetails'),
                          children: [
                            _buildInteractionsDetailSection(context, med),
                          ],
                        ),
                        if (med.note.isNotEmpty)
                          _buildDetailSection(
                            title: context.l10n.t('notes'),
                            children: [
                              Text(
                                med.note,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textGrey,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
