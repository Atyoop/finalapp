import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../models/medication_features.dart';
import '../providers/user_provider.dart';
import '../services/user_medications_service.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  late Future<_InsightsData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_InsightsData> _load() async {
    final token = context.read<UserProvider>().token;
    if (token == null || token.isEmpty) {
      throw Exception('Please sign in again.');
    }
    final results = await Future.wait([
      UserMedicationsService.getAdherenceSummary(token),
      UserMedicationsService.getDoseHistory(token),
    ]);
    return _InsightsData(
      summary: results[0] as AdherenceSummaryModel,
      history: results[1] as List<DoseHistoryModel>,
    );
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
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
          'Insights',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<_InsightsData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.primaryTeal),
            );
          }
          if (snapshot.hasError) {
            return _ErrorView(
              message: snapshot.error.toString(),
              onRetry: () => setState(() => _future = _load()),
            );
          }
          final data = snapshot.data!;
          return RefreshIndicator(
            color: AppColors.primaryTeal,
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _SummaryCard(summary: data.summary),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Medication performance',
                  child: data.summary.medications.isEmpty
                      ? _EmptyText('No medication adherence data yet.')
                      : Column(
                          children: data.summary.medications
                              .map(_MedicationPerformanceTile.new)
                              .toList(),
                        ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Dose history',
                  child: data.history.isEmpty
                      ? _EmptyText('No dose history yet.')
                      : Column(
                          children: data.history
                              .take(40)
                              .map(_DoseHistoryTile.new)
                              .toList(),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final AdherenceSummaryModel summary;

  const _SummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final percent = summary.adherenceRate.clamp(0, 100).toStringAsFixed(0);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primaryTeal,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Adherence summary',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$percent%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _MiniStat(label: 'Taken', value: summary.taken),
              _MiniStat(label: 'Skipped', value: summary.skipped),
              _MiniStat(label: 'Missed', value: summary.missed),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final int value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _MedicationPerformanceTile extends StatelessWidget {
  final MedicationAdherenceModel med;

  const _MedicationPerformanceTile(this.med);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              med.medicationName,
              style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '${med.adherenceRate.toStringAsFixed(0)}%',
            style: TextStyle(
              color: AppColors.primaryTeal,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _DoseHistoryTile extends StatelessWidget {
  final DoseHistoryModel item;

  const _DoseHistoryTile(this.item);

  @override
  Widget build(BuildContext context) {
    final date = item.actionAt ?? item.scheduledAt;
    final formatted = date == null
        ? ''
        : DateFormat('MMM d, h:mm a').format(date);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.medicationName,
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                item.status,
                style: TextStyle(
                  color: _statusColor(item.status),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (formatted.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              formatted,
              style: TextStyle(color: AppColors.textGrey, fontSize: 12),
            ),
          ],
          if ((item.reason ?? '').isNotEmpty || (item.note ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                [
                  if ((item.reason ?? '').isNotEmpty) item.reason,
                  if ((item.note ?? '').isNotEmpty) item.note,
                ].join(' - '),
                style: TextStyle(color: AppColors.textGrey, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    final text = status.toLowerCase();
    if (text.contains('take')) return AppColors.primaryTeal;
    if (text.contains('skip')) return Colors.orange;
    if (text.contains('miss')) return Colors.red;
    return AppColors.textGrey;
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insights_outlined, size: 48, color: AppColors.textGrey),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textGrey),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyText extends StatelessWidget {
  final String text;

  const _EmptyText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: TextStyle(color: AppColors.textGrey));
  }
}

class _InsightsData {
  final AdherenceSummaryModel summary;
  final List<DoseHistoryModel> history;

  const _InsightsData({required this.summary, required this.history});
}
