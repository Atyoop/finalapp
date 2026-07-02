import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../services/medicine_storage_service.dart';
import '../services/user_profile_service.dart';

class UserProvider extends ChangeNotifier {
  final void Function(String? token)? onTokenChanged;
  String _name = '';
  String _email = '';
  String _phoneNumber = '';
  DateTime? _dateOfBirth;
  String _gender = '';
  String? _imagePath;
  int _selectedAvatar = 0;
  String? _token;
  String? _userId;

  UserProvider({this.onTokenChanged}) {
    _loadPersistedSession();
    onTokenChanged?.call(_token);
  }

  void _loadPersistedSession() {
    final storedToken = MedicineStorageService.getSetting<String>('auth_token');
    final storedUserId = MedicineStorageService.getSetting<String>(
      'auth_user_id',
    );
    if (storedToken != null && storedToken.isNotEmpty) {
      try {
        if (JwtDecoder.isExpired(storedToken)) {
          debugPrint('[UserProvider] ⏳ Stored token is expired, clearing.');
          _clearSessionStorage();
        } else {
          _token = storedToken;
          _userId = storedUserId ?? _readUserIdFromToken(storedToken);
          _loadScopedProfile();
          debugPrint('[UserProvider] 🔑 Stored token loaded successfully');
        }
      } catch (e) {
        debugPrint('[UserProvider] ❌ Error decoding token: $e');
        _clearSessionStorage();
      }
    }
  }

  String? _readUserIdFromToken(String token) {
    try {
      final claims = JwtDecoder.decode(token);
      final value =
          claims['nameid'] ??
          claims['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'] ??
          claims['sub'];
      final id = value?.toString();
      return id == null || id.isEmpty ? null : id;
    } catch (_) {
      return null;
    }
  }

  String _profileKey(String field) => 'profile_${_userId ?? 'none'}_$field';

  void _loadScopedProfile() {
    if (_userId == null || _userId!.isEmpty) {
      _resetProfileInMemory();
      return;
    }
    _name =
        MedicineStorageService.getSetting<String>(_profileKey('name')) ?? '';
    _email =
        MedicineStorageService.getSetting<String>(_profileKey('email')) ?? '';
    _phoneNumber =
        MedicineStorageService.getSetting<String>(_profileKey('phone')) ?? '';
    _gender =
        MedicineStorageService.getSetting<String>(_profileKey('gender')) ?? '';
    _dateOfBirth = DateTime.tryParse(
      MedicineStorageService.getSetting<String>(_profileKey('birth_date')) ??
          '',
    );
    _imagePath = MedicineStorageService.getSetting<String>(
      _profileKey('image_path'),
    );
    _selectedAvatar =
        MedicineStorageService.getSetting<int>(_profileKey('avatar_index')) ??
        0;
    if (_selectedAvatar < 0 || _selectedAvatar >= avatarIcons.length) {
      _selectedAvatar = 0;
    }
  }

