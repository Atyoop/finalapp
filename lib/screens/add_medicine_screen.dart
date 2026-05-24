import 'package:final88/screens/medicine_scan_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../providers/language_provider.dart';
import '../services/medications_service.dart';

import 'add_reminder_screen.dart';

// ─── Data model for a medication from the API ───
class ApiMedication {
  final int id;
  final String tradeName;
  final String description;
  final String dosageForm;
  final String imageUrl;
  final List<Map<String, dynamic>> ingredients;

  ApiMedication({
    required this.id,
    required this.tradeName,
    required this.description,
    required this.dosageForm,
    required this.imageUrl,
    required this.ingredients,
  });

  factory ApiMedication.fromJson(Map<String, dynamic> json) {
    final rawIngredients = json['ingredients'] as List<dynamic>? ?? [];
    return ApiMedication(
      id: json['id'] ?? 0,
      tradeName: json['trade_name'] ?? '',
      description: json['description'] ?? '',
      dosageForm: json['dosage_Form'] ?? '',
      imageUrl: json['image_url'] ?? '',
      ingredients: rawIngredients
          .map((i) => i as Map<String, dynamic>)
          .toList(),
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
        _loadError = 'Connection error. Check your internet.';
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
        return Icons.medication_liquid;
      case 'AMPOULE':
      case 'VIAL_POWDER':
        return Icons.vaccines;
      case 'SUPPOSITORIES':
        return Icons.emergency;
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
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textDark),
        title: Text(
          'Add Medicine',
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
                  "Search for your medication",
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
                            hintText: "Type medication name or ingredient...",
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
                            borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(28),
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
                          'Loading medications...',
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
                          _loadError!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textGrey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _fetchMedications,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
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
                          'Search for a medication',
                          style: TextStyle(
                            color: AppColors.textDark,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Start typing to search',
                          style: TextStyle(
                            color: AppColors.textGrey.withValues(alpha: 0.6),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : _filtered.isEmpty
                ? Center(
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
                          'No results for "$_query"',
                          style: TextStyle(color: AppColors.textGrey),
                        ),
                      ],
                    ),
                  )
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
          builder: (_) => AddReminderScreen(initialDrugName: med.tradeName),
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
