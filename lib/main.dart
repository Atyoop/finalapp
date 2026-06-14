import 'package:final88/screens/auth_screens.dart';
import 'screens/home.dart';
import 'services/hive_service.dart';
import 'services/medicine_storage_service.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/medicine_provider.dart';
import 'providers/user_provider.dart';
import 'providers/saved_medicines_provider.dart';
import 'providers/alerts_provider.dart';
import 'providers/notifications_provider.dart';
import 'providers/support_provider.dart';
import 'providers/premium_provider.dart';
import 'services/language_service.dart';
import 'providers/language_provider.dart';
import 'l10n/app_localizations.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // Initialize Flutter binding
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive local database
  await HiveService.init();

  // Initialize Language Service (persisted language)
  await LanguageService.init();

  // Initialize notifications service
  final notificationsProvider = NotificationsProvider();
  await notificationsProvider.initialize();

  // Verify notification system
  await notificationsProvider.verifyNotificationSystem();
  await notificationsProvider.checkPendingNotifications();

  // Reschedule any local reminders after app start / boot
  await notificationsProvider.rescheduleAllAfterBoot();

  // Automatically fetch notification schedules if a valid stored session exists.
  // Awaited so that timezone is guaranteed initialized before zonedSchedule runs.
  final String? token = MedicineStorageService.getSetting<String>('auth_token');
  if (token != null && token.isNotEmpty) {
    try {
      if (!JwtDecoder.isExpired(token)) {
        debugPrint('[Startup] 🔑 Stored token valid — fetching notification schedules...');
        await notificationsProvider.fetchAndScheduleNotifications(token);
        debugPrint('[Startup] ✅ Startup notification schedule complete');
      } else {
        debugPrint('[Startup] ⏳ Stored token is expired, skipping notifications fetch.');
      }
    } catch (e) {
      debugPrint('[Startup] ❌ Error fetching notifications on startup: $e');
    }
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => MedicineProvider()..onMedicationChanged = (token) => notificationsProvider.refreshNotifications(token)),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => SavedMedicinesProvider()),
        ChangeNotifierProvider(create: (_) => AlertsProvider()),
        ChangeNotifierProvider(create: (_) => notificationsProvider),
        ChangeNotifierProvider(create: (_) => SupportProvider()),
        ChangeNotifierProvider(create: (_) => PremiumProvider()),
      ],
      child: const DrugSafeApp(),
    ),
  );
}

// --- 1. Colors & Theme ---
class AppColors {
  static const Color primaryTeal = Color(0xFF2C6E72);
  static const Color backgroundCream = Color(0xFFF9F7F2);
  static const Color textDark = Color(0xFF101010);
  static const Color textGrey = Color(0xFF888888);
  static const Color cardColor = Colors.white;
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
        color: color.withValues(alpha: 0.2),
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
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          onGenerateTitle: (context) => context.l10n.t('appName'),
          debugShowCheckedModeBanner: false,
          locale: Locale(languageProvider.currentLanguage),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) => Directionality(
            textDirection: languageProvider.textDirection,
            child: child ?? const SizedBox.shrink(),
          ),
          theme: ThemeData(
            scaffoldBackgroundColor: AppColors.backgroundCream,
            primaryColor: AppColors.primaryTeal,
            useMaterial3: true,
          ),
          home: const SplashScreen(),
        );
      },
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
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.isLoggedIn) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      }
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
              child: Icon(
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
  final List<Map<String, String>> _data = const [
    {"title": "staySafeTitle", "desc": "staySafeDesc"},
    {"title": "alwaysHereTitle", "desc": "alwaysHereDesc"},
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
              context.l10n.t(_data[_currentPage]["title"]!),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                context.l10n.t(_data[_currentPage]["desc"]!),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textGrey),
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
                    _currentPage == _data.length - 1
                        ? context.l10n.t('getStartedLower')
                        : context.l10n.t('next'),
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
              Text(
                context.l10n.t('welcomeTitle'),
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.t('welcomeSubtitle'),
                style: TextStyle(fontSize: 16, color: AppColors.textGrey),
                textAlign: TextAlign.center,
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
                  child: Text(
                    context.l10n.t('createAccount'),
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
                    side: BorderSide(color: AppColors.primaryTeal),
                  ),
                  child: Text(
                    context.l10n.t('login'),
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

void triggerGlobalLogout() {
  final context = navigatorKey.currentContext;
  if (context != null) {
    try {
      Provider.of<UserProvider>(context, listen: false).logout();
    } catch (_) {}
    try {
      Provider.of<MedicineProvider>(context, listen: false).clearLocalData();
    } catch (_) {}
    try {
      Provider.of<SavedMedicinesProvider>(context, listen: false).clear();
    } catch (_) {}
    try {
      Provider.of<AlertsProvider>(context, listen: false).clear();
    } catch (_) {}
    try {
      Provider.of<NotificationsProvider>(context, listen: false).clearAll();
    } catch (_) {}
    try {
      Provider.of<PremiumProvider>(context, listen: false).clear();
    } catch (_) {}
    try {
      Provider.of<SupportProvider>(context, listen: false).clear();
    } catch (_) {}

    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.t('sessionExpired')),
        backgroundColor: Colors.red,
      ),
    );
  }
}
