import 'dart:async';
import 'dart:convert'; // Ù„ØªØ­ÙˆÙŠÙ„ Ø§Ù„Ø¨ÙŠØ§Ù†Ø§Øª Ù„Ù€ JSON
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Ù„Ù„Ø§ØªØµØ§Ù„ Ø¨Ø§Ù„Ø³ÙŠØ±ÙØ±
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../main.dart'; // Ù„Ø§Ø³ØªÙŠØ±Ø§Ø¯ Ø§Ù„Ø£Ù„ÙˆØ§Ù† ÙˆØ§Ù„ÙˆØ¯Ø¬Øª
import '../providers/user_provider.dart';
import '../providers/notifications_provider.dart';
import 'home.dart'; // MainNavScreen

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
  bool _hasMinLength = false, _hasMinNumber = false, _hasUppercase = false;
  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  void _checkPassword(String password) {
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasMinNumber = password.replaceAll(RegExp(r'[^0-9]'), '').length >= 2;
      _hasUppercase = password.contains(RegExp(r'[A-Z]'));
    });
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
            _buildReqRow(context.l10n.t('min8Characters'), _hasMinLength),
            _buildReqRow(context.l10n.t('min2Numbers'), _hasMinNumber),
            _buildReqRow(context.l10n.t('min1Uppercase'), _hasUppercase),

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

  Widget _buildReqRow(String txt, bool ok) => Row(
    children: [
      Icon(
        ok ? Icons.check : Icons.circle,
        size: 16,
        color: ok ? AppColors.primaryTeal : Colors.grey,
      ),
      const SizedBox(width: 8),
      Text(
        txt,
        style: TextStyle(color: ok ? AppColors.primaryTeal : Colors.grey),
      ),
    ],
  );
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
        'https://drugsafe.runasp.net/api/Auth/verify-otp'; // adjust if different

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.t('verificationSuccessful')),
            backgroundColor: Colors.green,
          ),
        );

        if (widget.isReset) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (c) => const NewPasswordScreen()),
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
      setState(() => _isVerifying = false);
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
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const MainNavScreen()),
                  (r) => false,
                ),
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
        // --- SUCCESS ---
        String? token;
        String? userId;
        try {
          final data = jsonDecode(response.body);
          if (data is Map<String, dynamic>) {
            token =
                data['token']?.toString() ?? data['accessToken']?.toString();
            // nested wrappers
            token ??= (data['data'] is Map)
                ? data['data']['token']?.toString()
                : null;
            userId = data['userId']?.toString() ?? data['user_id']?.toString();
            userId ??= (data['data'] is Map)
                ? data['data']['userId']?.toString()
                : null;
          }
        } catch (_) {
          token = null;
        }

        if (token != null && token.isNotEmpty) {
          try {
            context.read<UserProvider>().setToken(token);
            if (userId != null && userId.isNotEmpty) {
              context.read<UserProvider>().setUserId(userId);
            }
            unawaited(context.read<NotificationsProvider>().fetchAndScheduleNotifications(token));
          } catch (_) {}
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.t('loginSuccessful')),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to Home
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainNavScreen()),
          (r) => false,
        );
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
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});
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
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OtpVerifyScreen(isReset: true),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                ),
                child: Text(
                  context.l10n.t('resetPasswordLower'),
                  style: TextStyle(color: Colors.white),
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
class NewPasswordScreen extends StatelessWidget {
  const NewPasswordScreen({super.key});
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
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: context.l10n.t('newPassword'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: context.l10n.t('confirmPassword'),
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
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.l10n.t('passwordChanged')),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (r) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                ),
                child: Text(
                  context.l10n.t('createNewPassword'),
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
