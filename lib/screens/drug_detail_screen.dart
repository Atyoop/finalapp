import 'package:flutter/material.dart';
import '../main.dart';

class DrugDetailScreen extends StatelessWidget {
  final String drugName;
  final String drugCategory;
  final Color drugColor;
  final IconData drugIcon;
  final Color drugIconColor;

  const DrugDetailScreen({
    super.key,
    required this.drugName,
    required this.drugCategory,
    required this.drugColor,
    required this.drugIcon,
    required this.drugIconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        title: Text(
          drugName,
          style: const TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Drug Image/Icon Header
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                color: drugColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: drugIconColor.withOpacity(0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(drugIcon, color: drugIconColor, size: 44),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    drugName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: drugIconColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      drugCategory,
                      style: TextStyle(
                        fontSize: 13,
                        color: drugIconColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Description
            _SectionCard(
              title: "Description",
              icon: Icons.info_outline_rounded,
              child: Text(
                "$drugName is a commonly used $drugCategory medication. It is used to treat various conditions as prescribed by your healthcare provider. Always follow your doctor's instructions regarding dosage and duration.",
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textGrey,
                  height: 1.6,
                ),
              ),
            ),

            // Usage
            _SectionCard(
              title: "Usage",
              icon: Icons.schedule_rounded,
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.access_time,
                    text: "Take as directed by your doctor",
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.restaurant,
                    text: "Can be taken with or without food",
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.water_drop,
                    text: "Take with a full glass of water",
                  ),
                ],
              ),
            ),

            // Side Effects
            _SectionCard(
              title: "Side Effects",
              icon: Icons.warning_amber_rounded,
              child: Column(
                children: [
                  _SideEffectRow("Headache", "Common", const Color(0xFF4CAF50)),
                  _SideEffectRow("Nausea", "Common", const Color(0xFF4CAF50)),
                  _SideEffectRow(
                    "Dizziness",
                    "Uncommon",
                    const Color(0xFFFFA726),
                  ),
                  _SideEffectRow(
                    "Allergic Reaction",
                    "Rare",
                    const Color(0xFFEF5350),
                  ),
                ],
              ),
            ),

            // Interaction Checker Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          _InteractionCheckerScreen(drugName: drugName),
                    ),
                  ),
                  icon: const Icon(
                    Icons.compare_arrows_rounded,
                    color: Colors.white,
                  ),
                  label: const Text(
                    "Drug Interaction Checker",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 3,
                    shadowColor: AppColors.primaryTeal.withOpacity(0.3),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// --- Section Card ---
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryTeal, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// --- Info Row ---
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primaryTeal),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: AppColors.textGrey),
          ),
        ),
      ],
    );
  }
}

// --- Side Effect Row ---
class _SideEffectRow extends StatelessWidget {
  final String name;
  final String severity;
  final Color color;
  const _SideEffectRow(this.name, this.severity, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 14, color: AppColors.textDark),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              severity,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Interaction Checker Screen ---
class _InteractionCheckerScreen extends StatefulWidget {
  final String drugName;
  const _InteractionCheckerScreen({required this.drugName});

  @override
  State<_InteractionCheckerScreen> createState() =>
      _InteractionCheckerScreenState();
}

class _InteractionCheckerScreenState extends State<_InteractionCheckerScreen> {
  final TextEditingController _drugController = TextEditingController();
  bool _showResult = false;

  @override
  void dispose() {
    _drugController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        title: const Text(
          "Drug Interaction Checker",
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
          children: [
            // Warning icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFFF9800),
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Check Drug Interactions",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Enter another drug to check for interactions",
              style: TextStyle(fontSize: 13, color: AppColors.textGrey),
            ),
            const SizedBox(height: 28),

            // Drug 1 (fixed)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primaryTeal.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.medication, color: AppColors.primaryTeal),
                  const SizedBox(width: 12),
                  Text(
                    widget.drugName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Compare icon
            const Icon(
              Icons.compare_arrows_rounded,
              color: AppColors.primaryTeal,
              size: 28,
            ),
            const SizedBox(height: 12),

            // Drug 2 (input)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: _drugController,
                decoration: InputDecoration(
                  hintText: "Enter drug name",
                  hintStyle: TextStyle(color: AppColors.textGrey),
                  prefixIcon: Icon(Icons.search, color: AppColors.textGrey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Check button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  if (_drugController.text.trim().isNotEmpty) {
                    setState(() => _showResult = true);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Text(
                  "Check Interaction",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Result
            if (_showResult)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.warning_rounded,
                      color: Color(0xFFFF9800),
                      size: 36,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Moderate Interaction Found",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Taking ${widget.drugName} with ${_drugController.text.trim()} may increase the risk of side effects. Consult your healthcare provider.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textGrey,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Severity bar
                    Row(
                      children: [
                        const Text("Severity:", style: TextStyle(fontSize: 13)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Container(
                                    height: 10,
                                    color: const Color(0xFF4CAF50),
                                  ),
                                ),
                                Expanded(
                                  flex: 4,
                                  child: Container(
                                    height: 10,
                                    color: const Color(0xFFFFA726),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Container(
                                    height: 10,
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Check Another
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _showResult = false;
                            _drugController.clear();
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primaryTeal),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Text(
                          "Check Another",
                          style: TextStyle(
                            color: AppColors.primaryTeal,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
