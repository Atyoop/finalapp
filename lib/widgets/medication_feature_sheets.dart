import 'package:flutter/material.dart';
import '../main.dart';

class ReasonNoteResult {
  final String? reason;
  final String? note;

  const ReasonNoteResult({this.reason, this.note});
}

Future<ReasonNoteResult?> showSkipReasonBottomSheet(BuildContext context) {
  return _showReasonSheet(
    context,
    title: 'Skip dose',
    subtitle: 'Add why this dose was skipped. The note will appear in history.',
    confirmLabel: 'Confirm skip',
    reasons: const [
      _ReasonOption('Forgot', 'forgot'),
      _ReasonOption('Busy', 'busy'),
      _ReasonOption('Outside', 'outside'),
      _ReasonOption('Side effects', 'side_effects'),
      _ReasonOption('Doctor advised', 'doctor_advised'),
      _ReasonOption('Felt better', 'felt_better'),
      _ReasonOption('Other', 'other'),
    ],
    noteHint: 'Optional note',
  );
}

Future<ReasonNoteResult?> showTakeNowReasonBottomSheet(BuildContext context) {
  return _showReasonSheet(
    context,
    title: 'Take now',
    subtitle: 'Record why you are taking this as-needed medication.',
    confirmLabel: 'Record dose',
    reasons: const [
      _ReasonOption('Headache', 'headache'),
      _ReasonOption('Pain', 'pain'),
      _ReasonOption('Fever', 'fever'),
      _ReasonOption('Allergy', 'allergy'),
      _ReasonOption('Other', 'other'),
    ],
    noteHint: 'Optional notes',
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
                'Add refill',
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
                  labelText: 'Quantity',
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
                  child: const Text('Save refill'),
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
