import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../main.dart';

class PasswordRules {
  const PasswordRules._();

  static bool hasMinLength(String password) => password.length >= 8;

  static bool hasMinNumbers(String password) =>
      RegExp(r'[0-9]').allMatches(password).length >= 2;

  static bool hasUppercase(String password) =>
      RegExp(r'[A-Z]').hasMatch(password);

  static bool isValid(String password) =>
      hasMinLength(password) &&
      hasMinNumbers(password) &&
      hasUppercase(password);
}

class PasswordRequirements extends StatelessWidget {
  const PasswordRequirements({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _RequirementRow(
          label: context.l10n.t('min8Characters'),
          isMet: PasswordRules.hasMinLength(password),
        ),
        _RequirementRow(
          label: context.l10n.t('min2Numbers'),
          isMet: PasswordRules.hasMinNumbers(password),
        ),
        _RequirementRow(
          label: context.l10n.t('min1Uppercase'),
          isMet: PasswordRules.hasUppercase(password),
        ),
      ],
    );
  }
}

class _RequirementRow extends StatelessWidget {
  const _RequirementRow({required this.label, required this.isMet});

  final String label;
  final bool isMet;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check : Icons.circle,
          size: 16,
          color: isMet ? AppColors.primaryTeal : Colors.grey,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(color: isMet ? AppColors.primaryTeal : Colors.grey),
        ),
      ],
    );
  }
}
