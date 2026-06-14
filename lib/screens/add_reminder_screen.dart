import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import '../models/medicine.dart';
import '../providers/medicine_provider.dart';
import '../providers/user_provider.dart';
import '../providers/language_provider.dart';
import '../utils/quantity_helpers.dart';
import '../utils/time_helpers.dart';
import '../widgets/interaction_warning_dialog.dart';

class AddReminderScreen extends StatefulWidget {
  final String? initialDrugName;
  final Medicine? initialMedicine;
  final String? selectedDosageForm;
  final String? selectedQuantityUnit;
  final int? selectedMedicationId;
  final bool isCustomMedication;
  final bool medicationSelectedFromCatalog;
  final int? defaultAfterOpeningValue;
  final String? defaultAfterOpeningUnit;
  final bool requiresOpeningTracking;
  final String? afterOpeningNote;

  const AddReminderScreen({
    super.key,
    this.initialDrugName,
    this.initialMedicine,
    this.selectedDosageForm,
    this.selectedQuantityUnit,
    this.selectedMedicationId,
    this.isCustomMedication = false,
    this.medicationSelectedFromCatalog = false,
    this.defaultAfterOpeningValue,
    this.defaultAfterOpeningUnit,
    this.requiresOpeningTracking = false,
    this.afterOpeningNote,
  });

  @override
  State<AddReminderScreen> createState() => _AddReminderScreenState();
}

// Schedule types for simple selection
enum ScheduleType { everyXHours, xTimesPerDay }

class _ScheduleConfig {
  ScheduleType type;
  int intervalHours; // for everyXHours mode
  List<TimeOfDay> doseTimes; // for xTimesPerDay mode
  DateTime startDate;
  DateTime? endDate;
  TimeOfDay
  firstDoseTime; // mutable: user-selected for interval, or earliest for custom

  /// Alias for backward compatibility with code referencing .value
  int get value => intervalHours;

  _ScheduleConfig({
    this.type = ScheduleType.everyXHours,
    this.intervalHours = 6,
    this.doseTimes = const [],
    required this.startDate,
    this.endDate,
    this.firstDoseTime = const TimeOfDay(hour: 8, minute: 0),
  });

  /// Get the effective first dose time for API
  TimeOfDay get effectiveFirstDoseTime {
    if (type == ScheduleType.xTimesPerDay && doseTimes.isNotEmpty) {
      final sorted = List<TimeOfDay>.from(doseTimes)
        ..sort(
          (a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute),
        );
      return sorted.first;
    }
    return firstDoseTime;
  }

  /// Convert schedule config to API fields
  Map<String, dynamic> toApiFields() {
    if (type == ScheduleType.everyXHours) {
      return {
        'scheduleType': 'Interval',
        'intervalHours': intervalHours,
        'doseTimes': <String>[],
        'dosesPerPeriod': null,
        'periodUnit': null,
        'periodValue': null,
      };
    } else {
      // Sort dose times and get earliest as first dose
      final sortedTimes = List<TimeOfDay>.from(doseTimes)
        ..sort(
          (a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute),
        );

      final doseTimeStrings = normalizeDoseTimesBeforeSave(sortedTimes);

      return {
        'scheduleType': 'CustomTimes',
        'doseTimes': doseTimeStrings,
        'firstDoseTime': doseTimeStrings.isNotEmpty
            ? doseTimeStrings.first
            : null,
        'dosesPerPeriod': doseTimeStrings.length,
        'periodUnit': 'Day',
        'periodValue': 1,
        'intervalHours': null,
      };
    }
  }

  String getDisplayText(BuildContext context) {
    if (type == ScheduleType.everyXHours) {
      final h = firstDoseTime.hour.toString().padLeft(2, '0');
      final m = firstDoseTime.minute.toString().padLeft(2, '0');
      return context.l10n.t('everyHoursStarting', {
        'hours': intervalHours,
        'time': '$h:$m',
      });
    } else {
      if (doseTimes.isEmpty) {
        return context.l10n.t('addDoseTimes');
      }
      final sortedTimes = List<TimeOfDay>.from(doseTimes)
        ..sort(
          (a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute),
        );

      final timeStrings = sortedTimes.map((t) {
        final hour = t.hour.toString().padLeft(2, '0');
        final minute = t.minute.toString().padLeft(2, '0');
        return '$hour:$minute';
      }).toList();

      return context.l10n.t('timesPerDay', {
        'count': doseTimes.length,
        'times': timeStrings.join(', '),
      });
    }
  }
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  late TextEditingController _nameController;
  late TextEditingController _dosageController;
  late TextEditingController _noteController;
  late TextEditingController _afterOpeningDurationController;

  // Schedule configuration
  late _ScheduleConfig _schedule;

  // Stock management
  int? _stock;
  int? _lowStockThreshold;
  DateTime? _expiryDate;
  bool _isOpened = false;
  DateTime? _openedDate;
  String _afterOpeningDurationUnit = 'days';
  bool _requiresOpeningTracking = false;
  String? _afterOpeningNote;

  // Pills per dose
  int _pillsPerDose = 1;
  String? _selectedDosageForm;
  String _selectedQuantityUnit = 'unit';
  int? _selectedMedicationId;
  late bool _isCustomMedication;
  late bool _medicationSelectedFromCatalog;

