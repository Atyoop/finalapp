import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';
import '../main.dart';
import '../models/medication_features.dart';
import '../providers/language_provider.dart';
import '../providers/user_provider.dart';
import '../services/user_medications_service.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  late Future<_InsightsData> _future;
  _InsightDateRangeOption _selectedRange = _InsightDateRangeOption.last7Days;
  DateTimeRange? _customRange;

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
    final range = _resolvedDateRange;
    final results = await Future.wait([
      UserMedicationsService.getAdherenceSummary(
        token,
        from: range.start,
        to: range.end,
      ),
      UserMedicationsService.getDoseHistory(
        token,
        from: range.start,
        to: range.end,
      ),
    ]);
    final filteredHistory = _filterHistoryByRange(
      results[1] as List<DoseHistoryModel>,
      range,
    );
    return _InsightsData(
      summary: _buildSummaryFromHistory(filteredHistory),
      history: filteredHistory,
    );
  }

  List<DoseHistoryModel> _filterHistoryByRange(
    List<DoseHistoryModel> history,
    DateTimeRange range,
  ) {
    return history.where((item) {
      final date = item.actionAt ?? item.scheduledAt;
      if (date == null) return false;
      return !date.isBefore(range.start) && !date.isAfter(range.end);
    }).toList();
  }

  AdherenceSummaryModel _buildSummaryFromHistory(List<DoseHistoryModel> history) {
    final medicationGroups = <String, List<DoseHistoryModel>>{};
    for (final item in history) {
      final key = item.userMedicationId?.toString() ?? item.medicationName;
      medicationGroups.putIfAbsent(key, () => <DoseHistoryModel>[]).add(item);
    }

    final medications = medicationGroups.values.map((items) {
      final first = items.first;
      final counts = _statusCounts(items);
      final total = counts.taken + counts.skipped + counts.missed;
      return MedicationAdherenceModel(
        userMedicationId: first.userMedicationId,
        medicationName: first.medicationName,
        taken: counts.taken,
        skipped: counts.skipped,
        missed: counts.missed,
        total: total,
        adherenceRate: total == 0 ? 0 : (counts.taken / total) * 100,
      );
    }).toList()
      ..sort((a, b) => a.medicationName.compareTo(b.medicationName));

    final counts = _statusCounts(history);
    final total = counts.taken + counts.skipped + counts.missed;
    return AdherenceSummaryModel(
      taken: counts.taken,
      skipped: counts.skipped,
      missed: counts.missed,
      total: total,
      adherenceRate: total == 0 ? 0 : (counts.taken / total) * 100,
      medications: medications,
    );
  }

  _DoseStatusCounts _statusCounts(List<DoseHistoryModel> items) {
    var taken = 0;
    var skipped = 0;
    var missed = 0;

    for (final item in items) {
      final status = item.status.toLowerCase();
      if (status.contains('take')) {
        taken++;
      } else if (status.contains('skip')) {
        skipped++;
      } else if (status.contains('miss')) {
        missed++;
      }
    }

    return _DoseStatusCounts(taken: taken, skipped: skipped, missed: missed);
  }

  DateTimeRange get _resolvedDateRange {
    if (_selectedRange == _InsightDateRangeOption.custom &&
        _customRange != null) {
      return _wholeDayRange(_customRange!.start, _customRange!.end);
    }

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = _endOfDay(todayStart);

    return switch (_selectedRange) {
      _InsightDateRangeOption.last7Days => DateTimeRange(
        start: todayStart.subtract(const Duration(days: 6)),
        end: todayEnd,
      ),
      _InsightDateRangeOption.last30Days => DateTimeRange(
        start: todayStart.subtract(const Duration(days: 29)),
        end: todayEnd,
      ),
      _InsightDateRangeOption.last3Months => DateTimeRange(
        start: DateTime(todayStart.year, todayStart.month - 3, todayStart.day),
        end: todayEnd,
      ),
      _InsightDateRangeOption.lastYear => DateTimeRange(
        start: DateTime(todayStart.year - 1, todayStart.month, todayStart.day),
        end: todayEnd,
      ),
      _InsightDateRangeOption.custom => DateTimeRange(
        start: todayStart.subtract(const Duration(days: 6)),
        end: todayEnd,
      ),
    };
  }

  DateTimeRange _wholeDayRange(DateTime start, DateTime end) {
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    return DateTimeRange(start: startDay, end: _endOfDay(endDay));
  }

  DateTime _endOfDay(DateTime day) {
    return DateTime(day.year, day.month, day.day, 23, 59, 59, 999);
  }

  DateTimeRange get _pickerInitialRange {
    final range = _customRange ?? _resolvedDateRange;
    return DateTimeRange(
      start: DateUtils.dateOnly(range.start),
      end: DateUtils.dateOnly(range.end),
    );
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _selectRange(_InsightDateRangeOption option) async {
    if (option == _InsightDateRangeOption.custom) {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateUtils.dateOnly(DateTime.now()),
        initialDateRange: _pickerInitialRange,
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.primaryTeal,
                onPrimary: Colors.white,
              ),
            ),
            child: child!,
          );
        },
      );
      if (picked == null || !mounted) return;
      setState(() {
        _selectedRange = option;
        _customRange = picked;
        _future = _load();
      });
      return;
    }

    setState(() {
      _selectedRange = option;
      _future = _load();
    });
  }

  String _text(String en, String ar) {
    return context.read<LanguageProvider>().isArabic ? ar : en;
  }

  String _rangeLabel(_InsightDateRangeOption option) {
    final isAr = context.read<LanguageProvider>().isArabic;
    return switch (option) {
      _InsightDateRangeOption.last7Days => isAr ? 'آخر 7 أيام' : 'Last 7 days',
      _InsightDateRangeOption.last30Days =>
        isAr ? 'آخر 30 يومًا' : 'Last 30 days',
      _InsightDateRangeOption.last3Months =>
        isAr ? 'آخر 3 أشهر' : 'Last 3 months',
      _InsightDateRangeOption.lastYear => isAr ? 'آخر سنة' : 'Last year',
      _InsightDateRangeOption.custom => isAr ? 'نطاق مخصص' : 'Custom range',
    };
  }

  String _rangeSubtitle() {
    final locale = context.read<LanguageProvider>().currentLanguage;
    final range = _resolvedDateRange;
    final formatter = intl.DateFormat('MMM d, yyyy', locale);
    return '${formatter.format(range.start)} - ${formatter.format(range.end)}';
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<LanguageProvider>().isArabic;
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textDark),
        title: Text(
          _text('Insights', 'التحليلات'),
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: FutureBuilder<_InsightsData>(
          future: _future,
          builder: (context, snapshot) {
            return RefreshIndicator(
              color: AppColors.primaryTeal,
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  _DateRangeFilterCard(
                    title: _text('Analysis period', 'فترة التحليل'),
                    label: _rangeLabel(_selectedRange),
                    subtitle: _rangeSubtitle(),
                    options: _InsightDateRangeOption.values,
                    optionLabel: _rangeLabel,
                    onSelected: _selectRange,
                  ),
                  const SizedBox(height: 16),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    _LoadingCard(
                      message: _text(
                        'Loading insights...',
                        'جاري تحميل التحليلات...',
                      ),
                    )
                  else if (snapshot.hasError)
                    _ErrorView(
                      message: snapshot.error.toString(),
                      onRetry: () => setState(() => _future = _load()),
                    )
                  else
                    ..._buildInsightsContent(snapshot.data!),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildInsightsContent(_InsightsData data) {
    final emptyMessage = _text(
      'No medication activity found for this period.',
      'لا يوجد نشاط دوائي في هذه الفترة.',
    );
    final hasAnyActivity = data.summary.total > 0 || data.history.isNotEmpty;

    return [
      if (!hasAnyActivity) ...[
        _EmptyStateCard(message: emptyMessage),
        const SizedBox(height: 16),
      ],
      _SummaryCard(
        summary: data.summary,
        title: _text('Adherence summary', 'ملخص الالتزام'),
        takenLabel: _text('Taken', 'تم تناولها'),
        skippedLabel: _text('Skipped', 'تم تخطيها'),
        missedLabel: _text('Missed', 'فائتة'),
      ),
      const SizedBox(height: 16),
      _SectionCard(
        title: _text('Medication performance', 'أداء الأدوية'),
        child: data.summary.medications.isEmpty ||
                data.summary.medications.every((med) => med.total == 0)
            ? _EmptyText(emptyMessage)
            : Column(
                children: data.summary.medications
                    .where((med) => med.total > 0)
                    .map(_MedicationPerformanceTile.new)
                    .toList(),
              ),
      ),
      const SizedBox(height: 16),
      _DoseHistorySection(
        title: _text('Dose History', 'سجل الجرعات'),
        emptyMessage: emptyMessage,
        history: data.history,
      ),
    ];
  }
}

class _SummaryCard extends StatelessWidget {
  final AdherenceSummaryModel summary;
  final String title;
  final String takenLabel;
  final String skippedLabel;
  final String missedLabel;

  const _SummaryCard({
    required this.summary,
    required this.title,
    required this.takenLabel,
    required this.skippedLabel,
    required this.missedLabel,
  });

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
          Text(
            title,
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
              _MiniStat(label: takenLabel, value: summary.taken),
              _MiniStat(label: skippedLabel, value: summary.skipped),
              _MiniStat(label: missedLabel, value: summary.missed),
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

class _DateRangeFilterCard extends StatelessWidget {
  final String title;
  final String label;
  final String subtitle;
  final List<_InsightDateRangeOption> options;
  final String Function(_InsightDateRangeOption option) optionLabel;
  final ValueChanged<_InsightDateRangeOption> onSelected;

  const _DateRangeFilterCard({
    required this.title,
    required this.label,
    required this.subtitle,
    required this.options,
    required this.optionLabel,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: AppColors.primaryTeal.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.date_range_rounded,
              color: AppColors.primaryTeal,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<_InsightDateRangeOption>(
            onSelected: onSelected,
            itemBuilder: (context) => options
                .map(
                  (option) => PopupMenuItem(
                    value: option,
                    child: Text(optionLabel(option)),
                  ),
                )
                .toList(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.primaryTeal,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
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

class _DoseHistorySection extends StatelessWidget {
  final String title;
  final String emptyMessage;
  final List<DoseHistoryModel> history;

  const _DoseHistorySection({
    required this.title,
    required this.emptyMessage,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          iconColor: AppColors.primaryTeal,
          collapsedIconColor: AppColors.primaryTeal,
          title: Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          children: [
            history.isEmpty
                ? Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: _EmptyText(emptyMessage),
                  )
                : Column(
                    children: history
                        .take(40)
                        .map(_DoseHistoryTile.new)
                        .toList(),
                  ),
          ],
        ),
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
        : intl.DateFormat('MMM d, h:mm a').format(date);
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

class _LoadingCard extends StatelessWidget {
  final String message;

  const _LoadingCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          CircularProgressIndicator(color: AppColors.primaryTeal),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: AppColors.textGrey)),
        ],
      ),
    );
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

class _EmptyStateCard extends StatelessWidget {
  final String message;

  const _EmptyStateCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryTeal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: AppColors.textDark,
          fontWeight: FontWeight.w600,
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

class _DoseStatusCounts {
  final int taken;
  final int skipped;
  final int missed;

  const _DoseStatusCounts({
    required this.taken,
    required this.skipped,
    required this.missed,
  });
}

enum _InsightDateRangeOption {
  last7Days,
  last30Days,
  last3Months,
  lastYear,
  custom,
}
