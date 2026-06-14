import 'dart:convert';

import 'package:final88/screens/medicine_scan_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../main.dart';
import '../l10n/app_localizations.dart';
import '../providers/language_provider.dart';
import '../providers/user_provider.dart';
import '../services/language_service.dart';
import '../services/medications_service.dart';

// ─────────────────────────────────────────────
// Result Screen
// ─────────────────────────────────────────────
class InteractionResultScreen extends StatelessWidget {
  final String message;
  final List<dynamic> results; // each item: {med1, med2, interactions:[...]}
  final List<Map<String, dynamic>> selectedMeds;

  const InteractionResultScreen({
    super.key,
    required this.message,
    required this.results,
    required this.selectedMeds,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAr = Localizations.localeOf(context).languageCode == 'ar';
    final bool hasInteraction =
        results.isNotEmpty &&
        results.any((r) {
          final interactions = r['interactions'] as List<dynamic>? ?? [];
          return interactions.isNotEmpty;
        });

    String getLocalizedMessage(String msg) {
      if (!isAr) return msg;
      final lower = msg.trim().toLowerCase();
      if (lower.contains('no interaction') || lower.contains('no interactions')) {
        return 'لا توجد تداخلات دوائية بين الأدوية المحددة.';
      }
      if (lower.contains('interaction found') || lower.contains('interactions found')) {
        return 'تم العثور على تداخلات دوائية!';
      }
      return msg;
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundCream,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textDark,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isAr ? 'نتائج التداخلات' : 'Interaction Result',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Selected Medications Chips ──
            Text(
              isAr ? 'الأدوية التي تم فحصها' : 'Checked Medications',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textGrey,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: selectedMeds.map((med) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryTeal.withValues(alpha: 0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.medication,
                        size: 14,
                        color: AppColors.primaryTeal,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        med['name'],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryTeal,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // ── Result Banner ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: hasInteraction
                    ? const Color(0xFFFFF3E0)
                    : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: hasInteraction
                      ? const Color(0xFFFF9800).withValues(alpha: 0.5)
                      : const Color(0xFF4CAF50).withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: hasInteraction
                          ? const Color(0xFFFF9800).withValues(alpha: 0.15)
                          : const Color(0xFF4CAF50).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      hasInteraction
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle_outline,
                      color: hasInteraction
                          ? const Color(0xFFFF9800)
                          : const Color(0xFF4CAF50),
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasInteraction
                              ? (isAr ? 'تم العثور على تداخلات' : 'Interactions Found')
                              : (isAr ? 'لا توجد تداخلات' : 'No Interactions'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: hasInteraction
                                ? const Color(0xFFE65100)
                                : const Color(0xFF2E7D32),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          getLocalizedMessage(message),
                          style: TextStyle(
                            fontSize: 13,
                            color: hasInteraction
                                ? const Color(0xFFBF360C)
                                : const Color(0xFF388E3C),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Interaction Pair Results ──
            if (hasInteraction) ...[
              Text(
                isAr ? 'تفاصيل التداخلات' : 'Interaction Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              ...results.map((result) {
                final med1 = result['med1']?.toString() ?? '';
                final med2 = result['med2']?.toString() ?? '';
                final interactions =
                    result['interactions'] as List<dynamic>? ?? [];

                if (interactions.isEmpty) return const SizedBox.shrink();

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFFF9800).withValues(alpha: 0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Pair Header ──
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFFF9800,
                          ).withValues(alpha: 0.07),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(18),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Med 1 pill
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryTeal.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.medication,
                                      size: 14,
                                      color: AppColors.primaryTeal,
                                    ),
                                    const SizedBox(width: 5),
                                    Flexible(
                                      child: Text(
                                        med1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primaryTeal,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Arrow
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.swap_horiz_rounded,
                                    color: const Color(0xFFFF9800),
                                    size: 22,
                                  ),
                                  Text(
                                    isAr ? 'يتفاعل مع' : 'interacts',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: AppColors.textGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Med 2 pill
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryTeal.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.medication,
                                      size: 14,
                                      color: AppColors.primaryTeal,
                                    ),
                                    const SizedBox(width: 5),
                                    Flexible(
                                      child: Text(
                                        med2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primaryTeal,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Interaction Types ──
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAr
                                  ? 'تم العثور على تداخلات (${interactions.length})'
                                  : '${interactions.length} interaction${interactions.length > 1 ? 's' : ''} found',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textGrey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ...interactions.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final interaction = entry.value;
                              final type =
                                  interaction['interaction_type']?.toString() ??
                                  interaction['Interaction_type']?.toString() ??
                                  '';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF3E0),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(
                                      0xFFFF9800,
                                    ).withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Number badge
                                    Container(
                                      width: 22,
                                      height: 22,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFF9800),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${idx + 1}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        type,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textDark,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ] else ...[
              // ── Safe State ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
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
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 56,
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.7),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      context.l10n.t('noKnownInteractions'),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.l10n.t('consultBeforeCombining'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textGrey,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // ── Disclaimer ──
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.textGrey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.l10n.t('medicalDisclaimer'),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textGrey,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Back Button ──
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
                ),
                child: Text(
                  context.l10n.t('checkAgain'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Main Screen
// ─────────────────────────────────────────────
class CheckInteractionsScreen extends StatefulWidget {
  const CheckInteractionsScreen({super.key});
  @override
  State<CheckInteractionsScreen> createState() =>
      _CheckInteractionsScreenState();
}

class _CheckInteractionsScreenState extends State<CheckInteractionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  final List<Map<String, dynamic>> _selectedMeds = [];
  static const int _maxMeds = 10;

  List<Map<String, dynamic>> _drugs = [];
  bool _isFetchingMeds = false;
  bool _isCheckingInteraction = false;
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

  List<Map<String, dynamic>> get _filtered {
    if (_query.isEmpty) return _drugs;
    return _drugs
        .where(
          (d) =>
              d['name'].toString().toLowerCase().contains(
                _query.toLowerCase(),
              ) ||
              d['type'].toString().toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchMedications() async {
    setState(() => _isFetchingMeds = true);
    try {
      final data = await MedicationsService.fetchAllMeds();
      final List<Map<String, dynamic>> meds = data.map((j) {
        final String name = (j['trade_name'] ?? '').toString();
        final String form = (j['dosage_Form'] ?? '').toString();

        String type = '';
        final ingredients = j['ingredients'];
        if (ingredients is List && ingredients.isNotEmpty) {
          type = (ingredients.first['ingredientName'] ?? '').toString();
        }
        if (type.isEmpty) type = 'Medication';

        String strength = '';
        if (ingredients is List && ingredients.isNotEmpty) {
          final first = ingredients.first;
          final val = first['strength_value']?.toString() ?? '';
          final unit = first['strength_unit']?.toString() ?? '';
          if (val.isNotEmpty) strength = '$val$unit';
        }

        final String displayForm = [
          form,
          strength,
        ].where((s) => s.isNotEmpty).join(' • ');

        return {
          'id': j['id'],
          'name': name.isNotEmpty ? name : 'Unknown',
          'type': type,
          'form': displayForm,
          'imageUrl': (j['image_url'] ?? '').toString(),
          'color': const Color(0xFFE8F5E9),
          'icon': Icons.medication,
          'iconColor': AppColors.primaryTeal,
        };
      }).toList();

      setState(() => _drugs = meds);
    } catch (_) {
      // show empty state on error
    } finally {
      if (mounted) setState(() => _isFetchingMeds = false);
    }
  }

  Future<void> _checkInteraction() async {
    if (_selectedMeds.length < 2) return;

    final token = context.read<UserProvider>().token;
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.t('pleaseSignInCheckInteractions')),
        ),
      );
      return;
    }

    setState(() => _isCheckingInteraction = true);

    try {
      // Build query params for all selected med names
      // e.g. ?medNames=Panadol&medNames=Cataflam&medNames=Congestal
      final queryParams = _selectedMeds
          .map((m) => 'medNames=${Uri.encodeComponent(m['name'].toString())}')
          .join('&');

      final uri = Uri.parse(
        'https://drugsafe.runasp.net/api/Medications/check-interaction'
        '?$queryParams&lang=${LanguageService.currentLanguage}',
      );

      final res = await http
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 20));

      final body = json.decode(res.body) as Map<String, dynamic>;

      // Parse new response structure
      // { "message": "...", "results": [ { "med1", "med2", "interactions": [...] } ] }
      final String message =
          body['message']?.toString() ?? body['Message']?.toString() ?? '';
      final List<dynamic> results =
          (body['results'] ?? body['Results']) as List<dynamic>? ?? [];

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => InteractionResultScreen(
            message: message,
            results: results,
            selectedMeds: List.from(_selectedMeds),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => InteractionResultScreen(
            message: context.l10n.t('failedCheckInteractions'),
            results: const [],
            selectedMeds: List.from(_selectedMeds),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isCheckingInteraction = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Text(
                context.l10n.t('checkMeds'),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
              child: Text(
                context.l10n.t('selectUpToMeds', {'count': _maxMeds}),
                style: TextStyle(fontSize: 14, color: AppColors.textGrey),
              ),
            ),

            // ── Search Bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
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
                          hintText: context.l10n.t('typeMedicationName'),
                          hintStyle: TextStyle(
                            color: AppColors.textGrey.withValues(alpha: 0.6),
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: AppColors.textDark,
                          ),
                          suffixIcon: _query.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close, size: 20),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _query = '');
                                  },
                                )
                              : null,
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
            ),
            const SizedBox(height: 12),

            // ── Selected Chips ──
            if (_selectedMeds.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          context.l10n.t('selectedCount', {
                            'selected': _selectedMeds.length,
                            'max': _maxMeds,
                          }),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryTeal,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => setState(() => _selectedMeds.clear()),
                          child: Text(
                            context.l10n.t('clearAll'),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: _selectedMeds.map((med) {
                        return Chip(
                          backgroundColor: AppColors.primaryTeal.withValues(
                            alpha: 0.1,
                          ),
                          side: BorderSide(
                            color: AppColors.primaryTeal.withValues(alpha: 0.3),
                          ),
                          label: Text(
                            med['name'],
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primaryTeal,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          avatar: Icon(
                            Icons.medication,
                            size: 14,
                            color: AppColors.primaryTeal,
                          ),
                          deleteIcon: const Icon(Icons.close, size: 14),
                          deleteIconColor: AppColors.primaryTeal,
                          onDeleted: () =>
                              setState(() => _selectedMeds.remove(med)),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),

            const SizedBox(height: 4),

            // ── Medications List ──
            Expanded(
              child: _isFetchingMeds
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primaryTeal,
                        ),
                      ),
                    )
                  : _buildMedicationList(),
            ),

            // ── Check Button ──
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed:
                      _selectedMeds.length >= 2 && !_isCheckingInteraction
                      ? _checkInteraction
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedMeds.length >= 2
                        ? AppColors.primaryTeal
                        : Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isCheckingInteraction
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _selectedMeds.length >= 2
                              ? context.l10n.t('checkInteractionsCount', {
                                  'count': _selectedMeds.length,
                                })
                              : context.l10n.t('selectAtLeastTwo'),
                          style: TextStyle(
                            color: _selectedMeds.length >= 2
                                ? Colors.white
                                : Colors.grey[500],
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationList() {
    final list = _filtered;

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 56,
              color: AppColors.textGrey.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              context.l10n.t('noResultsFound'),
              style: TextStyle(color: AppColors.textGrey, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final d = list[i];
        final isSelected = _selectedMeds.contains(d);
        final isMaxReached = _selectedMeds.length >= _maxMeds;

        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedMeds.remove(d);
              } else if (!isMaxReached) {
                _selectedMeds.add(d);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      context.l10n.t('selectUpToOnly', {'count': _maxMeds}),
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primaryTeal.withValues(alpha: 0.05)
                  : Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
              border: isSelected
                  ? Border.all(
                      color: AppColors.primaryTeal.withValues(alpha: 0.3),
                      width: 1.5,
                    )
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: d['color'],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(d['icon'], color: d['iconColor'], size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d['name'],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${d['type']} • ${d['form']}',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isSelected ? Icons.check_circle : Icons.add_circle_outline,
                  color: isSelected
                      ? AppColors.primaryTeal
                      : (isMaxReached
                            ? Colors.grey[300]
                            : AppColors.textGrey.withValues(alpha: 0.4)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
