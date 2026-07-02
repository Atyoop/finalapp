import 'dart:async';
import 'dart:convert'; // Ù„ØªØ­ÙˆÙŠÙ„ Ø§Ù„Ø¨ÙŠØ§Ù†Ø§Øª Ù„Ù€ JSON
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Ù„Ù„Ø§ØªØµØ§Ù„ Ø¨Ø§Ù„Ø³ÙŠØ±ÙØ±
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../main.dart'; // Ù„Ø§Ø³ØªÙŠØ±Ø§Ø¯ Ø§Ù„Ø£Ù„ÙˆØ§Ù† ÙˆØ§Ù„ÙˆØ¯Ø¬Øª
import '../providers/user_provider.dart';
import '../services/password_service.dart';
import '../widgets/password_requirements.dart';

Future<bool> _saveAuthSession(BuildContext context, String responseBody) async {
  final data = jsonDecode(responseBody);
  if (data is! Map<String, dynamic>) return false;

  final nestedData = data['data'];
  final user = data['user'];
  final token =
      data['token']?.toString() ??
      data['accessToken']?.toString() ??
      (nestedData is Map ? nestedData['token']?.toString() : null);
  final userId =
      data['userId']?.toString() ??
      data['user_id']?.toString() ??
      (user is Map ? (user['id'] ?? user['userId'])?.toString() : null) ??
      (nestedData is Map ? nestedData['userId']?.toString() : null);
  final email =
      (user is Map ? user['email']?.toString() : null) ??
      data['email']?.toString() ??
      (nestedData is Map ? nestedData['email']?.toString() : null);

  if (token == null || token.isEmpty) return false;
  await context.read<UserProvider>().saveAuthSession(
    token: token,
    userId: userId,
    email: email,
  );
  return true;
}

