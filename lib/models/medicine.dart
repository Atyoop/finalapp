import 'package:flutter/material.dart';

enum MedicineStatus { scheduled, taken, missed, warning }

class Medicine {
  final String id;
  final String name;
  final String imageUrl;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime deadlineDate;
  final DateTime expiryDate;
  final String frequency; // e.g., "Every 6 Hours, 3 times a day"
  final TimeOfDay time;
  final String doseAmount; // e.g., "1 Tablet"
  final int initialStock;
  final String note;
  MedicineStatus status;

  Medicine({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.startDate,
    required this.endDate,
    required this.deadlineDate,
    required this.expiryDate,
    required this.frequency,
    required this.time,
    required this.doseAmount,
    required this.initialStock,
    this.note = '',
    this.status = MedicineStatus.scheduled,
  });

  Medicine copyWith({
    String? name,
    String? imageUrl,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? deadlineDate,
    DateTime? expiryDate,
    String? frequency,
    TimeOfDay? time,
    String? doseAmount,
    int? initialStock,
    String? note,
    MedicineStatus? status,
  }) {
    return Medicine(
      id: this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      deadlineDate: deadlineDate ?? this.deadlineDate,
      expiryDate: expiryDate ?? this.expiryDate,
      frequency: frequency ?? this.frequency,
      time: time ?? this.time,
      doseAmount: doseAmount ?? this.doseAmount,
      initialStock: initialStock ?? this.initialStock,
      note: note ?? this.note,
      status: status ?? this.status,
    );
  }
}
