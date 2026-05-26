import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static const String _medicinesBoxName = 'medicines';
  static const String _remindersBoxName = 'reminders';
  static const String _settingsBoxName = 'app_settings';
  static const String _authBoxName = 'auth';

  static Box<dynamic>? _medicinesBox;
  static Box<dynamic>? _remindersBox;
  static Box<dynamic>? _settingsBox;
  static Box<dynamic>? _authBox;

  static Box<dynamic> get medicinesBox {
    if (_medicinesBox == null || !_medicinesBox!.isOpen) {
      throw StateError(
        'Medicines box not initialized. Call HiveService.init() first.',
      );
    }
    return _medicinesBox!;
  }

  static Box<dynamic> get remindersBox {
    if (_remindersBox == null || !_remindersBox!.isOpen) {
      throw StateError(
        'Reminders box not initialized. Call HiveService.init() first.',
      );
    }
    return _remindersBox!;
  }

  static Box<dynamic> get settingsBox {
    if (_settingsBox == null || !_settingsBox!.isOpen) {
      throw StateError(
        'Settings box not initialized. Call HiveService.init() first.',
      );
    }
    return _settingsBox!;
  }

  static Box<dynamic> get authBox {
    if (_authBox == null || !_authBox!.isOpen) {
      throw StateError(
        'Auth box not initialized. Call HiveService.init() first.',
      );
    }
    return _authBox!;
  }

  static Future<void> init() async {
    try {
      await Hive.initFlutter();
      _medicinesBox = await Hive.openBox<dynamic>(_medicinesBoxName);
      _remindersBox = await Hive.openBox<dynamic>(_remindersBoxName);
      _settingsBox = await Hive.openBox<dynamic>(_settingsBoxName);
      _authBox = await Hive.openBox<dynamic>(_authBoxName);
      debugPrint(
        '[HiveService] ✅ Initialized (medicines: ${_medicinesBox!.length}, reminders: ${_remindersBox!.length})',
      );
    } catch (e) {
      debugPrint('[HiveService] ❌ Init error: $e');
      rethrow;
    }
  }

  static Future<void> clearAll() async {
    await medicinesBox.clear();
    await remindersBox.clear();
    await settingsBox.clear();
    await authBox.clear();
    debugPrint('[HiveService] 🗑️ All boxes cleared');
  }

  static bool get isInitialized =>
      _medicinesBox != null && _medicinesBox!.isOpen;
}
