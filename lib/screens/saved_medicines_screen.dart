import 'dart:async';

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
import '../providers/notifications_provider.dart';
import '../providers/user_provider.dart';
import '../providers/language_provider.dart';
import '../services/user_medications_service.dart';
import '../utils/quantity_helpers.dart';
import '../widgets/medication_feature_sheets.dart';

class SavedMedicinesScreen extends StatefulWidget {
  final VoidCallback? onOpenAddMeds;
  final VoidCallback? onMedicationChanged;

  const SavedMedicinesScreen({
    super.key,
    this.onOpenAddMeds,
    this.onMedicationChanged,
  });

  @override
  State<SavedMedicinesScreen> createState() => _SavedMedicinesScreenState();
}

class _SavedMedicinesScreenState extends State<SavedMedicinesScreen> {
  Medicine? selectedMedicine;
  String? _currentLanguage;
  CabinetHealthModel? _cabinetHealth;
  bool _cabinetLoading = false;
  bool _detailsSheetOpen = false;
  final Map<String, DateTime> _asNeededLastTakenAt = {};
  final Set<String> _takeNowInFlight = {};
  Timer? _cooldownTimer;
  _MyMedsFilter _selectedFilter = _MyMedsFilter.all;

  String _formatDate(DateTime? date, {String locale = 'en'}) {
    if (date == null) return '';
    return DateFormat('MMM d, yyyy', locale).format(date);
  }

