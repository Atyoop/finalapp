import 'package:flutter/material.dart';

/// A compact warning badge indicator for drug interactions.
///
/// Displays a small icon with optional badge count in the top-right corner
/// of medication cards. Indicates when a medication has potential interactions
/// with other drugs.
class InteractionWarningBadge extends StatelessWidget {
  /// Number of interactions detected
  final int interactionCount;

  /// Called when the badge is tapped
  final VoidCallback? onTap;

  const InteractionWarningBadge({
    super.key,
    required this.interactionCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (interactionCount <= 0) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFF9800).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFFF9800).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFFF9800),
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              interactionCount.toString(),
              style: const TextStyle(
                color: Color(0xFFFF9800),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
