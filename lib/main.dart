import 'dart:async';

import 'package:final88/screens/auth_screens.dart';
import 'screens/home.dart';
import 'services/hive_service.dart';
import 'services/medicine_storage_service.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

const String _hasSeenOnboardingKey = 'hasSeenOnboarding';
const String _hasSeenFirstMedicationSetupKey = 'hasSeenFirstMedicationSetup';
const String _hasSeenReminderPermissionSetupKey =
    'hasSeenReminderPermissionSetup';

void main() async {
  // Initialize Flutter binding
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Hive local database
  await HiveService.init();

  // Initialize Language Service (persisted language)
  await LanguageService.init();

  // Initialize notifications service
  final notificationsProvider = NotificationsProvider();
  await notificationsProvider.initialize();

  // Notification verification and backend reconciliation continue without
  // delaying the first visible frame.
  unawaited(_initializeNotificationsInBackground(notificationsProvider));

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(
          create: (_) =>
              MedicineProvider()
                ..onMedicationChanged = (token) =>
                    notificationsProvider.refreshNotifications(token),
        ),
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

Future<void> _initializeNotificationsInBackground(
  NotificationsProvider notificationsProvider,
) async {
  try {
    await notificationsProvider.verifyNotificationSystem();
    await notificationsProvider.checkPendingNotifications();
    await notificationsProvider.rescheduleAllAfterBoot();

    final token = MedicineStorageService.getSetting<String>('auth_token');
    if (token == null || token.isEmpty || JwtDecoder.isExpired(token)) return;

    await notificationsProvider.fetchAndScheduleNotifications(token);
    debugPrint('[Startup] Notification schedule reconciliation complete');
  } catch (error, stackTrace) {
    debugPrint(
      '[Startup] Background notification initialization failed: $error',
    );
    debugPrint('$stackTrace');
  }
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
            appBarTheme: const AppBarTheme(
              systemOverlayStyle: SystemUiOverlayStyle.dark,
            ),
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}

Future<void> _showReminderPermissionSetupIfNeeded(BuildContext context) async {
  final alreadyShown =
      MedicineStorageService.getSetting<bool>(
        _hasSeenReminderPermissionSetupKey,
      ) ??
      false;
  if (alreadyShown || !context.mounted) return;

  final shouldRequest = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(dialogContext.l10n.t('enableReminders')),
      content: Text(
        '${dialogContext.l10n.t('notificationPermissionExplanation')}\n\n'
        '${dialogContext.l10n.t('batteryOptimizationExplanation')}',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(
            dialogContext.l10n.t('notNow'),
            style: TextStyle(color: AppColors.textGrey),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryTeal,
          ),
          child: Text(
            dialogContext.l10n.t('continueLabel'),
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    ),
  );

  await MedicineStorageService.saveSetting(
    _hasSeenReminderPermissionSetupKey,
    true,
  );

  if (shouldRequest == true && context.mounted) {
    await context.read<NotificationsProvider>().requestReminderPermissions();
  }
}

Future<void> continueAfterAuth(
  BuildContext context, {
  required bool isNewRegistration,
}) async {
  await _showReminderPermissionSetupIfNeeded(context);
  if (!context.mounted) return;

  final token = context.read<UserProvider>().token;
  if (token != null && token.isNotEmpty) {
    unawaited(
      context.read<NotificationsProvider>().fetchAndScheduleNotifications(
        token,
      ),
    );
  }

  final showFirstMedicationSetup =
      isNewRegistration &&
      !(MedicineStorageService.getSetting<bool>(
            _hasSeenFirstMedicationSetupKey,
          ) ??
          false);

  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder: (_) => showFirstMedicationSetup
          ? const FirstMedicationSetupScreen()
          : const MainNavScreen(),
    ),
    (route) => false,
  );
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
    Future.delayed(const Duration(milliseconds: 6000), () {
      if (!mounted) return;
      final userProvider = context.read<UserProvider>();
      final hasSeenOnboarding =
          MedicineStorageService.getSetting<bool>(_hasSeenOnboardingKey) ??
          false;
      final Widget nextScreen;
      if (userProvider.isLoggedIn) {
        nextScreen = const MainNavScreen();
      } else if (hasSeenOnboarding) {
        nextScreen = const WelcomeScreen();
      } else {
        nextScreen = const OnboardingScreen();
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => nextScreen),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(60),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(60),
                child: Image.asset(
                  'assets/icon/drugsafe_logo.jpg',

                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.error, size: 60, color: Colors.red),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "DrugSafe",
              style: TextStyle(
                color: AppColors.textDark,
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
  List<_OnboardingPageData> _pages(BuildContext context) => [
    _OnboardingPageData(
      title: context.l10n.t('neverMissDose'),
      subtitle: context.l10n.t('smartReminderOnboarding'),
      icon: Icons.notifications_active_outlined,
      color: Color(0xFF2C6E72),
    ),
    _OnboardingPageData(
      title: context.l10n.t('checkMedicationRisks'),
      subtitle: context.l10n.t('checkMedicationRisksBody'),
      icon: Icons.health_and_safety_outlined,
      color: Color(0xFF5867B1),
    ),
    _OnboardingPageData(
      title: context.l10n.t('manageYourPharmacy'),
      subtitle: context.l10n.t('manageYourPharmacyBody'),
      icon: Icons.inventory_2_outlined,
      color: Color(0xFFB56F45),
    ),
  ];

  Future<void> _finishOnboarding() async {
    await MedicineStorageService.saveSetting(_hasSeenOnboardingKey, true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = _pages(context);
    final page = pages[_currentPage];
    final isLastPage = _currentPage == pages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: TextButton(
                  onPressed: _finishOnboarding,
                  child: Text(
                    context.l10n.t('skip'),
                    style: TextStyle(color: AppColors.textGrey),
                  ),
                ),
              ),
            ),
            const Spacer(),
            Expanded(
              flex: 3,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (val) => setState(() => _currentPage = val),
                itemCount: pages.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.all(36.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: pages[index].color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        pages[index].icon,
                        size: 96,
                        color: pages[index].color,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pages.length,
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
              page.title,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                page.subtitle,
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
                    if (isLastPage) {
                      _finishOnboarding();
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
                    isLastPage
                        ? context.l10n.t('getStarted')
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

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
}

class FirstMedicationSetupScreen extends StatelessWidget {
  const FirstMedicationSetupScreen({super.key});

  Future<void> _continue(
    BuildContext context, {
    required bool openAddMedication,
  }) async {
    await MedicineStorageService.saveSetting(
      _hasSeenFirstMedicationSetupKey,
      true,
    );
    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => MainNavScreen(initialIndex: openAddMedication ? 3 : 0),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.medication_outlined,
                      color: AppColors.primaryTeal,
                      size: 42,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    context.l10n.t('addFirstMedication'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.l10n.t('addFirstMedicationBody'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.45,
                      color: AppColors.textGrey,
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () =>
                          _continue(context, openAddMedication: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                      ),
                      child: Text(
                        context.l10n.t('addMedicine'),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton(
                      onPressed: () =>
                          _continue(context, openAddMedication: false),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.primaryTeal),
                      ),
                      child: Text(
                        context.l10n.t('skipForNow'),
                        style: const TextStyle(color: AppColors.primaryTeal),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
