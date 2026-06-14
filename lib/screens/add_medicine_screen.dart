import 'package:final88/screens/medicine_scan_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import '../providers/language_provider.dart';
import '../services/medications_service.dart';
import '../utils/quantity_helpers.dart';

import 'add_reminder_screen.dart';

// ─── Data model for a medication from the API ───
class ApiMedication {
  final int id;
  final String tradeName;
  final String description;
  final String dosageForm;
  final String quantityUnit;
  final String imageUrl;
  final List<Map<String, dynamic>> ingredients;
  final int? defaultAfterOpeningValue;
  final String? defaultAfterOpeningUnit;
  final bool requiresOpeningTracking;
  final String? afterOpeningNote;

  ApiMedication({
    required this.id,
    required this.tradeName,
    required this.description,
    required this.dosageForm,
    required this.quantityUnit,
    required this.imageUrl,
    required this.ingredients,
    this.defaultAfterOpeningValue,
    this.defaultAfterOpeningUnit,
    this.requiresOpeningTracking = false,
    this.afterOpeningNote,
  });

  factory ApiMedication.fromJson(Map<String, dynamic> json) {
    final rawIngredients = json['ingredients'] as List<dynamic>? ?? [];
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.round();
      return int.tryParse(value.toString());
    }

    dynamic readAny(List<String> keys) {
      for (final key in keys) {
        if (json.containsKey(key)) return json[key];
      }
      return null;
    }

    return ApiMedication(
      id: json['id'] ?? 0,
      tradeName: json['trade_name'] ?? '',
      description: json['description'] ?? '',
      dosageForm: json['dosage_Form'] ?? '',
      quantityUnit:
          json['quantityUnit'] ??
          quantityUnitForDosageForm(json['dosage_Form']?.toString()),
      imageUrl: json['image_url'] ?? '',
      ingredients: rawIngredients
          .map((i) => i as Map<String, dynamic>)
          .toList(),
      defaultAfterOpeningValue: parseInt(
        readAny(['defaultAfterOpeningValue', 'DefaultAfterOpeningValue']),
      ),
      defaultAfterOpeningUnit:
          readAny([
            'defaultAfterOpeningUnit',
            'DefaultAfterOpeningUnit',
          ])?.toString() ??
          'days',
      requiresOpeningTracking:
          readAny(['requiresOpeningTracking', 'RequiresOpeningTracking'])
              as bool? ??
          false,
      afterOpeningNote: readAny([
        'afterOpeningNote',
        'AfterOpeningNote',
      ])?.toString(),
    );
  }

  /// Build a readable strength label from ingredients, e.g. "500mg • 65mg"
  String get strengthLabel {
    if (ingredients.isEmpty) return dosageForm;
    final parts = ingredients
        .map((i) {
          final val = i['strength_value'];
          final unit = i['strength_unit'] ?? '';
          return '$val $unit';
        })
        .take(2)
        .join(' • ');
    return '$dosageForm • $parts';
  }
}

class _ManualDosageFormOption {
  final String value;
  final String unit;
  final IconData icon;

  const _ManualDosageFormOption({
    required this.value,
    required this.unit,
    required this.icon,
  });
}

class AddMedicineScreen extends StatefulWidget {
  const AddMedicineScreen({super.key});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  // API state
  List<ApiMedication> _allMedications = [];
  bool _isLoading = true;
  String? _loadError;
  String? _currentLanguage;

  @override
  void initState() {
    super.initState();
    _fetchMedications();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newLang = Provider.of<LanguageProvider>(context).currentLanguage;
    if (_currentLanguage != null && _currentLanguage != newLang) {
      _currentLanguage = newLang;
      _fetchMedications();
    } else {
      _currentLanguage = newLang;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchMedications() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final data = await MedicationsService.fetchAllMeds();
      setState(() {
        _allMedications = data.map(ApiMedication.fromJson).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _loadError = 'connectionErrorInternet';
        _isLoading = false;
      });
    }
  }

  List<ApiMedication> get _filtered {
    if (_query.trim().isEmpty) return [];
    final q = _query.toLowerCase();
    return _allMedications.where((m) {
      return m.tradeName.toLowerCase().contains(q) ||
          m.description.toLowerCase().contains(q) ||
          m.ingredients.any(
            (i) => (i['ingredientName'] ?? '')
                .toString()
                .toLowerCase()
                .contains(q),
          );
    }).toList();
  }

