import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import '../models/medication_features.dart';
import '../providers/user_provider.dart';
import '../services/user_medications_service.dart';
import '../utils/quantity_helpers.dart';

class CabinetHealthScreen extends StatefulWidget {
  const CabinetHealthScreen({super.key});

  @override
  State<CabinetHealthScreen> createState() => _CabinetHealthScreenState();
}

class _CabinetHealthScreenState extends State<CabinetHealthScreen> {
  late Future<CabinetHealthModel> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<CabinetHealthModel> _load() {
    final token = context.read<UserProvider>().token;
    if (token == null || token.isEmpty) {
      throw Exception('Please sign in again.');
    }
    return UserMedicationsService.getCabinetHealth(token);
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
          context.l10n.t('myPharmacy'),
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<CabinetHealthModel>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.primaryTeal),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 48,
                      color: AppColors.textGrey,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textGrey),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => setState(() => _future = _load()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(context.l10n.t('retry')),
                    ),
                  ],
                ),
              ),
            );
          }
          final data = snapshot.data!;
          final isEmpty =
              data.expired.isEmpty &&
              data.expiringSoon.isEmpty &&
              data.afterOpeningExpiringSoon.isEmpty &&
              data.lowStock.isEmpty &&
              data.outOfStock.isEmpty &&
              data.runningOutSoon.isEmpty &&
              data.healthy.isEmpty;
          return RefreshIndicator(
            color: AppColors.primaryTeal,
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildSummary(data),
                const SizedBox(height: 16),
                if (isEmpty) _EmptyPharmacyCard(),
                _CabinetSection(
                  title: context.l10n.t('expired'),
                  color: Colors.red,
                  items: data.expired,
                ),
                _CabinetSection(
                  title: context.l10n.t('expiringSoon'),
                  color: Colors.orange,
                  items: data.expiringSoon,
                ),
                _CabinetSection(
                  title: context.l10n.t('afterOpeningWarnings'),
                  color: Colors.orange,
                  items: data.afterOpeningExpiringSoon,
                ),
                _CabinetSection(
                  title: context.l10n.t('outOfStock'),
                  color: Colors.red,
                  items: data.outOfStock,
                ),
                _CabinetSection(
                  title: context.l10n.t('lowStock'),
                  color: Colors.orange,
                  items: data.lowStock,
                ),
                _CabinetSection(
                  title: context.l10n.t('runningOutSoon'),
                  color: Colors.orange,
                  items: data.runningOutSoon,
                ),
                _CabinetSection(
                  title: context.l10n.t('healthy'),
                  color: AppColors.primaryTeal,
                  items: data.healthy,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummary(CabinetHealthModel data) {
    return Container(
      padding: const EdgeInsets.all(18),
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
            child: Icon(Icons.health_and_safety, color: AppColors.primaryTeal),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.attentionCount == 0
                      ? context.l10n.t('cabinetLooksHealthy')
                      : context.l10n.t('itemsNeedAttention', {
                          'count': data.attentionCount,
                        }),
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.t('healthyMedicationCount', {
                    'count': data.healthy.length,
                  }),
                  style: TextStyle(color: AppColors.textGrey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CabinetSection extends StatelessWidget {
  final String title;
  final Color color;
  final List<CabinetMedicationModel> items;

  const _CabinetSection({
    required this.title,
    required this.color,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                '$title (${items.length})',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => _CabinetMedicationTile(item: item, color: color),
          ),
        ],
      ),
    );
  }
}

class _CabinetMedicationTile extends StatelessWidget {
  final CabinetMedicationModel item;
  final Color color;

  const _CabinetMedicationTile({required this.item, required this.color});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final expiry = item.effectiveExpiryDate == null
        ? null
        : DateFormat('MMM d, yyyy', locale).format(item.effectiveExpiryDate!);
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
              if ((item.status ?? '').isNotEmpty)
                Text(
                  _localizedStatus(context, item.status!),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            [
              if (item.currentQuantity != null)
                formatQuantityWithUnit(item.currentQuantity, item.quantityUnit),
              if (item.daysUntilEmpty != null)
                context.l10n.t('runsOutInDays', {'count': item.daysUntilEmpty}),
              if (expiry != null) context.l10n.t('expiresOn', {'date': expiry}),
              if (item.daysUntilExpiry != null)
                context.l10n.t('daysToExpiry', {'count': item.daysUntilExpiry}),
            ].join(' - '),
            style: TextStyle(color: AppColors.textGrey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _localizedStatus(BuildContext context, String status) {
    final normalized = status
        .trim()
        .toLowerCase()
        .replaceAll('_', ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.contains('stock is low')) {
      return context.l10n.t('medicationStockIsLow');
    }
    if (normalized.contains('expires within 7 days')) {
      return context.l10n.t('medicationExpiresWithinSevenDays');
    }
    if (normalized.contains('opened medication expires soon')) {
      return context.l10n.t('openedMedicationExpiresSoon');
    }
    if (normalized.contains('out of stock')) {
      return context.l10n.t('outOfStock');
    }
    if (normalized.contains('low stock')) return context.l10n.t('lowStock');
    if (normalized.contains('running out')) {
      return context.l10n.t('runningOutSoon');
    }
    if (normalized.contains('expiring')) return context.l10n.t('expiringSoon');
    if (normalized.contains('expired')) return context.l10n.t('expired');
    if (normalized.contains('healthy')) return context.l10n.t('healthy');
    return Localizations.localeOf(context).languageCode == 'ar'
        ? context.l10n.t('needsAttention')
        : status;
  }
}

class _EmptyPharmacyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(
            Icons.medication_outlined,
            size: 42,
            color: AppColors.textGrey.withValues(alpha: 0.55),
          ),
          const SizedBox(height: 10),
          Text(
            context.l10n.t('noMedicationsInPharmacy'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.t('addMedicationToSeeHere'),
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textGrey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