  void _resetProfileInMemory() {
    _name = '';
    _email = '';
    _phoneNumber = '';
    _dateOfBirth = null;
    _gender = '';
    _imagePath = null;
    _selectedAvatar = 0;
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
  String get email => _email;
  String get phoneNumber => _phoneNumber;
  DateTime? get dateOfBirth => _dateOfBirth;
  String get gender => _gender;
  String get displayName {
    if (_name.trim().isNotEmpty) return _name.trim();
    if (_email.contains('@')) return _email.split('@').first;
    if (_email.trim().isNotEmpty) return _email.trim();
    return 'User';
  }

  String? get imagePath => _imagePath;
  int get selectedAvatar => _selectedAvatar;
  IconData get currentAvatarIcon => avatarIcons[_selectedAvatar];
  Color get currentAvatarColor => avatarColors[_selectedAvatar];
  String? get token => _token;
  String? get userId => _userId;
  bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  Future<void> saveAuthSession({
    required String token,
    String? userId,
    String? email,
  }) async {
    _token = token;
    _userId = userId ?? _readUserIdFromToken(token);
    _resetProfileInMemory();
    _loadScopedProfile();
    if (email != null && email.trim().isNotEmpty) {
      _email = email.trim();
      await MedicineStorageService.saveSetting(_profileKey('email'), _email);
    }
    final tokenSaved = await MedicineStorageService.saveSetting(
      'auth_token',
      token,
    );
    if (!tokenSaved) {
      _token = null;
      _userId = null;
      throw StateError('Could not persist the authentication token');
    }
    if (_userId != null && _userId!.isNotEmpty) {
      await MedicineStorageService.saveSetting('auth_user_id', _userId);
    } else {
      await MedicineStorageService.removeSetting('auth_user_id');
    }
    onTokenChanged?.call(token);
    notifyListeners();
  }

  void logout() {
    _token = null;
    _userId = null;
    MedicineStorageService.removeSetting('auth_token');
    MedicineStorageService.removeSetting('auth_user_id');
    // Remove obsolete unscoped keys so a previous account can never leak into
    // a newly authenticated account. Scoped profile keys remain available when
    // their owner signs back in on this device.
    MedicineStorageService.removeSetting('profile_display_name');
    MedicineStorageService.removeSetting('profile_image_path');
    MedicineStorageService.removeSetting('profile_avatar_index');
    onTokenChanged?.call(null);
    MedicineStorageService.clearAllMedicines();
    MedicineStorageService.clearAllReminders();
    _resetProfileInMemory();
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    final currentToken = _token;
    if (currentToken == null || currentToken.isEmpty) return;
    final profile = await UserProfileService.getProfile(currentToken);
    if (_userId == null || _userId!.isEmpty) {
      _userId = profile.id;
      await MedicineStorageService.saveSetting('auth_user_id', profile.id);
      _loadScopedProfile();
    }
    if (_userId != null && profile.id != _userId) return;
    _name = profile.fullName;
    _email = profile.email;
    _phoneNumber = profile.phoneNumber;
    _dateOfBirth = profile.dateOfBirth;
    _gender = profile.gender;
    await _persistProfileFields();
    notifyListeners();
  }

  Future<void> updateProfile({
    required String name,
    required String phoneNumber,
    required DateTime? dateOfBirth,
    required String gender,
    String? imagePath,
    required int selectedAvatar,
  }) async {
    final currentToken = _token;
    if (currentToken == null || currentToken.isEmpty) {
      throw const UserProfileException('Please sign in again.');
    }
    final profile = await UserProfileService.updateProfile(
      currentToken,
      fullName: name.trim(),
      phoneNumber: phoneNumber.trim(),
      dateOfBirth: dateOfBirth,
      gender: gender,
    );
    _name = profile.fullName;
    _email = profile.email;
    _phoneNumber = profile.phoneNumber;
    _dateOfBirth = profile.dateOfBirth;
    _gender = profile.gender;
    _imagePath = imagePath;
    _selectedAvatar = selectedAvatar;
    await _persistProfileFields();
    if (_imagePath == null || _imagePath!.isEmpty) {
      await MedicineStorageService.removeSetting(_profileKey('image_path'));
    } else {
      await MedicineStorageService.saveSetting(
        _profileKey('image_path'),
        _imagePath,
      );
    }
    await MedicineStorageService.saveSetting(
      _profileKey('avatar_index'),
      _selectedAvatar,
    );
    notifyListeners();
  }

  Future<void> _persistProfileFields() async {
    if (_userId == null || _userId!.isEmpty) return;
    await Future.wait([
      MedicineStorageService.saveSetting(_profileKey('name'), _name),
      MedicineStorageService.saveSetting(_profileKey('email'), _email),
      MedicineStorageService.saveSetting(_profileKey('phone'), _phoneNumber),
      MedicineStorageService.saveSetting(_profileKey('gender'), _gender),
      if (_dateOfBirth == null)
        MedicineStorageService.removeSetting(_profileKey('birth_date'))
      else
        MedicineStorageService.saveSetting(
          _profileKey('birth_date'),
          _dateOfBirth!.toIso8601String(),
        ),
    ]);
  }
}