  // Notifications
  bool _notificationActive = true;
  int? _advanceReminderMinutes;
  bool _advanceReminderEnabled = false;
  bool _isCustomAdvanceReminder = false;
  late TextEditingController _customAdvanceReminderMinutesController;

  // UI state
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialMedicine?.name ?? widget.initialDrugName ?? "Panadol",
    );
    _dosageController = TextEditingController(
      text: widget.initialMedicine?.dosage ?? '',
    );
    _noteController = TextEditingController(
      text: widget.initialMedicine?.note ?? '',
    );

    // Initialize schedule with proper dose times loading
    final med = widget.initialMedicine;

    // Determine schedule type from the medicine
    ScheduleType scheduleType = ScheduleType.everyXHours;
    List<TimeOfDay> doseTimes = const [];

    if (med != null) {
      if (med.scheduleType == 'CustomTimes' &&
          med.doseTimes != null &&
          med.doseTimes!.isNotEmpty) {
        scheduleType = ScheduleType.xTimesPerDay;
        // Convert API time strings to TimeOfDay
        doseTimes = med.doseTimes!
            .map((timeStr) => parseApiTimeToTimeOfDay(timeStr))
            .toList();
      } else if (med.scheduleType == 'Interval' || med.intervalHours != null) {
        scheduleType = ScheduleType.everyXHours;
      }
    }

    _schedule = _ScheduleConfig(
      type: scheduleType,
      intervalHours: med?.intervalHours ?? 6,
      doseTimes: doseTimes,
      startDate: med?.startDate ?? DateTime.now(),
      endDate: med?.endDate,
      firstDoseTime: med?.time ?? const TimeOfDay(hour: 8, minute: 0),
    );

    _selectedDosageForm = med?.dosageForm ?? widget.selectedDosageForm;
    _selectedQuantityUnit = normalizeQuantityUnit(
      med?.quantityUnit ??
          widget.selectedQuantityUnit ??
          quantityUnitForDosageForm(_selectedDosageForm),
    );
    _selectedMedicationId = med?.medicationId ?? widget.selectedMedicationId;
    _isCustomMedication =
        widget.isCustomMedication || (med?.isCustomMedication ?? false);
    _medicationSelectedFromCatalog =
        widget.medicationSelectedFromCatalog || med != null;

    // Initialize stock
    _stock = med?.currentQuantity ?? med?.currentPillCount ?? 30;
    _lowStockThreshold = med?.lowStockThreshold;
    _expiryDate = med?.expiryDate;
    _isOpened = med?.isOpened ?? false;
    _openedDate = med?.openedDate ?? (_isOpened ? DateTime.now() : null);
    _afterOpeningDurationUnit =
        med?.afterOpeningDurationUnit ??
        widget.defaultAfterOpeningUnit ??
        'days';
    final defaultAfterOpeningDuration =
        med?.afterOpeningDurationValue ??
        widget.defaultAfterOpeningValue ??
        _fallbackAfterOpeningDurationForForm(_selectedDosageForm);
    _afterOpeningDurationController = TextEditingController(
      text: defaultAfterOpeningDuration?.toString() ?? '',
    );
    _requiresOpeningTracking = widget.requiresOpeningTracking;
    _afterOpeningNote = med?.afterOpeningWarning ?? widget.afterOpeningNote;

    // Initialize pills per dose
    _pillsPerDose = med?.doseQuantity ?? med?.pillsPerDose ?? 1;

    _notificationActive = med?.notificationActive ?? true;
    _advanceReminderMinutes = med?.advanceReminderMinutes;
    _advanceReminderEnabled = _advanceReminderMinutes != null;

    final initialMinutes = med?.advanceReminderMinutes;
    final isPredefined = initialMinutes != null && const [15, 30, 45].contains(initialMinutes);
    _customAdvanceReminderMinutesController = TextEditingController(
      text: (initialMinutes != null && !isPredefined)
          ? initialMinutes.toString()
          : '',
    );
    _isCustomAdvanceReminder = initialMinutes != null && !isPredefined;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _noteController.dispose();
    _afterOpeningDurationController.dispose();
    _customAdvanceReminderMinutesController.dispose();
    super.dispose();
  }

  void _showScheduleSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ScheduleSelector(
        config: _schedule,
        onSave: (newConfig) {
          setState(() {
            _schedule = newConfig;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  /// Validate all required fields
  String? _validate() {
    if (_nameController.text.trim().isEmpty) {
      return 'Please enter medication name';
    }
    if (!_isCustomMedication &&
        !_medicationSelectedFromCatalog &&
        widget.initialMedicine == null &&
        widget.initialDrugName != null) {
      return 'Please select a medication from the list';
    }
    if (_schedule.type == ScheduleType.everyXHours &&
        _schedule.intervalHours <= 0) {
      return 'Interval hours must be greater than 0';
    }
    if (_schedule.type == ScheduleType.xTimesPerDay &&
        _schedule.doseTimes.isEmpty) {
      return 'Please add at least one dose time';
    }
    if (_selectedQuantityUnit.trim().isEmpty) {
      _selectedQuantityUnit = 'unit';
    }
    if (_stock == null || _stock! <= 0) {
      return 'Total quantity must be greater than 0';
    }
    if (_pillsPerDose <= 0) {
      return 'Quantity per dose must be greater than 0';
    }
    if (_pillsPerDose > _stock!) {
      return 'Dose quantity cannot be greater than total quantity';
    }
    if (_lowStockThreshold != null && _lowStockThreshold! < 0) {
      return context.l10n.t('lowStockNegative');
    }
    if (_lowStockThreshold != null &&
        _stock != null &&
        _lowStockThreshold! >= _stock!) {
      return context.l10n.t('lowStockLessTotal');
    }
    if (_isOpened) {
      if (_openedDate == null) {
        return context.l10n.t('pleaseSelectOpenedDate');
      }
      final duration = int.tryParse(_afterOpeningDurationController.text);
      if (duration == null || duration <= 0) {
        return context.l10n.t(
          'expiryDurationAfterOpeningMustBeGreaterThanZero',
        );
      }
    }
    if (_notificationActive && _advanceReminderEnabled) {
      if (_advanceReminderMinutes == null || _advanceReminderMinutes! <= 0) {
        return context.l10n.t('advanceReminderMinutesInvalid');
      }
    }
    return null;
  }

  String get _locale => context.read<LanguageProvider>().currentLanguage;

  String get _unitLabel =>
      getQuantityUnitLabel(_selectedQuantityUnit, locale: _locale);

  String get _formattedDose => formatQuantityWithUnit(
    _pillsPerDose,
    _selectedQuantityUnit,
    locale: _locale,
  );

  int? _fallbackAfterOpeningDurationForForm(String? dosageForm) {
    final normalized = dosageForm?.toUpperCase().replaceAll(' ', '_') ?? '';
    if (normalized.contains('EYE') || normalized.contains('DROP')) return 28;
    if (normalized.contains('SYRUP') ||
        normalized.contains('SUSPENSION') ||
        normalized.contains('SOLUTION')) {
      return 90;
    }
    if (normalized.contains('GEL') || normalized.contains('CREAM')) return 30;
    return null;
  }

  String get _openingSafetyMessage {
    final note = _afterOpeningNote;
    if (note != null && note.trim().isNotEmpty) return note.trim();
    return context.l10n.t(
      'thisIsADefaultDurationBasedOnTheMedicationTypePleaseCheckThePackageLeafletOrAskAPharmacist',
    );
  }

  String _openingReasonMessage(String? reason) {
    if (reason == 'AFTER_OPENING_EXPIRY') {
      return context.l10n.t('thisMedicationExpiresEarlierBecauseItWasOpened');
    }
    if (reason == 'PACKAGE_EXPIRY') {
      return context.l10n.t('thisMedicationExpiresBasedOnThePackageExpiryDate');
    }
    return '';
  }

  String get _openingUnitLabel => _afterOpeningDurationUnit == 'days'
      ? context.l10n.t('days')
      : _afterOpeningDurationUnit;

  Widget _buildTrackingInfoCard() {
    final typeLabel = getMedicationTypeLabel(
      _selectedDosageForm,
      locale: _locale,
    );
    final dosageTitle = _locale == 'ar' ? 'نوع الدواء' : 'Type';
    final unitTitle = _locale == 'ar' ? 'وحدة التتبع' : 'Tracking unit';

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryTeal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryTeal.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppColors.primaryTeal,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$dosageTitle: $typeLabel',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$unitTitle: $_unitLabel',
                  style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualMedicationNote() {
    final warning =
        widget.initialMedicine?.customMedicationWarning ??
        context.l10n.t('customMedicationWarning');

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: Colors.orange[800], size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              warning,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textDark,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAfterOpeningSection() {
    final dateLabel = _openedDate != null
        ? DateFormat('MMM d, yyyy').format(_openedDate!)
        : context.l10n.t('selectDate');

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isOpened
              ? AppColors.primaryTeal.withValues(alpha: 0.35)
              : AppColors.textGrey.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.lock_open_rounded,
                color: _requiresOpeningTracking
                    ? Colors.orange[700]
                    : AppColors.primaryTeal,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.t('openingTracking'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.t('haveYouOpenedThisMedication'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    if (_requiresOpeningTracking && !_isOpened) ...[
                      const SizedBox(height: 3),
                      Text(
                        context.l10n.t('openingTrackingRecommended'),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange[800],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _isOpened
                      ? Colors.green.withValues(alpha: 0.12)
                      : AppColors.textGrey.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _isOpened
                      ? context.l10n.t('openedMedication')
                      : context.l10n.t('notOpened'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _isOpened ? Colors.green[700] : AppColors.textGrey,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Switch(
                value: _isOpened,
                activeThumbColor: AppColors.primaryTeal,
                onChanged: (value) {
                  setState(() {
                    _isOpened = value;
                    if (value) {
                      _openedDate ??= DateTime.now();
                      if (_afterOpeningDurationController.text.isEmpty) {
                        final fallback = _fallbackAfterOpeningDurationForForm(
                          _selectedDosageForm,
                        );
                        if (fallback != null) {
                          _afterOpeningDurationController.text = fallback
                              .toString();
                        }
                      }
                      _afterOpeningDurationUnit =
                          _afterOpeningDurationUnit.isEmpty
                          ? 'days'
                          : _afterOpeningDurationUnit;
                    }
                  });
                },
              ),
            ],
          ),
          if (_isOpened) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _openedDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2101),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: AppColors.primaryTeal,
                          onPrimary: Colors.white,
                          onSurface: AppColors.textDark,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  setState(() => _openedDate = picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundCream,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.event_available_outlined,
                      color: AppColors.primaryTeal,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.t('openedDate'),
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textGrey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dateLabel,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.edit_outlined,
                      color: AppColors.primaryTeal,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _afterOpeningDurationController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: context.l10n.t('expiryDurationAfterOpening'),
                suffixText: _openingUnitLabel,
                filled: true,
                fillColor: AppColors.backgroundCream,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              context.l10n.t('safetyNote'),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textGrey,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 17,
                  color: Colors.orange[700],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$_openingSafetyMessage\n${context.l10n.t('checkThePackageLeafletOrAskAPharmacist')}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textGrey,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExpiryDetailsSection() {
    final med = widget.initialMedicine;
    if (med == null) return const SizedBox.shrink();

    final reasonMessage = _openingReasonMessage(med.expiryReason);
    final showSection =
        med.isOpened ||
        med.afterOpeningExpiryDate != null ||
        med.effectiveExpiryDate != null ||
        med.afterOpeningWarning != null ||
        reasonMessage.isNotEmpty;
    if (!showSection) return const SizedBox.shrink();

    Widget row(String label, String value, {IconData? icon}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon ?? Icons.circle,
              color: AppColors.primaryTeal,
              size: icon == null ? 8 : 17,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textGrey,
                    height: 1.35,
                  ),
                  children: [
                    TextSpan(
                      text: '$label: ',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(text: value),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryTeal.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryTeal.withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.t('expiryDetails'),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: med.isOpened
                      ? Colors.green.withValues(alpha: 0.12)
                      : AppColors.textGrey.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  med.isOpened
                      ? context.l10n.t('openedMedication')
                      : context.l10n.t('notOpened'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: med.isOpened
                        ? Colors.green[700]
                        : AppColors.textGrey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          row(
            context.l10n.t('packageExpiry'),
            DateFormat('MMM d, yyyy').format(med.expiryDate),
          ),
          if (med.isOpened && med.openedDate != null)
            row(
              context.l10n.t('openedDate'),
              DateFormat('MMM d, yyyy').format(med.openedDate!),
              icon: Icons.lock_open_rounded,
            ),
          if (med.afterOpeningDurationValue != null)
            row(
              context.l10n.t('defaultDuration'),
              '${med.afterOpeningDurationValue} ${med.afterOpeningDurationUnit == 'days' ? context.l10n.t('days') : (med.afterOpeningDurationUnit ?? '')}',
              icon: Icons.timelapse_rounded,
            ),
          if (med.afterOpeningExpiryDate != null)
            row(
              context.l10n.t('afterOpeningExpiry'),
              DateFormat('MMM d, yyyy').format(med.afterOpeningExpiryDate!),
              icon: Icons.event_busy_outlined,
            ),
          row(
            context.l10n.t('actualExpiry'),
            DateFormat('MMM d, yyyy').format(med.actualExpiryDate),
            icon: Icons.verified_outlined,
          ),
          if (reasonMessage.isNotEmpty)
            row(
              context.l10n.t('reasonLabel'),
              reasonMessage,
              icon: Icons.info_outline_rounded,
            ),
          if (med.afterOpeningWarning != null &&
              med.afterOpeningWarning!.trim().isNotEmpty)
            row(
              context.l10n.t('safetyNote'),
              med.afterOpeningWarning!.trim(),
              icon: Icons.warning_amber_rounded,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const BackButtonIcon(),
          color: AppColors.textDark,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.l10n.t('addMedicine'),
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Medication Name Card
            _buildCardSection(
              title: context.l10n.t('medication'),
              icon: Icons.medication_rounded,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      // Show name editor
                      showDialog(
                        context: context,
                        builder: (context) {
                          final controller = TextEditingController(
                            text: _nameController.text,
                          );
                          return AlertDialog(
                            title: Text(context.l10n.t('medicationName')),
                            content: TextField(
                              controller: controller,
                              decoration: InputDecoration(
                                hintText: 'e.g. Panadol 500mg',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  context.l10n.t('cancel'),
                                  style: TextStyle(color: AppColors.textGrey),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _nameController.text = controller.text;
                                  });
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryTeal,
                                ),
                                child: Text(
                                  context.l10n.t('save'),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.textGrey.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _nameController.text.isNotEmpty
                                      ? _nameController.text
                                      : context.l10n.t('tapMedicationName'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.edit_outlined,
                            color: AppColors.primaryTeal,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildTrackingInfoCard(),
                  if (_isCustomMedication) _buildManualMedicationNote(),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. Dosage Card
            _buildCardSection(
              title: context.l10n.t('dosage'),
              icon: Icons.medication_liquid,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          final controller = TextEditingController(
                            text: _dosageController.text,
                          );
                          return AlertDialog(
                            title: Text(context.l10n.t('dosageStrength')),
                            content: TextField(
                              controller: controller,
                              decoration: InputDecoration(
                                hintText: 'e.g. 500mg',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  context.l10n.t('cancel'),
                                  style: TextStyle(color: AppColors.textGrey),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _dosageController.text = controller.text;
                                  });
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryTeal,
                                ),
                                child: Text(
                                  context.l10n.t('save'),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.textGrey.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.l10n.t('strength'),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textGrey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _dosageController.text.isNotEmpty
                                    ? _dosageController.text
                                    : context.l10n.t('notSet'),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.edit_outlined,
                            color: AppColors.primaryTeal,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Pills Per Dose stepper
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.textGrey.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              getDoseQuantityFieldLabel(
                                _selectedQuantityUnit,
                                locale: _locale,
                              ),
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textGrey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _locale == 'ar'
                                  ? 'تخصم من الكمية عند تسجيل الجرعة'
                                  : 'Deducted per scheduled dose',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textGrey.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: _pillsPerDose > 1
                                  ? () => setState(() => _pillsPerDose--)
                                  : null,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _pillsPerDose > 1
                                      ? AppColors.primaryTeal.withValues(
                                          alpha: 0.1,
                                        )
                                      : Colors.grey[100],
                                ),
                                child: Icon(
                                  Icons.remove,
                                  size: 18,
                                  color: _pillsPerDose > 1
                                      ? AppColors.primaryTeal
                                      : Colors.grey[400],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                _formattedDose,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => _pillsPerDose++),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primaryTeal.withValues(
                                    alpha: 0.1,
                                  ),
                                ),
                                child: Icon(
                                  Icons.add,
                                  size: 18,
                                  color: AppColors.primaryTeal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. Schedule Card
            _buildCardSection(
              title: context.l10n.t('schedule'),
              icon: Icons.schedule_rounded,
              child: GestureDetector(
                onTap: _showScheduleSheet,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.textGrey.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _schedule.getDisplayText(context),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start: ${DateFormat('MMM d, yyyy').format(_schedule.startDate)}'
                              '${_schedule.endDate != null ? ' • End: ${DateFormat('MMM d, yyyy').format(_schedule.endDate!)}' : ''}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.edit_outlined,
                        color: AppColors.primaryTeal,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 4. Stock Card
            _buildCardSection(
              title: context.l10n.t('stockManagement'),
              icon: Icons.inventory_2_outlined,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      _showNumberInputDialog(
                        title: getQuantityFieldLabel(
                          _selectedQuantityUnit,
                          locale: _locale,
                        ),
                        initialValue: _stock,
                        onSave: (val) => setState(() => _stock = val),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.textGrey.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                getQuantityFieldLabel(
                                  _selectedQuantityUnit,
                                  locale: _locale,
                                ),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textGrey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _stock != null
                                    ? formatQuantityWithUnit(
                                        _stock,
                                        _selectedQuantityUnit,
                                        locale: _locale,
                                      )
                                    : context.l10n.t('notSet'),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.edit_outlined,
                            color: AppColors.primaryTeal,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      _showNumberInputDialog(
                        title: _locale == 'ar'
                            ? 'حد التنبيه عند انخفاض الكمية'
                            : context.l10n.t('lowStockThreshold'),
                        initialValue: _lowStockThreshold,
                        onSave: (val) =>
                            setState(() => _lowStockThreshold = val),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.textGrey.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _locale == 'ar'
                                    ? 'حد التنبيه عند انخفاض الكمية'
                                    : context.l10n.t('lowStockThreshold'),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textGrey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _lowStockThreshold != null
                                    ? (_locale == 'ar'
                                          ? 'نبه عند ${formatQuantityWithUnit(_lowStockThreshold, _selectedQuantityUnit, locale: _locale)}'
                                          : 'Remind at ${formatQuantityWithUnit(_lowStockThreshold, _selectedQuantityUnit, locale: _locale)}')
                                    : context.l10n.t('notSet'),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.edit_outlined,
                            color: AppColors.primaryTeal,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _expiryDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2101),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: AppColors.primaryTeal,
                                onPrimary: Colors.white,
                                onSurface: AppColors.textDark,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setState(() => _expiryDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.textGrey.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.l10n.t('expiryDate'),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textGrey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _expiryDate != null
                                    ? DateFormat(
                                        'MMM d, yyyy',
                                      ).format(_expiryDate!)
                                    : context.l10n.t('notSet'),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.edit_outlined,
                            color: AppColors.primaryTeal,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildAfterOpeningSection(),
                  _buildExpiryDetailsSection(),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 5. Notifications Card
            _buildCardSection(
              title: context.l10n.t('notifications'),
              icon: Icons.notifications_active_rounded,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.textGrey.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _notificationActive
                          ? context.l10n.t('enabled')
                          : context.l10n.t('disabled'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    Switch(
                      value: _notificationActive,
                      activeThumbColor: AppColors.primaryTeal,
                      onChanged: (val) =>
                          setState(() => _notificationActive = val),
                    ),
                  ],
                ),
              ),
            ),
            if (_notificationActive) ...[
              const SizedBox(height: 20),
              _buildCardSection(
                title: context.l10n.t('advanceReminder'),
                icon: Icons.alarm_rounded,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.textGrey.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _advanceReminderEnabled
                                ? context.l10n.t('enabled')
                                : context.l10n.t('disabled'),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          Switch(
                            value: _advanceReminderEnabled,
                            activeThumbColor: AppColors.primaryTeal,
                            onChanged: (val) {
                              setState(() {
                                _advanceReminderEnabled = val;
                                if (!val) {
                                  _advanceReminderMinutes = null;
                                  _isCustomAdvanceReminder = false;
                                } else {
                                  _advanceReminderMinutes = 15;
                                  _isCustomAdvanceReminder = false;
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      if (_advanceReminderEnabled) ...[
                        const Divider(height: 24),
                        _buildAdvanceReminderOptions(),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),

            // 6. Notes Card
            _buildCardSection(
              title: context.l10n.t('notes'),
              icon: Icons.note_alt_outlined,
              child: GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      final controller = TextEditingController(
                        text: _noteController.text,
                      );
                      return AlertDialog(
                        title: Text(context.l10n.t('notes')),
                        content: TextField(
                          controller: controller,
                          minLines: 3,
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText: context.l10n.t('optionalMedicationNotes'),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              context.l10n.t('cancel'),
                              style: TextStyle(color: AppColors.textGrey),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _noteController.text = controller.text;
                              });
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryTeal,
                            ),
                            child: Text(
                              context.l10n.t('save'),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.textGrey.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _noteController.text.isNotEmpty
                                  ? _noteController.text
                                  : context.l10n.t('tapAddNotes'),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.edit_outlined,
                        color: AppColors.primaryTeal,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveMedicine,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  disabledBackgroundColor: AppColors.primaryTeal.withValues(
                    alpha: 0.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        context.l10n.t('saveMedicine'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildCardSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primaryTeal, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textGrey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }

  Widget _buildAdvanceReminderOptions() {
    final options = [15, 30, 45];
    final isCustom = _isCustomAdvanceReminder;
    final lang = context.read<LanguageProvider>().currentLanguage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: [
            ...options.map((optionVal) {
              final isSelected = !isCustom && _advanceReminderMinutes == optionVal;
              final labelText = lang == 'ar' ? '$optionVal د' : '$optionVal min';

              return ChoiceChip(
                label: Text(labelText),
                selected: isSelected,
                selectedColor: AppColors.primaryTeal.withValues(alpha: 0.15),
                checkmarkColor: AppColors.primaryTeal,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.primaryTeal : AppColors.textDark,
                  fontSize: 13,
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _advanceReminderMinutes = optionVal;
                      _isCustomAdvanceReminder = false;
                    });
                  }
                },
              );
            }),
            ChoiceChip(
              label: Text(lang == 'ar' ? 'مخصص' : 'Custom'),
              selected: isCustom,
              selectedColor: AppColors.primaryTeal.withValues(alpha: 0.15),
              checkmarkColor: AppColors.primaryTeal,
              labelStyle: TextStyle(
                color: isCustom ? AppColors.primaryTeal : AppColors.textDark,
                fontSize: 13,
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _isCustomAdvanceReminder = true;
                    final parsedCustom = int.tryParse(_customAdvanceReminderMinutesController.text);
                    _advanceReminderMinutes = (parsedCustom != null && parsedCustom > 0) ? parsedCustom : 60;
                    _customAdvanceReminderMinutesController.text = _advanceReminderMinutes.toString();
                  });
                }
              },
            ),
          ],
        ),
        if (isCustom) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _customAdvanceReminderMinutesController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: context.l10n.t('customMinutes'),
              hintText: context.l10n.t('customMinutesInputHint'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onChanged: (val) {
              final parsed = int.tryParse(val);
              setState(() {
                if (parsed != null && parsed > 0) {
                  _advanceReminderMinutes = parsed;
                } else {
                  _advanceReminderMinutes = null;
                }
              });
            },
          ),
        ],
      ],
    );
  }

  void _showNumberInputDialog({
    required String title,
    int? initialValue,
    required Function(int?) onSave,
  }) {
    final controller = TextEditingController(
      text: initialValue?.toString() ?? '',
    );
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: context.l10n.t('enterNumber'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                context.l10n.t('cancel'),
                style: TextStyle(color: AppColors.textGrey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final val = int.tryParse(controller.text);
                onSave(val);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
              ),
              child: Text(
                context.l10n.t('save'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showSafetyAlert(List<String> warnings) async {
    await showInteractionWarningDialog(context, warnings);
  }

  int? _findCreatedCustomMedicationId(String medicationName) {
    final normalizedName = medicationName.trim().toLowerCase();
    int? foundId;
    for (final med in context.read<MedicineProvider>().medicines) {
      if (med.isCustomMedication &&
          med.name.trim().toLowerCase() == normalizedName) {
        foundId = int.tryParse(med.id);
      }
    }
    return foundId;
  }

  Future<void> _showSupportRequestDialog(
    String token,
    int userMedicationId,
  ) async {
    final send = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.t('requestAddMedicationToDatabaseTitle')),
        content: Text(context.l10n.t('requestAddMedicationToDatabaseBody')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.t('notNow')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
            ),
            child: Text(
              context.l10n.t('sendRequest'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (send != true || !mounted) return;

    final success = await context
        .read<MedicineProvider>()
        .requestAddMedicationToDatabase(token, userMedicationId);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? context.l10n.t('supportMedicationRequestSent')
              : context.l10n.t('failedToSendSupportMedicationRequest'),
        ),
      ),
    );
  }

  Future<void> _saveMedicine() async {
    final validation = _validate();
    if (validation != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validation)));
      return;
    }

    final userProvider = context.read<UserProvider>();
    final medProvider = context.read<MedicineProvider>();
    final token = userProvider.token;

    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.t('pleaseSignInSaveMedication'))),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Get schedule fields with new API format
      final scheduleFields = _schedule.toApiFields();

      // Determine first dose time based on schedule type
      final TimeOfDay firstDoseTime = _schedule.effectiveFirstDoseTime;

      // Build medicine object with all fields
      final quantityUnit = normalizeQuantityUnit(_selectedQuantityUnit);
      final medicine = Medicine(
        id: widget.initialMedicine?.id ?? '',
        medicationId: _isCustomMedication ? null : _selectedMedicationId,
        name: _nameController.text.trim(),
        startDate: _schedule.startDate,
        endDate:
            _schedule.endDate ??
            _schedule.startDate.add(const Duration(days: 30)),
        deadlineDate: DateTime.now(),
        expiryDate:
            _expiryDate ?? DateTime.now().add(const Duration(days: 365)),
        frequency: _schedule.getDisplayText(context),
        time: firstDoseTime,
        doseAmount: formatQuantityWithUnit(
          _pillsPerDose,
          quantityUnit,
          locale: _locale,
        ),
        initialStock: _stock ?? 0,
        note: _noteController.text.trim(),
        dosage: _dosageController.text.isNotEmpty
            ? _dosageController.text.trim()
            : null,
        dosageForm: _selectedDosageForm,
        quantityUnit: quantityUnit,
        initialQuantity: _stock,
        currentQuantity: _stock,
        doseQuantity: _pillsPerDose,
        currentPillCount: _stock,
        initialPillCount: _stock,
        lowStockThreshold: _lowStockThreshold,
        dosesPerPeriod: scheduleFields['dosesPerPeriod'] as int?,
        periodUnit: scheduleFields['periodUnit'] as String?,
        periodValue: scheduleFields['periodValue'] as int?,
        intervalHours: scheduleFields['intervalHours'] as int?,
        notificationActive: _notificationActive,
        advanceReminderMinutes: (_notificationActive && _advanceReminderEnabled)
            ? _advanceReminderMinutes
            : null,
        status: widget.initialMedicine?.status ?? MedicineStatus.scheduled,
        scheduleType: scheduleFields['scheduleType'] as String?,
        doseTimes: scheduleFields['doseTimes'] as List<String>?,
        pillsPerDose: _pillsPerDose,
        isOpened: _isOpened,
        openedDate: _isOpened ? _openedDate : null,
        afterOpeningDurationValue: _isOpened
            ? int.tryParse(_afterOpeningDurationController.text)
            : null,
        afterOpeningDurationUnit: _isOpened ? _afterOpeningDurationUnit : null,
        afterOpeningExpiryDate: widget.initialMedicine?.afterOpeningExpiryDate,
        effectiveExpiryDate: widget.initialMedicine?.effectiveExpiryDate,
        expiryReason: widget.initialMedicine?.expiryReason,
        afterOpeningSource: widget.initialMedicine?.afterOpeningSource,
        afterOpeningWarning: widget.initialMedicine?.afterOpeningWarning,
        isCustomMedication: _isCustomMedication,
        supportsInteractions: widget.initialMedicine?.supportsInteractions,
        supportsIngredientWarnings:
            widget.initialMedicine?.supportsIngredientWarnings,
        customMedicationWarning:
            widget.initialMedicine?.customMedicationWarning,
      );

      if (widget.initialMedicine != null) {
        // --- Edit existing medication ---
        final success = await medProvider.updateMedicineOnApi(token, medicine);
        if (success) {
          await medProvider.fetchMedicinesFromApi(token);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.t('medicineUpdated'))),
            );
            Navigator.pop(context);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  medProvider.error ?? context.l10n.t('failedToUpdate'),
                ),
              ),
            );
          }
        }
      } else {
        // --- Add new medication ---
        final response = await medProvider.addMedicineToApi(token, medicine);
        if (response != null) {
          // Check for interaction warnings
          if (response.hasInteractionWarnings) {
            await _showSafetyAlert(response.interactionWarnings);
          }

          // Refresh My Meds
          await medProvider.fetchMedicinesFromApi(token);

          if (_isCustomMedication && mounted) {
            final responseId = response.userMedicationId;
            final createdId =
                responseId ?? _findCreatedCustomMedicationId(medicine.name);
            if (createdId != null) {
              await _showSupportRequestDialog(token, createdId);
            }
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.t('medicineAdded'))),
            );
            Navigator.pop(context);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  medProvider.error ?? context.l10n.t('failedToAdd'),
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.t('errorWithMessage', {'message': e})),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

/// Schedule selector bottom sheet
class _ScheduleSelector extends StatefulWidget {
  final _ScheduleConfig config;
  final Function(_ScheduleConfig) onSave;

  const _ScheduleSelector({required this.config, required this.onSave});

  @override
  State<_ScheduleSelector> createState() => _ScheduleSelectorState();
}

class _ScheduleSelectorState extends State<_ScheduleSelector> {
  late ScheduleType _selectedType;
  late int _intervalHours;
  late List<TimeOfDay> _doseTimes;
  late DateTime _startDate;
  late DateTime? _endDate;
  late TimeOfDay _firstDoseTime;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.config.type;
    _intervalHours = widget.config.intervalHours;
    _doseTimes =
        _selectedType == ScheduleType.xTimesPerDay &&
            widget.config.doseTimes.isNotEmpty
        ? List<TimeOfDay>.from(widget.config.doseTimes)
        : <TimeOfDay>[const TimeOfDay(hour: 8, minute: 0)];
    _startDate = widget.config.startDate;
    _endDate = widget.config.endDate;
    _firstDoseTime = widget.config.firstDoseTime;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.l10n.t('schedule'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              context.l10n.t('scheduleType'),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textGrey,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundCream,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _selectedType = ScheduleType.everyXHours;
                        // Clear dose times when switching to Interval
                        _doseTimes = <TimeOfDay>[];
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedType == ScheduleType.everyXHours
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Every X Hours',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _selectedType == ScheduleType.everyXHours
                                ? AppColors.primaryTeal
                                : AppColors.textGrey,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _selectedType = ScheduleType.xTimesPerDay;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedType == ScheduleType.xTimesPerDay
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'X Times Per Day',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _selectedType == ScheduleType.xTimesPerDay
                                ? AppColors.primaryTeal
                                : AppColors.textGrey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_selectedType == ScheduleType.everyXHours) ...[
              const Text(
                'Interval (hours)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.textGrey.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: _intervalHours > 1
                          ? () => setState(() => _intervalHours--)
                          : null,
                      icon: Icon(
                        Icons.remove_circle_outline,
                        color: _intervalHours > 1
                            ? AppColors.primaryTeal
                            : Colors.grey[300],
                      ),
                    ),
                    Text(
                      '$_intervalHours hours',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _intervalHours++),
                      icon: Icon(
                        Icons.add_circle,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'First Dose Time',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _firstDoseTime,
                    builder: (ctx, child) => Theme(
                      data: Theme.of(ctx).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: AppColors.primaryTeal,
                          onPrimary: Colors.white,
                          onSurface: AppColors.textDark,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) setState(() => _firstDoseTime = picked);
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.textGrey.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _firstDoseTime.format(context),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(Icons.access_time, color: AppColors.primaryTeal),
                    ],
                  ),
                ),
              ),
            ] else ...[
              const Text(
                'Dose Times',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 12),
              ..._doseTimes.asMap().entries.map(
                (entry) => GestureDetector(
                  onTap: () async {
                    final TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: entry.value,
                      builder: (ctx, child) => Theme(
                        data: Theme.of(ctx).copyWith(
                          colorScheme: ColorScheme.light(
                            primary: AppColors.primaryTeal,
                            onPrimary: Colors.white,
                            onSurface: AppColors.textDark,
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (!context.mounted) return;
                    if (picked != null) {
                      final exists = _doseTimes.asMap().entries.any(
                        (e) =>
                            e.key != entry.key &&
                            e.value.hour == picked.hour &&
                            e.value.minute == picked.minute,
                      );
                      if (!exists) {
                        setState(() {
                          _doseTimes[entry.key] = picked;
                          _doseTimes.sort(
                            (a, b) => a.hour != b.hour
                                ? a.hour - b.hour
                                : a.minute - b.minute,
                          );
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(context.l10n.t('timeAlreadyAdded')),
                          ),
                        );
                      }
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.textGrey.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.value.format(context),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () {
                            setState(() {
                              _doseTimes.removeAt(entry.key);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () async {
                  final TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 8, minute: 0),
                    builder: (ctx, child) => Theme(
                      data: Theme.of(ctx).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: AppColors.primaryTeal,
                          onPrimary: Colors.white,
                          onSurface: AppColors.textDark,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (!context.mounted) return;
                  if (picked != null) {
                    final exists = _doseTimes.any(
                      (t) => t.hour == picked.hour && t.minute == picked.minute,
                    );
                    if (!exists) {
                      setState(() {
                        _doseTimes.add(picked);
                        _doseTimes.sort(
                          (a, b) => a.hour != b.hour
                              ? a.hour - b.hour
                              : a.minute - b.minute,
                        );
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(context.l10n.t('timeAlreadyAdded')),
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(
                  Icons.add_circle,
                  color: AppColors.primaryTeal,
                ),
                label: Text(context.l10n.t('addDoseTime')),
              ),
              if (_doseTimes.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Please add at least one dose time.',
                    style: TextStyle(color: Colors.redAccent, fontSize: 13),
                  ),
                ),
              const SizedBox(height: 20),
            ],
            const Text(
              'Start Date',

              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textGrey,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2101),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: AppColors.primaryTeal,
                          onPrimary: Colors.white,
                          onSurface: AppColors.textDark,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  setState(() => _startDate = picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.textGrey.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('MMM d, yyyy').format(_startDate),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      Icons.calendar_today_outlined,
                      color: AppColors.primaryTeal,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'End Date (Optional)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textGrey,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate:
                      _endDate ?? _startDate.add(const Duration(days: 30)),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2101),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: AppColors.primaryTeal,
                          onPrimary: Colors.white,
                          onSurface: AppColors.textDark,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  setState(() => _endDate = picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.textGrey.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _endDate != null
                          ? DateFormat('MMM d, yyyy').format(_endDate!)
                          : context.l10n.t('notSet'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _endDate != null
                            ? AppColors.textDark
                            : AppColors.textGrey,
                      ),
                    ),
                    Icon(
                      Icons.calendar_today_outlined,
                      color: AppColors.primaryTeal,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed:
                    (_selectedType == ScheduleType.everyXHours &&
                            _intervalHours > 0) ||
                        (_selectedType == ScheduleType.xTimesPerDay &&
                            _doseTimes.isNotEmpty)
                    ? () {
                        final config = _selectedType == ScheduleType.everyXHours
                            ? _ScheduleConfig(
                                type: _selectedType,
                                intervalHours: _intervalHours,
                                startDate: _startDate,
                                endDate: _endDate,
                                firstDoseTime: _firstDoseTime,
                              )
                            : _ScheduleConfig(
                                type: _selectedType,
                                doseTimes: List<TimeOfDay>.from(_doseTimes),
                                startDate: _startDate,
                                endDate: _endDate,
                              );
                        widget.onSave(config);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  context.l10n.t('saveSchedule'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
