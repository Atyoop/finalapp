import 'package:final88/models/medicine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('custom injection uses the backend-compatible ampoule unit', () {
    final now = DateTime(2026, 6, 15);
    final medicine = Medicine(
      name: 'Custom injection',
      startDate: now,
      endDate: now.add(const Duration(days: 30)),
      deadlineDate: now,
      expiryDate: now.add(const Duration(days: 365)),
      frequency: 'Once daily',
      time: const TimeOfDay(hour: 8, minute: 0),
      doseAmount: '1 ampoule',
      initialStock: 5,
      dosageForm: 'Injection',
      quantityUnit: 'unit',
      initialQuantity: 5,
      currentQuantity: 5,
      doseQuantity: 1,
      isCustomMedication: true,
    );

    expect(medicine.toJson()['quantityUnit'], 'ampoule');
  });
}
