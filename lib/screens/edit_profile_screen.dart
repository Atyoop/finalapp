import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import '../providers/user_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  DateTime? _dateOfBirth;
  String _gender = '';
  int _selectedAvatar = 0;
  String? _imagePath;
  bool _isInit = true;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      _isInit = false;
      _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    final user = context.read<UserProvider>();
    try {
      await user.refreshProfile();
    } catch (_) {
      // Cached, user-scoped data remains available while offline.
    }
    if (!mounted) return;
    _nameController.text = user.name;
    _emailController.text = user.email;
    _phoneController.text = user.phoneNumber;
    setState(() {
      _dateOfBirth = user.dateOfBirth;
      _gender = _supportedGender(user.gender);
      _selectedAvatar = user.selectedAvatar;
      _imagePath = user.imagePath;
      _isLoading = false;
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      if (!mounted) return;
      final userId = context.read<UserProvider>().userId ?? 'current_user';
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final profileImagesDirectory = Directory(
        '${documentsDirectory.path}${Platform.pathSeparator}profile_images',
      );
      await profileImagesDirectory.create(recursive: true);
      final extension = pickedFile.path.contains('.')
          ? pickedFile.path.substring(pickedFile.path.lastIndexOf('.'))
          : '.jpg';
      final permanentImage = await File(pickedFile.path).copy(
        '${profileImagesDirectory.path}${Platform.pathSeparator}'
        'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}$extension',
      );
      if (!mounted) return;
      setState(() {
        _imagePath = permanentImage.path;
      });
    }
  }

  // Avatar icons using Material icons as placeholders
  static const List<IconData> _avatarIcons = [
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

  static const List<Color> _avatarColors = [
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

  Future<void> _showDateOfBirthPicker() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 18),
      firstDate: DateTime(now.year - 120),
      lastDate: now,
    );
    if (selected != null && mounted) {
      setState(() => _dateOfBirth = selected);
    }
  }

  void _showGenderPicker() {
    String tempGender = _gender;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              height: 370,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.l10n.t('chooseGender'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _GenderOption(
                    label: context.l10n.t('male'),
                    isSelected: tempGender == 'Male',
                    onTap: () => setModalState(() => tempGender = 'Male'),
                  ),
                  const SizedBox(height: 12),
                  _GenderOption(
                    label: context.l10n.t('female'),
                    isSelected: tempGender == 'Female',
                    onTap: () => setModalState(() => tempGender = 'Female'),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() => _gender = tempGender);
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                      child: Text(
                        context.l10n.t('done'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        int tempAvatar = _selectedAvatar;
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              height: MediaQuery.of(ctx).size.height * 0.65,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.l10n.t('chooseAvatar'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await _pickImage();
                    },
                    icon: const Icon(Icons.photo_library, color: Colors.white),
                    label: Text(
                      context.l10n.t('chooseFromGallery'),
                      style: const TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                      itemCount: _avatarIcons.length,
                      itemBuilder: (ctx, i) {
                        final isSelected = tempAvatar == i;
                        return GestureDetector(
                          onTap: () => setModalState(() => tempAvatar = i),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _avatarColors[i].withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(
                                      color: AppColors.primaryTeal,
                                      width: 3,
                                    )
                                  : null,
                            ),
                            child: Icon(
                              _avatarIcons[i],
                              color: _avatarColors[i],
                              size: 36,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedAvatar = tempAvatar;
                          _imagePath =
                              null; // reset image path if avatar is chosen
                        });
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                      child: Text(
                        context.l10n.t('done'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _dateOfBirthText(BuildContext context) {
    if (_dateOfBirth == null) return context.l10n.t('notSet');
    return DateFormat.yMMMMd(
      Localizations.localeOf(context).languageCode,
    ).format(_dateOfBirth!);
  }

  String _genderText(BuildContext context) {
    if (_gender.toLowerCase() == 'male') return context.l10n.t('male');
    if (_gender.toLowerCase() == 'female') return context.l10n.t('female');
    return context.l10n.t('notSet');
  }

  String _supportedGender(String gender) {
    if (gender.toLowerCase() == 'male') return 'Male';
    if (gender.toLowerCase() == 'female') return 'Female';
    return '';
  }

  Future<void> _saveProfile() async {
    final phone = _phoneController.text.trim();
    if (phone.isNotEmpty && !RegExp(r'^\+?[0-9\s()-]+$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.t('invalidPhoneNumber'))),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await context.read<UserProvider>().updateProfile(
        name: _nameController.text,
        phoneNumber: phone,
        dateOfBirth: _dateOfBirth,
        gender: _gender,
        selectedAvatar: _selectedAvatar,
        imagePath: _imagePath,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.t('profileUpdated')),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textDark),
        title: Text(
          context.l10n.t('editProfile'),
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.primaryTeal),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // Avatar
                  GestureDetector(
                    onTap: _showAvatarPicker,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: _imagePath == null
                                ? _avatarColors[_selectedAvatar].withValues(
                                    alpha: 0.15,
                                  )
                                : AppColors.backgroundCream,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primaryTeal.withValues(
                                alpha: 0.3,
                              ),
                              width: 2,
                            ),
                            image:
                                _imagePath != null &&
                                    File(_imagePath!).existsSync()
                                ? DecorationImage(
                                    image: FileImage(File(_imagePath!)),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child:
                              _imagePath == null ||
                                  !File(_imagePath!).existsSync()
                              ? Icon(
                                  _avatarIcons[_selectedAvatar],
                                  color: _avatarColors[_selectedAvatar],
                                  size: 52,
                                )
                              : null,
                        ),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primaryTeal,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Name
                  _buildLabel(context.l10n.t('fullName')),
                  _buildTextField(_nameController, Icons.person_outline),
                  const SizedBox(height: 16),
                  // Email
                  _buildLabel(context.l10n.t('email')),
                  _buildTextField(
                    _emailController,
                    Icons.email_outlined,
                    readOnly: true,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  // Phone
                  _buildLabel(context.l10n.t('phoneNumber')),
                  _buildTextField(
                    _phoneController,
                    Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[0-9+()\-\s]'),
                      ),
                      LengthLimitingTextInputFormatter(30),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // DOB
                  _buildLabel(context.l10n.t('dateOfBirth')),
                  GestureDetector(
                    onTap: _showDateOfBirthPicker,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            color: AppColors.textGrey,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _dateOfBirthText(context),
                            style: TextStyle(
                              fontSize: 15,
                              color: AppColors.textDark,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.keyboard_arrow_down,
                            color: AppColors.textGrey,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Gender
                  _buildLabel(context.l10n.t('gender')),
                  GestureDetector(
                    onTap: _showGenderPicker,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.wc_outlined,
                            color: AppColors.textGrey,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _genderText(context),
                            style: TextStyle(
                              fontSize: 15,
                              color: AppColors.textDark,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.keyboard_arrow_down,
                            color: AppColors.textGrey,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 3,
                        shadowColor: AppColors.primaryTeal.withValues(
                          alpha: 0.3,
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              context.l10n.t('save'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textGrey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    IconData icon, {
    bool readOnly = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.textGrey, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

// --- Gender Option Widget ---
class _GenderOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryTeal.withValues(alpha: 0.08)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryTeal : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.primaryTeal : AppColors.textGrey,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.primaryTeal : AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
