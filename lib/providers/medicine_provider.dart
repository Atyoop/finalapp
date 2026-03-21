import 'package:flutter/material.dart';
import '../models/medicine.dart';

class MedicineProvider extends ChangeNotifier {
  final List<Medicine> _medicines = [];

  List<Medicine> get medicines => _medicines;

  void addMedicine(Medicine medicine) {
    _medicines.add(medicine);
    notifyListeners();
  }

  void updateMedicineStatus(String id, MedicineStatus status) {
    final index = _medicines.indexWhere((m) => m.id == id);
    if (index != -1) {
      _medicines[index].status = status;
      notifyListeners();
    }
  }

  // Get medicines for a specific date (simplified for now)
  List<Medicine> getMedicinesForDate(DateTime date) {
    return _medicines.where((m) {
      // Logic to check if date is between start and end date
      // and potentially matches frequency (simplified: just check range)
      return (date.isAfter(m.startDate) || date.isAtSameMomentAs(m.startDate)) &&
          (date.isBefore(m.endDate) || date.isAtSameMomentAs(m.endDate));
    }).toList();
  }
}
