import 'package:flutter/foundation.dart';
import '../models/hive_medicine.dart';
import '../models/hive_reminder.dart';
import '../models/medicine.dart';
import 'hive_service.dart';

class MedicineStorageService {
  // ───── Medicines ─────

  static List<Medicine> getAllMedicines() {
    try {
      final box = HiveService.medicinesBox;
      return box.values.map((m) {
        return HiveMedicine.fromMap(Map<String, dynamic>.from(m)).toMedicine();
      }).toList();
    } catch (e) {
      debugPrint('[MedicineStorage] Error reading all: $e');
      return [];
    }
  }

  static Medicine? getMedicine(String id) {
    try {
      final box = HiveService.medicinesBox;
      final data = box.get(id);
      if (data == null) return null;
      return HiveMedicine.fromMap(Map<String, dynamic>.from(data)).toMedicine();
    } catch (e) {
      debugPrint('[MedicineStorage] Error reading $id: $e');
      return null;
    }
  }

  static Future<bool> saveMedicine(Medicine medicine) async {
    try {
      final box = HiveService.medicinesBox;
      final hiveMed = HiveMedicine.fromMedicine(medicine);
      await box.put(medicine.id, hiveMed.toMap());
      debugPrint('[MedicineStorage] ✅ Saved: ${medicine.name}');
      return true;
    } catch (e) {
      debugPrint('[MedicineStorage] ❌ Error saving: $e');
      return false;
    }
  }

  static Future<bool> saveAllMedicines(List<Medicine> medicines) async {
    try {
      final box = HiveService.medicinesBox;
      final map = <String, Map<String, dynamic>>{};
      for (final m in medicines) {
        map[m.id] = HiveMedicine.fromMedicine(m).toMap();
      }
      await box.putAll(map);
      debugPrint('[MedicineStorage] ✅ Saved ${medicines.length} medicines');
      return true;
    } catch (e) {
      debugPrint('[MedicineStorage] ❌ Error saving all: $e');
      return false;
    }
  }

  static Future<bool> deleteMedicine(String id) async {
    try {
      final box = HiveService.medicinesBox;
      await box.delete(id);
      debugPrint('[MedicineStorage] 🗑️ Deleted: $id');
      return true;
    } catch (e) {
      debugPrint('[MedicineStorage] ❌ Error deleting: $e');
      return false;
    }
  }

  static Future<bool> clearAllMedicines() async {
    try {
      await HiveService.medicinesBox.clear();
      debugPrint('[MedicineStorage] 🗑️ All medicines cleared');
      return true;
    } catch (e) {
      debugPrint('[MedicineStorage] ❌ Error clearing: $e');
      return false;
    }
  }

  static List<Medicine> searchMedicines(String query) {
    if (query.isEmpty) return getAllMedicines();
    final lower = query.toLowerCase();
    return getAllMedicines().where((m) {
      return m.name.toLowerCase().contains(lower) ||
          (m.dosage?.toLowerCase().contains(lower) ?? false);
    }).toList();
  }

  // ───── Reminders ─────

  static List<HiveReminder> getAllReminders() {
    try {
      final box = HiveService.remindersBox;
      return box.values.map((r) {
        return HiveReminder.fromMap(Map<String, dynamic>.from(r));
      }).toList();
    } catch (e) {
      debugPrint('[MedicineStorage] Error reading reminders: $e');
      return [];
    }
  }

  static Future<bool> saveReminder(HiveReminder reminder) async {
    try {
      final box = HiveService.remindersBox;
      await box.put(reminder.medicineId, reminder.toMap());
      return true;
    } catch (e) {
      debugPrint('[MedicineStorage] ❌ Error saving reminder: $e');
      return false;
    }
  }

  static Future<bool> deleteReminder(String medicineId) async {
    try {
      await HiveService.remindersBox.delete(medicineId);
      return true;
    } catch (e) {
      debugPrint('[MedicineStorage] ❌ Error deleting reminder: $e');
      return false;
    }
  }

  static Future<bool> toggleReminder(String medicineId, bool isActive) async {
    try {
      final box = HiveService.remindersBox;
      final data = box.get(medicineId);
      if (data == null) return false;
      final reminder = HiveReminder.fromMap(Map<String, dynamic>.from(data));
      reminder.isActive = isActive;
      await box.put(medicineId, reminder.toMap());
      return true;
    } catch (e) {
      debugPrint('[MedicineStorage] ❌ Error toggling reminder: $e');
      return false;
    }
  }

  static Future<bool> clearAllReminders() async {
    try {
      await HiveService.remindersBox.clear();
      return true;
    } catch (e) {
      debugPrint('[MedicineStorage] ❌ Error clearing reminders: $e');
      return false;
    }
  }

  // ───── Settings ─────

  static Future<bool> saveSetting(String key, dynamic value) async {
    try {
      await HiveService.settingsBox.put(key, value);
      return true;
    } catch (e) {
      debugPrint('[MedicineStorage] ❌ Error saving setting $key: $e');
      return false;
    }
  }

  static T? getSetting<T>(String key) {
    try {
      final val = HiveService.settingsBox.get(key);
      return val as T?;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> removeSetting(String key) async {
    try {
      await HiveService.settingsBox.delete(key);
      return true;
    } catch (e) {
      debugPrint('[MedicineStorage] ❌ Error removing setting $key: $e');
      return false;
    }
  }

  // ───── Stock helpers ─────

  static Future<bool> updateStock(String id, int newCount) async {
    try {
      final box = HiveService.medicinesBox;
      final data = box.get(id);
      if (data == null) return false;
      final hiveMed = HiveMedicine.fromMap(Map<String, dynamic>.from(data));
      hiveMed.currentPillCount = newCount;
      hiveMed.currentQuantity = newCount;
      hiveMed.updatedAt = DateTime.now().toIso8601String();
      await box.put(id, hiveMed.toMap());
      return true;
    } catch (e) {
      debugPrint('[MedicineStorage] ❌ Error updating stock: $e');
      return false;
    }
  }

  static Future<bool> decrementStock(String id, int amount) async {
    final med = getMedicine(id);
    if (med == null) return false;
    final current =
        med.currentQuantity ?? med.currentPillCount ?? med.initialStock;
    final newCount = (current - amount).clamp(0, current);
    return updateStock(id, newCount);
  }
}
