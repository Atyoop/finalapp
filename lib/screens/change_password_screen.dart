import 'package:flutter/material.dart';
import '../main.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  bool _obsOld = true;
  bool _obsNew = true;
  bool _obsConfirm = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Change Password",
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Text("Old Password", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 8),
            _buildTextField("Enter your Old Password", _obsOld, () => setState(() => _obsOld = !_obsOld)),
            
            const SizedBox(height: 20),
            const Text("New Password", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 8),
            _buildTextField("Enter your New Password", _obsNew, () => setState(() => _obsNew = !_obsNew)),
            
            const SizedBox(height: 20),
            const Text("Confirm New Password", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 8),
            _buildTextField("Re-Enter your New Password", _obsConfirm, () => setState(() => _obsConfirm = !_obsConfirm)),
            
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
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text("Change Password", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, bool isObscure, VoidCallback toggle) {
    return TextField(
      obscureText: isObscure,
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
          icon: Icon(isObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textGrey),
          onPressed: toggle,
        ),
      ),
    );
  }
}
