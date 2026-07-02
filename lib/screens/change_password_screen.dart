import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import '../providers/user_provider.dart';
import '../services/password_service.dart';
import '../widgets/password_requirements.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obsOld = true;
  bool _obsNew = true;
  bool _obsConfirm = true;
  bool _isSaving = false;

  Future<void> _changePassword() async {
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmation = _confirmPasswordController.text;
    final userProvider = context.read<UserProvider>();
    final token = userProvider.token;

    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmation.isEmpty) {
      _showError(context.l10n.t('pleaseFillAllFields'));
      return;
    }
    if (newPassword != confirmation) {
      _showError(context.l10n.t('passwordsDoNotMatch'));
      return;
    }
    if (!PasswordRules.isValid(newPassword)) {
      _showError(context.l10n.t('passwordRequirementsError'));
      return;
    }
    if (token == null || token.isEmpty) {
      _showError(context.l10n.t('pleaseSignInAgain'));
      return;
    }

    setState(() => _isSaving = true);
    try {
      await PasswordService.changePassword(
        token: token,
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmation,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.t('passwordChangedSuccessfully')),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } on PasswordServiceException catch (error) {
      if (!mounted) return;
      if (error.statusCode == 401) {
        userProvider.logout();
        _showError(context.l10n.t('sessionExpired'));
        Navigator.pop(context);
      } else if (error.message.toLowerCase().contains('current password')) {
        _showError(context.l10n.t('currentPasswordIncorrect'));
      } else {
        _showError(context.l10n.t('passwordChangeFailed'));
      }
    } catch (_) {
      if (mounted) _showError(context.l10n.t('passwordChangeFailed'));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const BackButtonIcon(),
          color: AppColors.textDark,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.l10n.t('changePassword'),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              context.l10n.t('oldPassword'),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            _buildTextField(
              _currentPasswordController,
              context.l10n.t('enterOldPassword'),
              _obsOld,
              () => setState(() => _obsOld = !_obsOld),
            ),

            const SizedBox(height: 20),
            Text(
              context.l10n.t('newPassword'),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            _buildTextField(
              _newPasswordController,
              context.l10n.t('enterNewPassword'),
              _obsNew,
              () => setState(() => _obsNew = !_obsNew),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            PasswordRequirements(password: _newPasswordController.text),

            const SizedBox(height: 20),
            Text(
              context.l10n.t('confirmNewPassword'),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            _buildTextField(
              _confirmPasswordController,
              context.l10n.t('reenterNewPassword'),
              _obsConfirm,
              () => setState(() => _obsConfirm = !_obsConfirm),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _changePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      context.l10n.t('changePassword'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    bool isObscure,
    VoidCallback toggle, {
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      onChanged: onChanged,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textGrey, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            isObscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: AppColors.textGrey,
          ),
          onPressed: toggle,
        ),
      ),
    );
  }
}
