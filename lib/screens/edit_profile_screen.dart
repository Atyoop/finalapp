import 'package:flutter/material.dart';
import '../main.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController(text: 'User Name');
  final _emailController = TextEditingController(text: 'user@email.com');
  final _phoneController = TextEditingController(text: '+20 123 456 7890');
  String _dob = '01 / January / 2000';
  String _gender = 'Male';
  int _selectedAvatar = 0;

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

  void _showDateOfBirthPicker() {
    int selectedDay = 1;
    int selectedMonthIndex = 0;
    int selectedYear = 2000;
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

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
              height: 350,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Date of Birth',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Row(
                      children: [
                        // Day
                        Expanded(
                          child: ListWheelScrollView.useDelegate(
                            itemExtent: 44,
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: (i) =>
                                setModalState(() => selectedDay = i + 1),
                            childDelegate: ListWheelChildBuilderDelegate(
                              childCount: 31,
                              builder: (ctx, i) => Center(
                                child: Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: selectedDay == i + 1
                                        ? AppColors.primaryTeal
                                        : AppColors.textGrey,
                                    fontWeight: selectedDay == i + 1
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Month
                        Expanded(
                          flex: 2,
                          child: ListWheelScrollView.useDelegate(
                            itemExtent: 44,
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: (i) =>
                                setModalState(() => selectedMonthIndex = i),
                            childDelegate: ListWheelChildBuilderDelegate(
                              childCount: 12,
                              builder: (ctx, i) => Center(
                                child: Text(
                                  months[i],
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: selectedMonthIndex == i
                                        ? AppColors.primaryTeal
                                        : AppColors.textGrey,
                                    fontWeight: selectedMonthIndex == i
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Year
                        Expanded(
                          child: ListWheelScrollView.useDelegate(
                            itemExtent: 44,
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: (i) =>
                                setModalState(() => selectedYear = 1950 + i),
                            childDelegate: ListWheelChildBuilderDelegate(
                              childCount: 77,
                              builder: (ctx, i) {
                                final y = 1950 + i;
                                return Center(
                                  child: Text(
                                    '$y',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: selectedYear == y
                                          ? AppColors.primaryTeal
                                          : AppColors.textGrey,
                                      fontWeight: selectedYear == y
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _dob =
                              '${selectedDay.toString().padLeft(2, '0')} / ${months[selectedMonthIndex]} / $selectedYear';
                        });
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                      child: const Text(
                        'Done',
                        style: TextStyle(color: Colors.white, fontSize: 16),
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
              height: 300,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Choose Gender',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _GenderOption(
                    label: 'Male',
                    isSelected: tempGender == 'Male',
                    onTap: () => setModalState(() => tempGender = 'Male'),
                  ),
                  const SizedBox(height: 12),
                  _GenderOption(
                    label: 'Female',
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
                      child: const Text(
                        'Done',
                        style: TextStyle(color: Colors.white, fontSize: 16),
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
                      const Text(
                        'Choose Avatar',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                              color: _avatarColors[i].withOpacity(0.15),
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
                        setState(() => _selectedAvatar = tempAvatar);
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                      child: const Text(
                        'Done',
                        style: TextStyle(color: Colors.white, fontSize: 16),
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
        iconTheme: const IconThemeData(color: AppColors.textDark),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
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
                      color: _avatarColors[_selectedAvatar].withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryTeal.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      _avatarIcons[_selectedAvatar],
                      color: _avatarColors[_selectedAvatar],
                      size: 52,
                    ),
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
            _buildLabel('Full Name'),
            _buildTextField(_nameController, Icons.person_outline),
            const SizedBox(height: 16),
            // Email
            _buildLabel('Email'),
            _buildTextField(_emailController, Icons.email_outlined),
            const SizedBox(height: 16),
            // Phone
            _buildLabel('Phone Number'),
            _buildTextField(_phoneController, Icons.phone_outlined),
            const SizedBox(height: 16),
            // DOB
            _buildLabel('Date of Birth'),
            GestureDetector(
              onTap: _showDateOfBirthPicker,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        color: AppColors.textGrey, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      _dob,
                      style: const TextStyle(fontSize: 15, color: AppColors.textDark),
                    ),
                    const Spacer(),
                    Icon(Icons.keyboard_arrow_down,
                        color: AppColors.textGrey, size: 22),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Gender
            _buildLabel('Gender'),
            GestureDetector(
              onTap: _showGenderPicker,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.wc_outlined,
                        color: AppColors.textGrey, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      _gender,
                      style: const TextStyle(fontSize: 15, color: AppColors.textDark),
                    ),
                    const Spacer(),
                    Icon(Icons.keyboard_arrow_down,
                        color: AppColors.textGrey, size: 22),
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
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile Updated Successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 3,
                  shadowColor: AppColors.primaryTeal.withOpacity(0.3),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(
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
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textGrey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
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
              ? AppColors.primaryTeal.withOpacity(0.08)
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
