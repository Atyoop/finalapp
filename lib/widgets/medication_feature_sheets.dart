import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';

class ReasonNoteResult {
  final String? reason;
  final String? note;

  const ReasonNoteResult({this.reason, this.note});
}

Future<ReasonNoteResult?> showSkipReasonBottomSheet(BuildContext context) {
  return _showReasonSheet(
    context,
    title: context.l10n.t('whySkippingDose'),
    subtitle: context.l10n.t('skipDoseHelp'),
    confirmLabel: context.l10n.t('confirmSkip'),
    reasons: [
      _ReasonOption(context.l10n.t('forgot'), 'forgot'),
      _ReasonOption(context.l10n.t('busy'), 'busy'),
      _ReasonOption(context.l10n.t('outside'), 'outside'),
      _ReasonOption(context.l10n.t('sideEffects'), 'side_effects'),
      _ReasonOption(context.l10n.t('doctorAdvised'), 'doctor_advised'),
      _ReasonOption(context.l10n.t('feltBetter'), 'felt_better'),
      _ReasonOption(context.l10n.t('other'), 'other'),
    ],
    noteHint: context.l10n.t('addNoteOptional'),
  );
}

Future<ReasonNoteResult?> showTakeNowReasonBottomSheet(BuildContext context) {
  return _showReasonSheet(
    context,
    title: context.l10n.t('takeNow'),
    subtitle: context.l10n.t('takeNowReasonPrompt'),
    confirmLabel: context.l10n.t('recordDose'),
    reasons: [
      _ReasonOption(context.l10n.t('headache'), 'headache'),
      _ReasonOption(context.l10n.t('pain'), 'pain'),
      _ReasonOption(context.l10n.t('fever'), 'fever'),
      _ReasonOption(context.l10n.t('allergy'), 'allergy'),
      _ReasonOption(context.l10n.t('other'), 'other'),
    ],
    noteHint: context.l10n.t('optionalNotes'),
  );
}

Future<int?> showRefillBottomSheet(BuildContext context) async {
  final controller = TextEditingController();
  final result = await showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(context).padding.bottom + 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                context.l10n.t('addRefill'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: context.l10n.t('quantity'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final quantity = int.tryParse(controller.text.trim());
                    if (quantity == null || quantity <= 0) return;
                    Navigator.pop(context, quantity);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(context.l10n.t('saveRefill')),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
  controller.dispose();
  return result;
}

Future<ReasonNoteResult?> _showReasonSheet(
  BuildContext context, {
  required String title,
  required String subtitle,
  required String confirmLabel,
  required List<_ReasonOption> reasons,
  required String noteHint,
}) async {
  final controller = TextEditingController();
  final result = await showModalBottomSheet<ReasonNoteResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      String? selectedReason = reasons.first.value;
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(context).padding.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: reasons.map((option) {
                      final selected = selectedReason == option.value;
                      return ChoiceChip(
                        label: Text(option.label),
                        selected: selected,
                        selectedColor: AppColors.primaryTeal.withValues(
                          alpha: 0.14,
                        ),
                        side: BorderSide(
                          color: selected
                              ? AppColors.primaryTeal
                              : Colors.grey.shade300,
                        ),
                        labelStyle: TextStyle(
                          color: selected
                              ? AppColors.primaryTeal
                              : AppColors.textDark,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                        onSelected: (_) =>
                            setModalState(() => selectedReason = option.value),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: controller,
                    minLines: 2,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: noteHint,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final note = controller.text.trim();
                        Navigator.pop(
                          context,
                          ReasonNoteResult(
                            reason: selectedReason,
                            note: note.isEmpty ? null : note,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(confirmLabel),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
  controller.dispose();
  return result;
}

class _ReasonOption {
  final String label;
  final String value;

  const _ReasonOption(this.label, this.value);
}
