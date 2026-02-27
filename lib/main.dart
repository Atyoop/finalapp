import 'dart:async';
import 'package:final88/screens/auth_screens.dart';

import 'package:flutter/material.dart';

void main() {
  runApp(const DrugSafeApp());
}

// --- 1. Colors & Theme ---
class AppColors {
  static const Color primaryTeal = Color(0xFF2C6E72);
  static const Color backgroundCream = Color(0xFFF9F7F2);
  static const Color textDark = Color(0xFF101010);
  static const Color textGrey = Color(0xFF888888);
}

// --- 2. Shared Widget (Image Placeholder) ---
class PlaceholderImageWidget extends StatelessWidget {
  final Color color;
  const PlaceholderImageWidget({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Center(child: Icon(Icons.science, size: 100, color: color)),
    );
  }
}

// --- 3. Main App ---
class DrugSafeApp extends StatelessWidget {
  const DrugSafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DrugSafe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.backgroundCream,
        primaryColor: AppColors.primaryTeal,
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

// --- 4. Splash Screen ---
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryTeal,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.medication_liquid,
                size: 60,
                color: AppColors.primaryTeal,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "DrugSafe",
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 5. Onboarding Screen ---
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final List<Map<String, String>> _data = [
    {
      "title": "Stay Safe with Drug Safe",
      "desc": "Check for harmful drug interactions instantly.",
    },
    {
      "title": "Here for You, Always",
      "desc": "Identify medications and never miss a dose again.",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Expanded(
              flex: 3,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (val) => setState(() => _currentPage = val),
                itemCount: _data.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: PlaceholderImageWidget(
                    color: index == 0 ? Colors.blue : Colors.purple,
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _data.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 5),
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? AppColors.primaryTeal
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              _data[_currentPage]["title"]!,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _data[_currentPage]["desc"]!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.textGrey),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentPage == _data.length - 1) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WelcomeScreen(),
                        ),
                      );
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeIn,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                  ),
                  child: Text(
                    _currentPage == _data.length - 1 ? "Get started" : "Next",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 6. Welcome Screen ---
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const Spacer(),
              const Expanded(
                flex: 3,
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: PlaceholderImageWidget(color: Colors.blueAccent),
                ),
              ),
              const Text(
                "Welcome to Drug Save!",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Your Smart Health Companion",
                style: TextStyle(fontSize: 16, color: AppColors.textGrey),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SignupScreen(),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                  ),
                  child: const Text(
                    "Create an account",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primaryTeal),
                  ),
                  child: const Text(
                    "Log in",
                    style: TextStyle(color: AppColors.primaryTeal),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
