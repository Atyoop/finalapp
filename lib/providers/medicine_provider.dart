import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../services/user_medications_service.dart';
import '../services/medicine_storage_service.dart';

class MedicineProvider extends ChangeNotifier {
  List<Medicine> _medicines = [];
  bool _isLoading = false;
  String? _error;
  bool _loadedFromLocal = false;
  void Function(String token)? onMedicationChanged;

  List<Medicine> get medicines => _medicines;
  bool get isLoading => _isLoading;
  String? get error => _error;

  MedicineProvider() {
    loadFromLocal();
  }

  // ─── Local database methods ───

  /// Load medicines from local Hive storage (instant, works offline)
  void loadFromLocal() {
    try {
      _medicines = MedicineStorageService.getAllMedicines();
      _loadedFromLocal = true;
      debugPrint(
        '[MedicineProvider] 📂 Loaded ${_medicines.length} from local',
      );
      notifyListeners();
    } catch (e) {
      debugPrint('[MedicineProvider] ❌ Local load error: $e');
    }
  }

  /// Search medicines locally
  List<Medicine> searchMedicines(String query) {
    return MedicineStorageService.searchMedicines(query);
  }

  /// Update stock locally
  Future<bool> updateStockLocally(String id, int newCount) async {
    final ok = await MedicineStorageService.updateStock(id, newCount);
    if (ok) {
      final index = _medicines.indexWhere((m) => m.id == id);
      if (index != -1) {
        _medicines[index] =
            MedicineStorageService.getMedicine(id) ?? _medicines[index];
        notifyListeners();
      }
    }
    return ok;
  }

  // ─── Local-only methods ───

  void addMedicine(Medicine medicine) {
    _medicines.add(medicine);
    MedicineStorageService.saveMedicine(medicine);
    notifyListeners();
  }

  void updateMedicine(Medicine updated) {
    final index = _medicines.indexWhere((m) => m.id == updated.id);
    if (index != -1) {
      _medicines[index] = updated;
      MedicineStorageService.saveMedicine(updated);
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

  List<Medicine> getMedicinesForDate(DateTime date) {
    return _medicines.where((m) {
      return (date.isAfter(m.startDate) ||
              date.isAtSameMomentAs(m.startDate)) &&
          (date.isBefore(m.endDate) || date.isAtSameMomentAs(m.endDate));
    }).toList();
  }

  void removeMedicine(String id) {
    _medicines.removeWhere((m) => m.id == id);
    MedicineStorageService.deleteMedicine(id);
    notifyListeners();
  }

  // ─── API-backed methods (with Hive cache) ───

  Future<void> fetchMedicinesFromApi(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final list = await UserMedicationsService.fetchAll(token);
      _medicines = list;
      MedicineStorageService.saveAllMedicines(list);
      _loadedFromLocal = false;
      _error = null;
    } catch (e) {
      _error = e.toString();
      if (!_loadedFromLocal) {
        loadFromLocal();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<AddMedicineResponse?> addMedicineToApi(
    String token,
    Medicine medicine,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await UserMedicationsService.create(token, medicine);
      _medicines.add(medicine);
      MedicineStorageService.saveMedicine(medicine);
      _error = null;
      onMedicationChanged?.call(token);
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
      MedicineStorageService.saveMedicine(updated);
      _error = null;
      onMedicationChanged?.call(token);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> requestAddMedicationToDatabase(
    String token,
    int userMedicationId,
  ) async {
    try {
      await UserMedicationsService.requestAddToDatabase(
        token,
        userMedicationId,
      );
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> deleteMedicineFromApi(String token, String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await UserMedicationsService.delete(token, id);
      _medicines.removeWhere((m) => m.id == id);
      MedicineStorageService.deleteMedicine(id);
      _error = null;
      onMedicationChanged?.call(token);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteAllFromApi(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await UserMedicationsService.deleteMyUserMeds(token);
      _medicines.clear();
      MedicineStorageService.clearAllMedicines();
      _error = null;
      onMedicationChanged?.call(token);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearLocalData() {
    _medicines.clear();
    MedicineStorageService.clearAllMedicines();
    notifyListeners();
  }
}
