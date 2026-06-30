import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../providers/language_provider.dart';
import '../services/medications_service.dart';
import 'drug_detail_screen.dart';

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

  List<Map<String, dynamic>> _drugs = [];

  bool _isFetchingMeds = false;
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
    setState(() {
      _isFetchingMeds = true;
    });
    try {
      final data = await MedicationsService.fetchAllMeds();
      final List<Map<String, dynamic>> meds = data.map((j) {
        // name
        final String name = (j['trade_name'] ?? '').toString();

        // form
        final String form = (j['dosage_Form'] ?? '').toString();

        // type: first ingredient name, fallback to 'Medication'
        String type = '';
        final ingredients = j['ingredients'];
        if (ingredients is List && ingredients.isNotEmpty) {
          type = (ingredients.first['ingredientName'] ?? '').toString();
        }
        if (type.isEmpty) type = 'Medication';

        // strength: first ingredient strength_value + strength_unit
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

      setState(() {
        _drugs = meds;
      });
    } catch (_) {
      // show empty state on error
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingMeds = false;
        });
      }
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
              padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Text(
                "Check Meds",
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
                "Find medications or check a pill",
                style: TextStyle(fontSize: 14, color: AppColors.textGrey),
              ),
            ),
            // Search bar
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
                          hintText: "Type medication name...",
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
                          builder: (_) => const ScanCameraScreen(),
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
            const SizedBox(height: 20),

            Expanded(
              child: _isFetchingMeds
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primaryTeal,
                        ),
                      ),
                    )
                  : (_query.isNotEmpty
                        ? _buildSearchResults()
                        : _buildEmptySearch()), // ← changed from _buildAllMeds()
            ),

            // Check Interactions button
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _selectedMeds.length >= 2 ? () {} : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedMeds.length >= 2
                        ? AppColors.primaryTeal
                        : Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    "Check Interactions",
                    style: TextStyle(
                      color: _selectedMeds.length >= 2
                          ? Colors.white
                          : Colors.grey[500],
                      fontSize: 16,
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

  Widget _buildEmptySearch() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_rounded,
            size: 64,
            color: AppColors.textGrey.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            "Search for a medication",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Type a medication name above\nto see results.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_filtered.isEmpty) {
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
              "No results found",
              style: TextStyle(color: AppColors.textGrey, fontSize: 15),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _filtered.length,
      itemBuilder: (context, i) {
        final d = _filtered[i];
        final isSelected = _selectedMeds.contains(d);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedMeds.remove(d);
              } else {
                _selectedMeds.add(d);
              }
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
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
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: d['color'],
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(d['icon'], color: d['iconColor'], size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d['name'],
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${d['type']} • ${d['form']}",
                        style: TextStyle(
                          fontSize: 12,
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
                      : AppColors.textGrey.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// =============================================================================
// SCAN CAMERA SCREEN — simulated camera scanner with overlay
// =============================================================================
class ScanCameraScreen extends StatefulWidget {
  const ScanCameraScreen({super.key});
  @override
  State<ScanCameraScreen> createState() => _ScanCameraScreenState();
}

class _ScanCameraScreenState extends State<ScanCameraScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  bool _showResult = false;
  late AnimationController _animController;
  late Animation<double> _lineAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _lineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _simulateScan() {
    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _showResult = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showResult) return _buildResultScreen();
    if (_isLoading) return _buildLoadingScreen();
    return _buildScannerScreen();
  }

  Widget _buildScannerScreen() {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Scan Medication',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const Spacer(),
          const Text(
            'Place the pill or\nbarcode in the frame',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 32),

          // Scanner Frame
          Center(
            child: SizedBox(
              width: 260,
              height: 260,
              child: Stack(
                children: [
                  _buildCorner(Alignment.topLeft),
                  _buildCorner(Alignment.topRight),
                  _buildCorner(Alignment.bottomLeft),
                  _buildCorner(Alignment.bottomRight),

                  AnimatedBuilder(
                    animation: _lineAnimation,
                    builder: (context, child) {
                      return Positioned(
                        top: _lineAnimation.value * 240 + 10,
                        left: 10,
                        right: 10,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                AppColors.primaryTeal.withValues(alpha: 0.8),
                                const Color(0xFF3A9EA5),
                                AppColors.primaryTeal.withValues(alpha: 0.8),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  Center(
                    child: Icon(
                      Icons.medication_rounded,
                      size: 80,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),

          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _simulateScan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Text(
                  'Capture & Identify',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryTeal,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Identifying...',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Analyzing the medication',
              style: TextStyle(fontSize: 14, color: AppColors.textGrey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultScreen() {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textDark),
        title: Text(
          'Scan Result',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(
                      Icons.check_circle_outline,
                      color: Color(0xFF4CAF50),
                      size: 44,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Pill Identified!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We found a match for your medication',
                    style: TextStyle(fontSize: 14, color: AppColors.textGrey),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  _ResultRow('Name', 'Amoxicillin'),
                  _ResultRow('Category', 'Antibiotic'),
                  _ResultRow('Form', 'Capsule • 500mg'),
                  _ResultRow('Manufacturer', 'PharmaCorp'),
                ],
              ),
            ),
            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DrugDetailScreen(
                        drugName: 'Amoxicillin',
                        drugCategory: 'Antibiotic',
                        drugColor: const Color(0xFFE8F5E9),
                        drugIcon: Icons.medication,
                        drugIconColor: const Color(0xFF4CAF50),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 3,
                  shadowColor: AppColors.primaryTeal.withValues(alpha: 0.3),
                ),
                child: const Text(
                  'View Full Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = false;
                    _showResult = false;
                  });
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.primaryTeal),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: Text(
                  'Scan Another',
                  style: TextStyle(
                    color: AppColors.primaryTeal,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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

  Widget _buildCorner(Alignment alignment) {
    final isTop =
        alignment == Alignment.topLeft || alignment == Alignment.topRight;
    final isLeft =
        alignment == Alignment.topLeft || alignment == Alignment.bottomLeft;

    return Positioned(
      top: isTop ? 0 : null,
      bottom: isTop ? null : 0,
      left: isLeft ? 0 : null,
      right: isLeft ? null : 0,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border(
            top: isTop
                ? BorderSide(color: AppColors.primaryTeal, width: 3)
                : BorderSide.none,
            bottom: !isTop
                ? BorderSide(color: AppColors.primaryTeal, width: 3)
                : BorderSide.none,
            left: isLeft
                ? BorderSide(color: AppColors.primaryTeal, width: 3)
                : BorderSide.none,
            right: !isLeft
                ? BorderSide(color: AppColors.primaryTeal, width: 3)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}

// --- Result Row ---
class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  const _ResultRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: AppColors.textGrey),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
