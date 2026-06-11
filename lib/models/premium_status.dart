class PremiumStatus {
  final bool isActive;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? planType;
  final int? _remainingDays;

  PremiumStatus({
    required this.isActive,
    this.startDate,
    this.endDate,
    this.planType,
    int? remainingDays,
  }) : _remainingDays = remainingDays;

  /// Calculate remaining days or return the one from backend
  int get remainingDays {
    if (_remainingDays != null) return _remainingDays;
    if (!isActive || endDate == null) return 0;
    return endDate!.difference(DateTime.now()).inDays + 1;
  }

  /// Parse from JSON response
  factory PremiumStatus.fromJson(Map<String, dynamic> json) {
    return PremiumStatus(
      isActive: (json['isPremium'] ?? json['isActive']) as bool? ?? false,
      startDate: (json['premiumStartDate'] ?? json['startDate']) != null
          ? DateTime.tryParse((json['premiumStartDate'] ?? json['startDate']) as String)
          : null,
      endDate: (json['premiumEndDate'] ?? json['endDate']) != null
          ? DateTime.tryParse((json['premiumEndDate'] ?? json['endDate']) as String)
          : null,
      planType: json['planType'] as String?,
      remainingDays: json['remainingDays'] as int?,
    );
  }


  @override
  String toString() =>
      'PremiumStatus(isActive: $isActive, planType: $planType, remainingDays: $remainingDays)';
}
