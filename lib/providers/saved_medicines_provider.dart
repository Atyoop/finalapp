import 'package:flutter/material.dart';

class SavedMedicinesProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _savedMedicines = [];

  List<Map<String, dynamic>> get savedMedicines => _savedMedicines;

  bool isSaved(String name) {
    return _savedMedicines.any((m) => m['name'] == name);
  }

  void toggleSaved(Map<String, dynamic> medicine) {
    final index = _savedMedicines.indexWhere(
      (m) => m['name'] == medicine['name'],
    );
    if (index >= 0) {
      _savedMedicines.removeAt(index);
    } else {
      _savedMedicines.add(medicine);
    }
    notifyListeners();
  }

  void clear() {
    _savedMedicines.clear();
    notifyListeners();
  }
}
