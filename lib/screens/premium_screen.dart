import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import '../providers/premium_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/premium_plan_card.dart';
import 'fake_payment_screen.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  String _selectedPlan = 'Month'; // Month, ThreeMonths, Year
  bool _showPlansForRenewal = false;

  final Map<String, Map<String, String>> _plans = {
    'Month': {
      'title': 'Monthly Plan',
      'price': '99 EGP',
      'description': 'Billed every month',
      'apiPlan': 'Month',
    },
    'ThreeMonths': {
      'title': '3 Months Plan',
      'price': '229 EGP',
      'description': 'Best value for regular users',
      'apiPlan': 'ThreeMonths',
    },
    'Year': {
      'title': 'Yearly Plan',
      'price': '799 EGP',
      'description': 'Full premium access for one year',
      'apiPlan': 'Year',
    },
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPremiumStatus();
    });
  }

  void _loadPremiumStatus() {
    final premiumProvider = context.read<PremiumProvider>();
    final userProvider = context.read<UserProvider>();
    if (userProvider.token != null) {
      premiumProvider.fetchPremiumStatus(userProvider.token!);
    }
  }

  Future<void> _proceedToPayment() async {
    final userProvider = context.read<UserProvider>();
    final premiumProvider = context.read<PremiumProvider>();

    if (userProvider.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.t('authenticationRequired'))),
      );
      return;
    }

    final planInfo = _plans[_selectedPlan]!;

    if (mounted) {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => FakePaymentScreen(
            planName: planInfo['title']!,
            price: planInfo['price']!,
            onPaymentConfirmed: () async {
              // Call activation API
              final success = await premiumProvider.activatePremium(
                token: userProvider.token!,
                plan: _selectedPlan,
              );

              if (success && mounted) {
                setState(() {
                  _showPlansForRenewal = false;
                });
                _showSuccessDialog(premiumProvider);
              }
            },
          ),
        ),
      );

      if (result == true && mounted) {
        _loadPremiumStatus();
      }
    }
  }

  void _showSuccessDialog(PremiumProvider premiumProvider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                size: 50,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.t('premiumUpdated'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.t('premiumRenewedSuccess'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textGrey),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  context.l10n.t('done'),
                  style: const TextStyle(
                    color: Colors.white,
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

  Future<void> _cancelPremium() async {
    final userProvider = context.read<UserProvider>();
    final premiumProvider = context.read<PremiumProvider>();

    if (userProvider.token == null) return;

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          context.l10n.t('cancelPremiumQuestion'),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        content: Text(
          context.l10n.t('cancelPremiumConfirm'),
          style: TextStyle(fontSize: 14, color: AppColors.textDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              context.l10n.t('keepPremium'),
              style: TextStyle(color: AppColors.primaryTeal),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await premiumProvider.cancelPremium(
                userProvider.token!,
              );
              if (success && mounted) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.l10n.t('subscriptionCancelled')),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
                _loadPremiumStatus();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              context.l10n.t('cancelSubscription'),
              style: const TextStyle(color: Colors.white),
            ),
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
          icon: Icon(
            _showPlansForRenewal ? Icons.close : Icons.arrow_back,
            color: AppColors.textDark,
          ),
          onPressed: () {
            if (_showPlansForRenewal) {
              setState(() => _showPlansForRenewal = false);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Consumer2<PremiumProvider, UserProvider>(
        builder: (context, premiumProvider, userProvider, child) {
          if (premiumProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (premiumProvider.error != null && premiumProvider.status == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.t('failedLoadPremium'),
                    style: TextStyle(color: AppColors.textDark),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _loadPremiumStatus,
                    child: Text(context.l10n.t('retry')),
                  ),
                ],
              ),
            );
          }

          final isPremium = premiumProvider.isPremiumActive;

          if (isPremium && !_showPlansForRenewal) {
            return _buildStatusView(premiumProvider);
          } else {
            return _buildPlansView(premiumProvider);
          }
        },
      ),
    );
  }

  Widget _buildStatusView(PremiumProvider premiumProvider) {
    final status = premiumProvider.status;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Top Section
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.workspace_premium,
                    size: 80,
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  context.l10n.t('drugSafePremium'),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.t('premiumEnjoying'),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: AppColors.textGrey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Subscription details card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  context.l10n.t('premiumStatus'),
                  context.l10n.t('active'),
                  valueColor: Colors.green,
                ),
                const Divider(height: 24),
                if (status?.startDate != null) ...[
                  _buildInfoRow(
                    context.l10n.t('startDate'),
                    _formatDate(status!.startDate!),
                  ),
                  const Divider(height: 24),
                ],
                if (status?.endDate != null) ...[
                  _buildInfoRow(
                    context.l10n.t('endDate'),
                    _formatDate(status!.endDate!),
                  ),
                  const Divider(height: 24),
                  _buildInfoRow(
                    context.l10n.t('remainingDays'),
                    context.l10n.t('daysCount', {
                      'count': premiumProvider.remainingDays,
                    }),
                    valueColor: AppColors.primaryTeal,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Buttons section
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => setState(() => _showPlansForRenewal = true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                context.l10n.t('renewSubscription'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: _cancelPremium,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                context.l10n.t('cancelSubscription'),
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlansView(PremiumProvider premiumProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _showPlansForRenewal
                ? context.l10n.t('renewYourPremium')
                : context.l10n.t('drugSafePremium'),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.t('premiumDescription'),
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textGrey,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            context.l10n.t('chooseYourPlan'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          ..._plans.entries.map((entry) {
            final key = entry.key;
            final plan = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PremiumPlanCard(
                title: _planTitle(key),
                price: plan['price']!,
                description: _planDescription(key),
                isSelected: _selectedPlan == key,
                onTap: () => setState(() => _selectedPlan = key),
              ),
            );
          }),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: premiumProvider.isActivating
                  ? null
                  : _proceedToPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                disabledBackgroundColor: Colors.grey[400],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: premiumProvider.isActivating
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      _showPlansForRenewal
                          ? context.l10n.t('renewNow')
                          : context.l10n.t('goWithoutAds'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: AppColors.textGrey, fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppColors.textDark,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _planTitle(String key) {
    return switch (key) {
      'Month' => context.l10n.t('monthlyPlan'),
      'ThreeMonths' => context.l10n.t('threeMonthsPlan'),
      'Year' => context.l10n.t('yearlyPlan'),
      _ => key,
    };
  }

  String _planDescription(String key) {
    return switch (key) {
      'Month' => context.l10n.t('billedMonthly'),
      'ThreeMonths' => context.l10n.t('bestValueRegular'),
      'Year' => context.l10n.t('fullPremiumYear'),
      _ => '',
    };
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
