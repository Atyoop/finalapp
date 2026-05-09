import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../services/user_medications_service.dart';

class MedicineProvider extends ChangeNotifier {
  final List<Medicine> _medicines = [];
  bool _isLoading = false;
  String? _error;

  List<Medicine> get medicines => _medicines;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ─── Local-only methods (keep for offline fallback) ───

  void addMedicine(Medicine medicine) {
    _medicines.add(medicine);
    notifyListeners();
  }

  void updateMedicine(Medicine updated) {
    final index = _medicines.indexWhere((m) => m.id == updated.id);
    if (index != -1) {
      _medicines[index] = updated;
      notifyListeners();
    }
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
      return (date.isAfter(m.startDate) ||
              date.isAtSameMomentAs(m.startDate)) &&
          (date.isBefore(m.endDate) || date.isAtSameMomentAs(m.endDate));
    }).toList();
  }

  void removeMedicine(String id) {
    final index = _medicines.indexWhere((m) => m.id == id);
    if (index != -1) {
      _medicines.removeAt(index);
      notifyListeners();
    }
  }

  // ─── API-backed methods ───

  /// Fetch all medications from the server
  Future<void> fetchMedicinesFromApi(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final list = await UserMedicationsService.fetchAll(token);
      _medicines.clear();
      _medicines.addAll(list);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a medication on the server.
  /// Returns [AddMedicineResponse] on success (which may include interaction
  /// warnings), or null on failure (check [error] for the message).
  /// The caller is responsible for calling [fetchMedicinesFromApi] afterward.
  Future<AddMedicineResponse?> addMedicineToApi(
    String token,
    Medicine medicine,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await UserMedicationsService.create(token, medicine);
      _error = null;
      return response;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ addMedicineToApi error: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update a medication on the server and locally
  Future<bool> updateMedicineOnApi(String token, Medicine medicine) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await UserMedicationsService.update(token, medicine);
      final index = _medicines.indexWhere((m) => m.id == updated.id);
      if (index != -1) {
        _medicines[index] = updated;
      }
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Delete a medication from the server and locally
  Future<bool> deleteMedicineFromApi(String token, String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await UserMedicationsService.delete(token, id);
      _medicines.removeWhere((m) => m.id == id);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Delete all user medications on the server and clear local list
  Future<bool> deleteAllFromApi(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await UserMedicationsService.deleteMyUserMeds(token);
      _medicines.clear();
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