  // Map dosage form to a nice icon + color
  IconData _iconFor(String form) {
    switch (form.toUpperCase()) {
      case 'SYRUP':
      case 'SUSPENSION':
      case 'ORAL_SOLUTION':
      case 'ORAL_DROP':
      case 'ORAL_DROPS':
        return Icons.medication_liquid;
      case 'EYE_DROPS':
      case 'EYE_DROP':
        return Icons.remove_red_eye_outlined;
      case 'INJECTION':
      case 'AMPOULE':
      case 'VIAL_POWDER':
        return Icons.vaccines;
      case 'INHALER':
        return Icons.air;
      case 'SUPPOSITORIES':
        return Icons.emergency;
      case 'CREAM':
      case 'OINTMENT':
      case 'GEL':
      case 'EMULGEL':
      case 'TOPICAL_PATCH':
        return Icons.spa;
      case 'SACHETS':
        return Icons.bakery_dining;
      default:
        return Icons.medication;
    }
  }

  Color _colorFor(int index) {
    final colors = [
      const Color(0xFFE8F5E9),
      const Color(0xFFFFF3E0),
      const Color(0xFFE3F2FD),
      const Color(0xFFFCE4EC),
      const Color(0xFFEDE7F6),
      const Color(0xFFE0F7FA),
      const Color(0xFFF3E5F5),
      const Color(0xFFFFF8E1),
    ];
    return colors[index % colors.length];
  }

  List<_ManualDosageFormOption> get _manualDosageForms => const [
    _ManualDosageFormOption(
      value: 'Tablet',
      unit: 'tablet',
      icon: Icons.medication,
    ),
    _ManualDosageFormOption(
      value: 'Syrup',
      unit: 'ml',
      icon: Icons.medication_liquid,
    ),
    _ManualDosageFormOption(
      value: 'Oral Drops',
      unit: 'drops',
      icon: Icons.water_drop_outlined,
    ),
    _ManualDosageFormOption(
      value: 'Injection',
      unit: 'unit',
      icon: Icons.vaccines,
    ),
    _ManualDosageFormOption(
      value: 'Ointment',
      unit: 'g',
      icon: Icons.spa,
    ),
    _ManualDosageFormOption(
      value: 'Inhaler',
      unit: 'puffs',
      icon: Icons.air,
    ),
    _ManualDosageFormOption(
      value: 'Other',
      unit: 'unit',
      icon: Icons.category_outlined,
    ),
  ];

  String _manualDosageFormLabel(String value) {
    final locale = context.read<LanguageProvider>().currentLanguage;
    final isAr = locale == 'ar';
    switch (value) {
      case 'Tablet':
        return isAr ? 'حبوب' : 'Tablets / Pills';
      case 'Syrup':
        return isAr ? 'شراب' : 'Syrup';
      case 'Oral Drops':
        return isAr ? 'قطرات' : 'Drops';
      case 'Injection':
        return isAr ? 'حقن' : 'Injection';
      case 'Ointment':
        return isAr ? 'مرهم' : 'Ointment / Cream';
      case 'Inhaler':
        return isAr ? 'بخاخ' : 'Spray';
      case 'Other':
        return isAr ? 'أخرى' : 'Other';
      default:
        return context.l10n.t('dosageForm${value.replaceAll(' ', '')}');
    }
  }