  @override
  void initState() {
    super.initState();
    // ✅ Fetch medicines from API when screen loads
    _fetchMedicinesAfterFrame();
    _cooldownTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final token = context.read<UserProvider>().token;
      if (token != null && token.isNotEmpty) {
        final medicineProvider = context.read<MedicineProvider>();
        await medicineProvider.fetchMedicinesFromApi(token);
        if (!mounted) return;
        await Future.wait([
          _loadCabinetHealth(token),
          _loadAsNeededCooldowns(token, medicineProvider.medicines),
        ]);
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
    final medicineProvider = context.read<MedicineProvider>();
    final notificationsProvider = context.read<NotificationsProvider>();

    await medicineProvider.fetchMedicinesFromApi(token);
    await _loadAsNeededCooldowns(token, medicineProvider.medicines);
    await _loadCabinetHealth(token);
    await notificationsProvider.refreshNotifications(token);
    widget.onMedicationChanged?.call();
  }

  Future<void> _loadAsNeededCooldowns(
    String token,
    List<Medicine> medicines,
  ) async {
    final asNeededMeds = medicines.where(
      (med) => med.isAsNeeded && med.minimumHoursBetweenDoses != null,
    );

    final latestById = <String, DateTime>{};
    await Future.wait(
      asNeededMeds.map((med) async {
        final id = _userMedicationId(med);
        if (id == null) return;
        try {
          final history = await UserMedicationsService.getIntakeHistory(
            token,
            id,
          );
          DateTime? latest;
          for (final log in history) {
            final takenAt = log.takenAt;
            if (takenAt == null) continue;
            if (latest == null || takenAt.isAfter(latest)) {
              latest = takenAt;
            }
          }
          if (latest != null) latestById[med.id] = latest;
        } catch (_) {
          // Keep the card usable if one history request fails.
        }
      }),
    );

    if (!mounted) return;
    setState(() {
      _asNeededLastTakenAt
        ..removeWhere((id, _) => medicines.every((med) => med.id != id))
        ..addAll(latestById);
    });
  }

  Future<void> _handleTakeNow(Medicine med) async {
    final token = context.read<UserProvider>().token;
    final id = _userMedicationId(med);
    if (token == null || token.isEmpty || id == null) return;
    final result = await showTakeNowReasonBottomSheet(context);
    if (result == null) return;
    setState(() => _takeNowInFlight.add(med.id));
    try {
      final intake = await UserMedicationsService.takeNow(
        token,
        id,
        reason: result.reason,
        notes: result.note,
      );
      if (mounted) {
        setState(() {
          _asNeededLastTakenAt[med.id] = intake?.takenAt ?? DateTime.now();
        });
      }
      await _reloadMedicationData();
      if (!mounted) return;
      if (_detailsSheetOpen && Navigator.canPop(context)) {
        Navigator.of(context).pop();
        await Future<void>.delayed(const Duration(milliseconds: 120));
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.t('doseRecordedSuccessfully'))),
      );
    } catch (e) {
      if (!mounted) return;
      if (_detailsSheetOpen && Navigator.canPop(context)) {
        Navigator.of(context).pop();
        await Future<void>.delayed(const Duration(milliseconds: 120));
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_localizedTakeNowError(e))));
    } finally {
      if (mounted) {
        setState(() => _takeNowInFlight.remove(med.id));
      }
    }
  }

  String _localizedTakeNowError(Object error) {
    if (error is ApiException) {
      final details = '${error.message} ${error.responseBody}'.toLowerCase();
      if (details.contains('minimum time') ||
          details.contains('minimumhoursbetweendoses')) {
        return context.l10n.t('waitBeforeAnotherDose');
      }
      if (details.contains('maximum doses') ||
          details.contains('maxdosesperday')) {
        return context.l10n.t('maximumDailyDosesReached');
      }
      return error.message;
    }
    return context.l10n.t('connectionErrorTryAgain');
  }

  Future<void> _editMedicine(Medicine med) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddReminderScreen(initialMedicine: med),
      ),
    );
    if (!mounted) return;
    await _reloadMedicationData();
  }

  Future<void> _deleteMedicine(Medicine med) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.t('deleteMedicine')),
        content: Text(
          context.l10n.t('deleteMedicineConfirm', {'name': med.name}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              context.l10n.t('cancel'),
              style: TextStyle(color: AppColors.textGrey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              context.l10n.t('delete'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    final token = context.read<UserProvider>().token;
    if (token == null || token.isEmpty) return;

    final success = await context
        .read<MedicineProvider>()
        .deleteMedicineFromApi(token, med.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? context.l10n.t('medicineDeleted', {'name': med.name})
              : context.l10n.t('failedToDeleteMedicine', {'name': med.name}),
        ),
        backgroundColor: success ? AppColors.primaryTeal : Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
    if (success) {
      await _reloadMedicationData();
    }
  }

  Future<void> _toggleReminders(Medicine med) async {
    final token = context.read<UserProvider>().token;
    if (token == null || token.isEmpty) return;

    final medicineProvider = context.read<MedicineProvider>();
    final notificationsProvider = context.read<NotificationsProvider>();
    final updated = med.copyWith(notificationActive: !med.notificationActive);
    final messenger = ScaffoldMessenger.of(context);

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          updated.notificationActive
              ? context.l10n.t('remindersEnabled')
              : context.l10n.t('remindersDisabled'),
        ),
        backgroundColor: AppColors.primaryTeal,
        duration: const Duration(seconds: 2),
      ),
    );

    medicineProvider.updateMedicine(updated);

    if (!updated.notificationActive) {
      final id = _userMedicationId(updated);
      if (id != null) {
        await notificationsProvider.cancelBackendNotificationsForUserMedication(
          id,
        );
      }
      await notificationsProvider.toggleLocalReminder(updated.id, false);
    }

    final success = await medicineProvider.updateMedicineOnApi(token, updated);
    if (!success) {
      medicineProvider.updateMedicine(med);
      if (!mounted) return;
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(context.l10n.t('couldNotUpdateReminders')),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      if (updated.notificationActive) {
        await notificationsProvider.toggleLocalReminder(updated.id, true);
      }
      await _reloadMedicationData();
    }
  }

  List<Medicine> _filteredMedicines(List<Medicine> medicines) {
    return medicines.where((med) {
      return switch (_selectedFilter) {
        _MyMedsFilter.all => true,
        _MyMedsFilter.scheduled => !med.isAsNeeded,
        _MyMedsFilter.asNeeded => med.isAsNeeded,
        _MyMedsFilter.reminderOff => !med.notificationActive && !med.isAsNeeded,
        _MyMedsFilter.needsAttention => _needsAttention(med),
        _MyMedsFilter.lowStock => med.refillWarning,
        _MyMedsFilter.expired => _isExpired(med),
      };
    }).toList();
  }

  bool _needsAttention(Medicine med) {
    return med.refillWarning ||
        med.interactions.isNotEmpty ||
        _isExpired(med) ||
        _expiresSoon(med);
  }

  bool _isExpired(Medicine med) {
    final today = DateTime.now();
    final expiry = med.actualExpiryDate;
    return DateUtils.dateOnly(expiry).isBefore(DateUtils.dateOnly(today));
  }

  bool _expiresSoon(Medicine med) {
    final today = DateUtils.dateOnly(DateTime.now());
    final expiry = DateUtils.dateOnly(med.actualExpiryDate);
    return !expiry.isBefore(today) && expiry.difference(today).inDays <= 30;
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

          final filteredMedicines = _filteredMedicines(savedMedicines);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildMyPharmacyCard(savedMedicines),
              _buildFilterChips(),
              const SizedBox(height: 14),
              if (savedMedicines.isEmpty)
                _buildEmptyMedicinesState()
              else if (filteredMedicines.isEmpty)
                _buildNoFilterResultsState()
              else
                ...filteredMedicines.map(_buildMedicineCard),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _MyMedsFilter.values.map((filter) {
          final selected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: FilterChip(
              selected: selected,
              showCheckmark: false,
              label: Text(_filterLabel(filter)),
              onSelected: (_) => setState(() => _selectedFilter = filter),
              selectedColor: AppColors.primaryTeal.withValues(alpha: 0.14),
              backgroundColor: Colors.white,
              side: BorderSide(
                color: selected
                    ? AppColors.primaryTeal
                    : Colors.black.withValues(alpha: 0.06),
              ),
              labelStyle: TextStyle(
                color: selected ? AppColors.primaryTeal : AppColors.textGrey,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _filterLabel(_MyMedsFilter filter) {
    return switch (filter) {
      _MyMedsFilter.reminderOff => context.l10n.t('reminderOff'),
      _MyMedsFilter.all => context.l10n.t('all'),
      _MyMedsFilter.scheduled => context.l10n.t('scheduled'),
      _MyMedsFilter.asNeeded => context.l10n.t('asNeeded'),
      _MyMedsFilter.needsAttention => context.l10n.t('needsAttention'),
      _MyMedsFilter.lowStock => context.l10n.t('lowStock'),
      _MyMedsFilter.expired => context.l10n.t('expired'),
    };
  }

  Widget _buildEmptyMedicinesState() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(
            Icons.medication_outlined,
            size: 58,
            color: AppColors.textGrey.withValues(alpha: 0.34),
          ),
          const SizedBox(height: 14),
          Text(
            context.l10n.t('noMedicinesAdded'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: AppColors.textGrey),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: widget.onOpenAddMeds,
            icon: const Icon(Icons.add_rounded),
            label: Text(context.l10n.t('addMedicine')),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoFilterResultsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        context.l10n.t('noMedicinesMatchFilter'),
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.textGrey),
      ),
    );
  }

  Widget _buildMedicineCard(Medicine med) {
    final warnings = _cardWarningLabels(med);
    final nextAllowedAt = _nextAllowedAt(med);
    final isCoolingDown =
        nextAllowedAt != null && DateTime.now().isBefore(nextAllowedAt);
    final isTakingNow = _takeNowInFlight.contains(med.id);
    return InkWell(
      onTap: () => _showMedicineDetailsSheet(med),
      borderRadius: BorderRadius.circular(18),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMedicineAvatar(med),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        med.name.isNotEmpty ? med.name : med.doseAmount,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _buildBadge(
                            med.isAsNeeded
                                ? context.l10n.t('asNeeded')
                                : context.l10n.t('scheduled'),
                            AppColors.primaryTeal,
                          ),
                          if (!med.notificationActive && !med.isAsNeeded)
                            _buildBadge(
                              context.l10n.t('reminderOff'),
                              Colors.orange,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildMedicationMenu(med),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              med.isAsNeeded
                  ? _buildAsNeededSummary(med)
                  : _compactScheduleSummary(med),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textGrey,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _quantitySummary(med),
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (isCoolingDown) ...[
              const SizedBox(height: 6),
              Text(
                context.l10n.t('nextAllowedAfter', {
                  'time': _formatTime(nextAllowedAt),
                }),
                style: TextStyle(
                  color: AppColors.primaryTeal,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            if (warnings.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: warnings
                    .map((warning) => _buildWarningPill(warning))
                    .toList(),
              ),
            ],
            if (med.isAsNeeded) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isCoolingDown || isTakingNow
                      ? null
                      : () => _handleTakeNow(med),
                  icon: Icon(
                    isCoolingDown
                        ? Icons.check_circle_outline_rounded
                        : Icons.flash_on_rounded,
                    size: 18,
                  ),
                  label: Text(
                    isCoolingDown
                        ? context.l10n.t('takenRecently')
                        : context.l10n.t('takeNow'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCoolingDown
                        ? AppColors.textGrey.withValues(alpha: 0.18)
                        : AppColors.primaryTeal,
                    disabledBackgroundColor: AppColors.textGrey.withValues(
                      alpha: 0.18,
                    ),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: AppColors.textGrey,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMedicineAvatar(Medicine med) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primaryTeal.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: med.imageUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                med.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.medication,
                  color: AppColors.primaryTeal,
                  size: 25,
                ),
              ),
            )
          : Icon(Icons.medication, color: AppColors.primaryTeal, size: 25),
    );
  }

  Widget _buildMedicationMenu(Medicine med) {
    return PopupMenuButton<String>(
      tooltip: context.l10n.t('actions'),
      icon: Icon(Icons.more_vert_rounded, color: AppColors.textGrey),
      onSelected: (value) {
        if (value == 'edit') _editMedicine(med);
        if (value == 'toggleReminders') _toggleReminders(med);
        if (value == 'delete') _deleteMedicine(med);
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: 'edit', child: Text(context.l10n.t('edit'))),
        if (!med.isAsNeeded)
          PopupMenuItem(
            value: 'toggleReminders',
            child: Text(
              med.notificationActive
                  ? context.l10n.t('disableReminder')
                  : context.l10n.t('enableReminder'),
            ),
          ),
        PopupMenuItem(
          value: 'delete',
          child: Text(
            context.l10n.t('delete'),
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }

  Widget _buildWarningPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 14,
            color: Colors.orange,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.orange,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  List<String> _cardWarningLabels(Medicine med) {
    final warnings = <String>[];
    if (_isExpired(med)) {
      warnings.add(context.l10n.t('expired'));
    } else if (_expiresSoon(med)) {
      warnings.add(context.l10n.t('expiringSoon'));
    }
    if (med.refillWarning) {
      if (med.daysUntilEmpty != null && med.daysUntilEmpty! >= 0) {
        warnings.add(
          context.l10n.t('runsOutInDays', {'count': med.daysUntilEmpty}),
        );
      } else {
        warnings.add(context.l10n.t('runningOutSoon'));
      }
    }
    if (med.interactions.isNotEmpty) {
      warnings.add(
        context.l10n.t('interactionCountSummary', {
          'count': med.interactions.length,
        }),
      );
    }
    return warnings;
  }

  String _quantitySummary(Medicine med) {
    final quantity = med.currentQuantity ?? med.currentPillCount;
    if (quantity == null) return context.l10n.t('stockNotSet');
    return remainingQuantityLabel(
      quantity,
      med.quantityUnit,
      locale: _currentLanguage ?? 'en',
    );
  }

  DateTime? _nextAllowedAt(Medicine med) {
    final spacing = med.minimumHoursBetweenDoses;
    final lastTakenAt = _asNeededLastTakenAt[med.id];
    if (!med.isAsNeeded ||
        spacing == null ||
        spacing <= 0 ||
        lastTakenAt == null) {
      return null;
    }
    return lastTakenAt.add(Duration(minutes: (spacing * 60).round()));
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat(
      'h:mm a',
      _currentLanguage ?? 'en',
    ).format(dateTime.toLocal());
  }

  String _compactScheduleSummary(Medicine med) {
    final summary = buildScheduleSummary(med, locale: _currentLanguage ?? 'en');
    return summary
        .replaceAll('Every ', 'Every ')
        .replaceAll(' hours', 'h')
        .replaceAll(' hour', 'h')
        .replaceAll(' - ', ' • ');
  }

  Widget _buildMyPharmacyCard(List<Medicine> medicines) {
    final attention = _cabinetHealth?.attentionCount ?? 0;
    final expired = _cabinetHealth?.expired.length ?? 0;
    final runningOut = _cabinetHealth?.runningOutSoon.length ?? 0;
    final lowStock =
        (_cabinetHealth?.lowStock.length ?? 0) +
        (_cabinetHealth?.outOfStock.length ?? 0);
    final interactions = medicines.fold<int>(
      0,
      (sum, med) => sum + med.interactions.length,
    );
    final summary = _cabinetLoading
        ? context.l10n.t('checkingCabinetHealth')
        : attention == 0 && interactions == 0
        ? context.l10n.t('noCabinetWarnings')
        : [
            if (attention > 0)
              context.l10n.t('needAttentionCount', {'count': attention}),
            if (expired > 0) context.l10n.t('expiredCount', {'count': expired}),
            if (lowStock > 0)
              context.l10n.t('lowStockCount', {'count': lowStock}),
            if (runningOut > 0)
              context.l10n.t('runningOutCount', {'count': runningOut}),
            if (interactions > 0)
              context.l10n.t('interactionCountSummary', {
                'count': interactions,
              }),
          ].join(' • ');
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
                    context.l10n.t('myPharmacy'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    summary,
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
      parts.add(
        context.l10n.t('maxDosesPerDayCompact', {'count': med.maxDosesPerDay}),
      );
    }
    if (med.minimumHoursBetweenDoses != null) {
      parts.add(
        context.l10n.t('everyHoursCompact', {
          'hours': med.minimumHoursBetweenDoses!.toStringAsFixed(0),
        }),
      );
    }
    return parts.isEmpty
        ? context.l10n.t('takeOnlyWhenNeeded')
        : parts.join(' • ');
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

  Widget _buildExpandableDetailSection({
    required String title,
    required List<Widget> children,
    bool initiallyExpanded = false,
    String? subtitle,
    Color? accentColor,
  }) {
    final color = accentColor ?? AppColors.primaryTeal;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          iconColor: color,
          collapsedIconColor: color,
          title: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          subtitle: subtitle == null
              ? null
              : Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: AppColors.textGrey),
                ),
          children: children,
        ),
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
            context.l10n.t('couldNotLoadIntakeHistory'),
            style: TextStyle(fontSize: 12, color: AppColors.textGrey),
          );
        } else {
          final logs = snapshot.data ?? const <MedicationIntakeLogModel>[];
          if (logs.isEmpty) {
            child = Text(
              context.l10n.t('noIntakeHistory'),
              style: TextStyle(fontSize: 12, color: AppColors.textGrey),
            );
          } else {
            child = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...logs.take(3).map((log) {
                  final date = log.takenAt == null
                      ? ''
                      : DateFormat(
                          'MMM d, h:mm a',
                          _currentLanguage ?? 'en',
                        ).format(log.takenAt!);
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
                          date.isEmpty ? context.l10n.t('doseRecorded') : date,
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
                }),
                if (logs.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      context.l10n.t('showingLatestRecords', {
                        'shown': 3,
                        'total': logs.length,
                      }),
                      style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                    ),
                  ),
              ],
            );
          }
        }
        return child;
      },
    );
  }

  Future<void> _showMedicineDetailsSheet(Medicine med) async {
    final locale = _currentLanguage ?? 'en';
    final warningCount = _cardWarningLabels(med).length;
    _detailsSheetOpen = true;
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMedicineAvatar(med),
                      const SizedBox(width: 12),
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
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                _buildBadge(
                                  med.isAsNeeded
                                      ? context.l10n.t('asNeeded')
                                      : context.l10n.t('scheduled'),
                                  AppColors.primaryTeal,
                                ),
                                _buildBadge(
                                  _quantitySummary(med),
                                  AppColors.textGrey,
                                ),
                              ],
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
                        _buildExpandableDetailSection(
                          title: context.l10n.t('overview'),
                          subtitle: med.isAsNeeded
                              ? _buildAsNeededSummary(med)
                              : _compactScheduleSummary(med),
                          initiallyExpanded: true,
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
                              valueColor: _isExpired(med)
                                  ? Colors.red
                                  : _expiresSoon(med)
                                  ? Colors.orange
                                  : AppColors.textDark,
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
                          ],
                        ),
                        if (med.isAsNeeded)
                          _buildExpandableDetailSection(
                            title: context.l10n.t('asNeededSettings'),
                            subtitle: _buildAsNeededSummary(med),
                            children: [
                              if (med.maxDosesPerDay != null)
                                _buildDetailRow(
                                  context,
                                  context.l10n.t('maxDosesPerDay'),
                                  '${med.maxDosesPerDay}',
                                ),
                              if (med.minimumHoursBetweenDoses != null)
                                _buildDetailRow(
                                  context,
                                  context.l10n.t('minimumSpacing'),
                                  context.l10n.t('hoursCount', {
                                    'count': med.minimumHoursBetweenDoses!
                                        .toStringAsFixed(0),
                                  }),
                                ),
                            ],
                          ),
                        if (med.isAsNeeded)
                          _buildExpandableDetailSection(
                            title: context.l10n.t('intakeHistory'),
                            subtitle: context.l10n.t('latestRecords'),
                            children: [
                              _buildIntakeHistorySection(context, med),
                            ],
                          ),
                        _buildExpandableDetailSection(
                          title: context.l10n.t('warningsAndInteractions'),
                          subtitle: warningCount == 0
                              ? context.l10n.t('noInteractionWarnings')
                              : context.l10n.t('warningsFound', {
                                  'count': warningCount,
                                }),
                          accentColor: warningCount == 0
                              ? AppColors.primaryTeal
                              : Colors.orange,
                          children: [
                            _buildInteractionsDetailSection(context, med),
                            if (med.note.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                med.note,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textGrey,
                                  height: 1.5,
                                ),
                              ),
                            ],
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
    _detailsSheetOpen = false;
  }
}

enum _MyMedsFilter {
  all,
  scheduled,
  asNeeded,
  reminderOff,
  needsAttention,
  lowStock,
  expired,
}