// -----------------------------------------------------------------------------
// 1. SIGNUP SCREEN
// -----------------------------------------------------------------------------
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool _isPasswordVisible = false;
  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  void _checkPassword(String password) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.t('createAccount'),
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            // Name Input

            // Email Input
            Text(
              context.l10n.t('email'),
              style: TextStyle(color: AppColors.textGrey),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: context.l10n.t('enterEmail'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Password Input
            Text(
              context.l10n.t('password'),
              style: TextStyle(color: AppColors.textGrey),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              onChanged: _checkPassword,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: context.l10n.t('createPassword'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () =>
                      setState(() => _isPasswordVisible = !_isPasswordVisible),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Password Validations
            PasswordRequirements(password: _passwordController.text),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        context.l10n.t('createAccount'),
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _register() async {
    const String apiUrl = "https://drugsafe.runasp.net/api/Auth/register";

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.t('pleaseFillAllFields')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json", "Accept": "*/*"},
        body: jsonEncode({
          "name": _nameController.text.trim(),
          "email": _emailController.text.trim(),
          "password": _passwordController.text,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.t('registrationSuccessful')),
            backgroundColor: Colors.green,
          ),
        );

        // try to extract pending token from response body and forward it
        String? pendingToken;
        try {
          final data = jsonDecode(response.body);
          pendingToken =
              data['pendingToken'] ??
              data['pending_token'] ??
              data['token']?.toString();
        } catch (_) {
          pendingToken = null;
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerifyScreen(
              isReset: false,
              email: _emailController.text.trim(),
              pendingToken: pendingToken,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.t('failedWithBody', {'body': response.body}),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.t('connectionErrorCors')),
          backgroundColor: Colors.orange,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

// -----------------------------------------------------------------------------
// 2. OTP VERIFY SCREEN
// -----------------------------------------------------------------------------
class OtpVerifyScreen extends StatefulWidget {
  final bool isReset;
  final String? email;

  // â”€â”€ CHANGE 1: added pendingToken parameter â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // For the register flow, the backend returns a pendingToken after register.
  // The register screen must pass it here. It is optional so the reset flow
  // (which may not use pendingToken) is not broken.
  final String? pendingToken;
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  const OtpVerifyScreen({
    super.key,
    required this.isReset,
    this.email,
    this.pendingToken, // â† added
  });

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  int _start = 59;
  late Timer _timer;
  final List<TextEditingController> _otpControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocus = List.generate(4, (_) => FocusNode());
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (t) => setState(() => _start > 0 ? _start-- : t.cancel()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            Text(
              widget.isReset
                  ? context.l10n.t('enter4DigitCodeTitle')
                  : context.l10n.t('codeSentToEmail'),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(4, (i) {
                return SizedBox(
                  width: 65,
                  child: TextField(
                    controller: _otpControllers[i],
                    focusNode: _otpFocus[i],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    decoration: InputDecoration(
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (v) {
                      if (v.isNotEmpty && i < 3) {
                        _otpFocus[i + 1].requestFocus();
                      }
                      if (v.isEmpty && i > 0) {
                        _otpFocus[i - 1].requestFocus();
                      }
                    },
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            Text("00:${_start.toString().padLeft(2, '0')}sec"),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isVerifying ? null : _verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                ),
                child: _isVerifying
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        widget.isReset
                            ? context.l10n.t('resetPassword')
                            : context.l10n.t('confirm'),
                        style: const TextStyle(color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _verifyOtp() async {
    final code = _otpControllers.map((c) => c.text).join();
    if (code.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.t('enter4DigitCode')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isVerifying = true);

    // â”€â”€ CHANGE 2: choose endpoint and body based on flow â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    // Register flow  â†’ POST verify-register-otp  with { pendingToken, otp }
    // Reset flow     â†’ POST verify-otp (or your reset endpoint) with { email, otp }
    // The user never types email or pendingToken â€” they come from widget params.
    const String registerVerifyUrl =
        'https://drugsafe.runasp.net/api/Auth/verify-register-otp';
    const String resetVerifyUrl =
        'https://drugsafe.runasp.net/api/Auth/verify-reset-otp';

    final String apiUrl = widget.isReset ? resetVerifyUrl : registerVerifyUrl;

    final Map<String, dynamic> body = widget.isReset
        ? {
            // Reset flow: still uses email + otp (unchanged)
            if (widget.email != null) 'email': widget.email,
            'otp': code,
          }
        : {
            // Register flow: uses pendingToken + otp â€” NO email sent
            'pendingToken': widget.pendingToken,
            'otp': code,
          };
    // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json", "Accept": "*/*"},
        body: jsonEncode(body),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        if (!widget.isReset) {
          final sessionSaved = await _saveAuthSession(context, response.body);
          if (!mounted) return;
          if (!sessionSaved) {
            throw const FormatException(
              'Registration verification response did not contain a token',
            );
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.t('verificationSuccessful')),
            backgroundColor: Colors.green,
          ),
        );

        if (widget.isReset) {
          final data = jsonDecode(response.body);
          final resetToken = data is Map<String, dynamic>
              ? data['resetToken']?.toString()
              : null;
          if (resetToken == null ||
              resetToken.isEmpty ||
              widget.email == null) {
            throw const FormatException(
              'Reset verification response did not contain a reset token',
            );
          }
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (c) => NewPasswordScreen(
                email: widget.email!,
                resetToken: resetToken,
              ),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (c) => const SuccessVerifiedScreen()),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isReset
                  ? context.l10n.t('invalidOrExpiredOtp')
                  : context.l10n.t('failedWithBody', {'body': response.body}),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.t('connectionErrorCors')),
          backgroundColor: Colors.orange,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  @override
  void dispose() {
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocus) {
      f.dispose();
    }
    _timer.cancel();
    super.dispose();
  }
}

// -----------------------------------------------------------------------------
// 3. SUCCESS SCREEN
// -----------------------------------------------------------------------------
class SuccessVerifiedScreen extends StatelessWidget {
  const SuccessVerifiedScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const Spacer(),
          const PlaceholderImageWidget(color: Colors.pink),
          const SizedBox(height: 20),
          Text(
            context.l10n.t('successfullyVerified'),
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () =>
                    continueAfterAuth(context, isNewRegistration: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                ),
                child: Text(
                  context.l10n.t('getStarted'),
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 4. LOGIN SCREEN (API CONNECTED WITH EMAIL)
// -----------------------------------------------------------------------------
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isObscure = true;

  // --- API FUNCTION ---
  Future<void> _login() async {
    const String apiUrl = "https://drugsafe.runasp.net/api/Auth/login";

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.t('pleaseFillAllFields')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json", "Accept": "*/*"},
        body: jsonEncode({
          "email": _emailController.text.trim(), // Using Email
          "password": _passwordController.text,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final sessionSaved = await _saveAuthSession(context, response.body);
        if (!mounted) return;
        if (!sessionSaved) {
          throw const FormatException('Login response did not contain a token');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.t('loginSuccessful')),
            backgroundColor: Colors.green,
          ),
        );

        await continueAfterAuth(context, isNewRegistration: false);
      } else {
        // --- ERROR ---
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.t('failedWithBody', {'body': response.body}),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // --- NETWORK ERROR ---
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.t('connectionErrorCors')),
          backgroundColor: Colors.orange,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.t('login'),
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            // --- EMAIL FIELD ---
            const Text("Email"), const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: context.l10n.t('enterEmail'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // --- PASSWORD FIELD ---
            const Text("Password"), const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              obscureText: _isObscure,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: context.l10n.t('enterPassword'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isObscure ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () => setState(() => _isObscure = !_isObscure),
                ),
              ),
            ),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ForgotPasswordScreen(),
                  ),
                ),
                child: Text(
                  context.l10n.t('forgotPassword'),
                  style: TextStyle(color: AppColors.primaryTeal),
                ),
              ),
            ),

            // --- LOGIN BUTTON ---
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        context.l10n.t('login'),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignupScreen()),
                ),
                child: Text(
                  context.l10n.t('createAccountPrompt'),
                  style: TextStyle(color: AppColors.primaryTeal),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 5. FORGOT PASSWORD SCREEN
// -----------------------------------------------------------------------------
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isSending = false;

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showMessage(context.l10n.t('enterValidEmail'), Colors.red);
      return;
    }

    setState(() => _isSending = true);
    try {
      await PasswordService.requestResetOtp(email);
      if (!mounted) return;
      _showMessage(context.l10n.t('resetOtpSent'), Colors.green);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerifyScreen(isReset: true, email: email),
        ),
      );
    } catch (_) {
      if (mounted) _showMessage(context.l10n.t('failedToSendOtp'), Colors.red);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            Text(
              context.l10n.t('forgotPassword'),
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: context.l10n.t('enterEmailShort'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSending ? null : _sendOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                ),
                child: _isSending
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        context.l10n.t('resetPasswordLower'),
                        style: const TextStyle(color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 6. NEW PASSWORD SCREEN
// -----------------------------------------------------------------------------
class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({
    super.key,
    required this.email,
    required this.resetToken,
  });

  final String email;
  final String resetToken;

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSaving = false;

  Future<void> _resetPassword() async {
    final password = _newPasswordController.text;
    final confirmation = _confirmPasswordController.text;
    if (password.isEmpty || confirmation.isEmpty) {
      _showError(context.l10n.t('pleaseFillAllFields'));
      return;
    }
    if (password != confirmation) {
      _showError(context.l10n.t('passwordsDoNotMatch'));
      return;
    }
    if (!PasswordRules.isValid(password)) {
      _showError(context.l10n.t('passwordRequirementsError'));
      return;
    }

    setState(() => _isSaving = true);
    try {
      await PasswordService.resetPassword(
        email: widget.email,
        resetToken: widget.resetToken,
        newPassword: password,
        confirmPassword: confirmation,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.t('passwordResetSuccessful')),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } on PasswordServiceException catch (error) {
      if (!mounted) return;
      _showError(
        error.message.toLowerCase().contains('expired')
            ? context.l10n.t('resetVerificationExpired')
            : context.l10n.t('passwordResetFailed'),
      );
    } catch (_) {
      if (mounted) _showError(context.l10n.t('passwordResetFailed'));
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
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            Text(
              context.l10n.t('newPassword'),
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _newPasswordController,
              obscureText: _obscureNew,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: context.l10n.t('newPassword'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNew ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                ),
              ),
            ),
            const SizedBox(height: 10),
            PasswordRequirements(password: _newPasswordController.text),
            const SizedBox(height: 20),
            TextField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: context.l10n.t('confirmPassword'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _resetPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        context.l10n.t('createNewPassword'),
                        style: const TextStyle(color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
