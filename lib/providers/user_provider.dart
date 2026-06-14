import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../services/medicine_storage_service.dart';

class UserProvider extends ChangeNotifier {
  String _name = 'Omar H.';
  String? _imagePath;
  int _selectedAvatar = 0;
  String? _token;
  String? _userId;

  UserProvider() {
    _loadPersistedSession();
  }

  void _loadPersistedSession() {
    final storedToken = MedicineStorageService.getSetting<String>('auth_token');
    final storedUserId = MedicineStorageService.getSetting<String>('auth_user_id');
    
    if (storedToken != null && storedToken.isNotEmpty) {
      try {
        if (JwtDecoder.isExpired(storedToken)) {
          debugPrint('[UserProvider] ⏳ Stored token is expired, clearing.');
          _clearSessionStorage();
        } else {
          _token = storedToken;
          _userId = storedUserId;
          debugPrint('[UserProvider] 🔑 Stored token loaded successfully');
        }
      } catch (e) {
        debugPrint('[UserProvider] ❌ Error decoding token: $e');
        _clearSessionStorage();
      }
    }
  }

  void _clearSessionStorage() {
    _token = null;
    _userId = null;
    MedicineStorageService.removeSetting('auth_token');
    MedicineStorageService.removeSetting('auth_user_id');
  }

  static const List<IconData> avatarIcons = [
    Icons.face,
    Icons.face_2,
    Icons.face_3,
    Icons.face_4,
    Icons.face_5,
    Icons.face_6,
    Icons.sentiment_very_satisfied,
    Icons.sentiment_satisfied,
    Icons.emoji_people,
    Icons.person,
    Icons.person_2,
    Icons.person_3,
    Icons.person_4,
    Icons.boy,
    Icons.girl,
    Icons.elderly,
  ];

  static const List<Color> avatarColors = [
    Color(0xFF4CAF50),
    Color(0xFF2196F3),
    Color(0xFFFF9800),
    Color(0xFF9C27B0),
    Color(0xFFE91E63),
    Color(0xFF00BCD4),
    Color(0xFFFF5722),
    Color(0xFF607D8B),
    Color(0xFF795548),
    Color(0xFF3F51B5),
    Color(0xFFCDDC39),
    Color(0xFF009688),
    Color(0xFFF44336),
    Color(0xFF673AB7),
    Color(0xFFFFEB3B),
    Color(0xFF8BC34A),
  ];

  String get name => _name;
  String? get imagePath => _imagePath;
  int get selectedAvatar => _selectedAvatar;
  IconData get currentAvatarIcon => avatarIcons[_selectedAvatar];
  Color get currentAvatarColor => avatarColors[_selectedAvatar];
  String? get token => _token;
  String? get userId => _userId;
  bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  void setToken(String token) {
    _token = token;
    MedicineStorageService.saveSetting('auth_token', token);
    notifyListeners();
  }

  void setUserId(String id) {
    _userId = id;
    MedicineStorageService.saveSetting('auth_user_id', id);
    notifyListeners();
  }

  void logout() {
    _token = null;
    _userId = null;
    MedicineStorageService.removeSetting('auth_token');
    MedicineStorageService.removeSetting('auth_user_id');
    MedicineStorageService.clearAllMedicines();
    MedicineStorageService.clearAllReminders();
    notifyListeners();
  }

  void updateProfile({
    required String name,
    String? imagePath,
    required int selectedAvatar,
  }) {
    _name = name;
    _imagePath = imagePath;
    _selectedAvatar = selectedAvatar;
    notifyListeners();
  }
}