  Future<void> _showManualDosageFormSheet(String medicationName) async {
    final selected = await showModalBottomSheet<_ManualDosageFormOption>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.t('chooseDosageForm'),
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                medicationName,
                style: TextStyle(color: AppColors.textGrey, fontSize: 13),
              ),
              const SizedBox(height: 18),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _manualDosageForms.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final option = _manualDosageForms[index];
                    return Material(
                      color: AppColors.backgroundCream,
                      borderRadius: BorderRadius.circular(14),
                      child: ListTile(
                        leading: Icon(
                          option.icon,
                          color: AppColors.primaryTeal,
                        ),
                        title: Text(
                          _manualDosageFormLabel(option.value),
                          style: TextStyle(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          context.l10n.t('defaultUnit', {
                            'unit': getQuantityUnitLabel(
                              option.unit,
                              locale: _currentLanguage ?? 'en',
                            ),
                          }),
                          style: TextStyle(color: AppColors.textGrey),
                        ),
                        onTap: () => Navigator.pop(context, option),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (selected == null || !mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddReminderScreen(
          initialDrugName: medicationName,
          selectedDosageForm: selected.value,
          selectedQuantityUnit: selected.unit,
          selectedMedicationId: null,
          isCustomMedication: true,
          medicationSelectedFromCatalog: false,
        ),
      ),
    );
  }

  Widget _buildManualAddTile() {
    final name = _query.trim();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medication_outlined,
            size: 64,
            color: AppColors.textGrey.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.t('noResultsFor', {'query': name}),
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textGrey),
          ),
          const SizedBox(height: 18),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => _showManualDosageFormSheet(name),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.primaryTeal.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.add_circle, color: AppColors.primaryTeal),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        context.l10n.t('addMedicationManually', {'name': name}),
                        style: TextStyle(
                          color: AppColors.primaryTeal,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _iconColorFor(int index) {
    final colors = [
      const Color(0xFF4CAF50),
      const Color(0xFFFF9800),
      const Color(0xFF2196F3),
      const Color(0xFFE91E63),
      const Color(0xFF673AB7),
      const Color(0xFF00BCD4),
      const Color(0xFF9C27B0),
      const Color(0xFFFF9800),
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textDark),
        title: Text(
          context.l10n.t('addMedicine'),
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Search Bar ───
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.t('searchMedication'),
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
                        color: Colors.black.withValues(alpha: 0.04),
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
                            hintText: context.l10n.t(
                              'typeMedicationOrIngredient',
                            ),
                            hintStyle: TextStyle(
                              color: AppColors.textGrey.withValues(alpha: 0.6),
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
                            builder: (_) => const MedicineScanScreen(),
                          ),
                        ),
                        child: Container(
                          width: 65,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.primaryTeal,
                            borderRadius: BorderRadius.only(
                              topLeft: isAr ? const Radius.circular(28) : Radius.zero,
                              bottomLeft: isAr ? const Radius.circular(28) : Radius.zero,
                              topRight: isAr ? Radius.zero : const Radius.circular(28),
                              bottomRight: isAr ? Radius.zero : const Radius.circular(28),
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
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ─── Results Area ───
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppColors.primaryTeal),
                        const SizedBox(height: 16),
                        Text(
                          context.l10n.t('loadingMedications'),
                          style: TextStyle(color: AppColors.textGrey),
                        ),
                      ],
                    ),
                  )
                : _loadError != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.wifi_off_rounded,
                          size: 64,
                          color: AppColors.textGrey.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          context.l10n.t(_loadError!),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textGrey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _fetchMedications,
                          icon: const Icon(Icons.refresh),
                          label: Text(context.l10n.t('retry')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryTeal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : _query.trim().isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_rounded,
                          size: 80,
                          color: AppColors.primaryTeal.withValues(alpha: 0.18),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          context.l10n.t('searchForMedication'),
                          style: TextStyle(
                            color: AppColors.textDark,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.l10n.t('startTypingToSearch'),
                          style: TextStyle(
                            color: AppColors.textGrey.withValues(alpha: 0.6),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : _filtered.isEmpty
                ? Center(child: _buildManualAddTile())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      return _buildResultTile(_filtered[index], index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultTile(ApiMedication med, int index) {
    final bgColor = _colorFor(index);
    final iconColor = _iconColorFor(index);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddReminderScreen(
            initialDrugName: med.tradeName,
            selectedDosageForm: med.dosageForm,
            selectedQuantityUnit: med.quantityUnit,
            selectedMedicationId: med.id,
            isCustomMedication: false,
            medicationSelectedFromCatalog: true,
            defaultAfterOpeningValue: med.defaultAfterOpeningValue,
            defaultAfterOpeningUnit: med.defaultAfterOpeningUnit,
            requiresOpeningTracking: med.requiresOpeningTracking,
            afterOpeningNote: med.afterOpeningNote,
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
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon Box
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(_iconFor(med.dosageForm), color: iconColor, size: 26),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    med.tradeName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    med.strengthLabel,
                    style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                  ),
                  if (med.description.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      med.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textGrey.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.add_circle_outline_rounded,
              color: AppColors.primaryTeal.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}
