# DrugSafe Flutter App - Project Brief

## 🎯 Project Overview
**Name**: final88 (DrugSafe)  
**Type**: Flutter Mobile Application  
**Platform**: Android, iOS, Linux, macOS, Windows  
**Version**: 1.0.0+1  
**SDK**: Dart 3.8.1+  

**Purpose**: A comprehensive medication reminder and drug interaction warning app that helps users:
- Manage medication schedules and reminders
- Scan medicine packages (OCR)
- Detect drug-drug interactions
- Receive local notifications for medication times
- Track medication history and adherence
- Get medication recommendations and information
- Manage personal health information

---

## 📦 Tech Stack

### Core Framework
- **Flutter**: Latest version
- **Dart**: 3.8.1+
- **Provider**: ^6.1.5+1 (State Management)

### Key Dependencies
- **HTTP Client**: `dio: ^5.2.1`, `http: ^1.2.0`
- **Notifications**: `flutter_local_notifications: ^18.0.0`
- **Timezone**: `timezone: ^0.10.0`, `flutter_timezone: ^4.0.2`
- **Image Processing**: `image_picker: ^1.2.1`
- **Persistence**: `shared_preferences: ^2.2.3`
- **Localization**: `intl: ^0.20.2`, `flutter_localizations`
- **UI**: `cupertino_icons: ^1.0.8`
- **HTTP Parsing**: `http_parser: ^4.1.2`

### Development
- `flutter_lints: ^5.0.0` (Code quality)

---

## 📁 Project Structure

```
lib/
├── main.dart                          # App entry point, theme config, MultiProvider setup
├── models/                            # Data models
│   ├── alert.dart                     # Alert model
│   ├── medicine.dart                  # Medicine data model
│   ├── medicine_scan_response.dart    # OCR scan response model
│   ├── notification_schedule.dart     # Medication schedule/reminder model
│   ├── premium_status.dart            # Premium subscription status
│   └── support_ticket.dart            # Support/Help ticket model
├── providers/                         # State management (ChangeNotifier)
│   ├── language_provider.dart         # App language state
│   ├── medicine_provider.dart         # Medicine data management
│   ├── user_provider.dart             # User authentication & profile
│   ├── saved_medicines_provider.dart  # Saved medicines library
│   ├── alerts_provider.dart           # Drug interaction alerts
│   ├── notifications_provider.dart    # Notification scheduling & management
│   ├── support_provider.dart          # Support/Help features
│   └── premium_provider.dart          # Premium features & payments
├── screens/                           # UI Screens
│   ├── auth_screens.dart              # Login/Register/Auth flows
│   ├── home_screen.dart               # Home/Today view (main medication dashboard)
│   ├── home.dart                      # Home navigation hub
│   ├── add_medicine_screen.dart       # Add new medication
│   ├── add_reminder_screen.dart       # Add medication reminders
│   ├── medicine_scan_screen.dart      # Medicine OCR scanning
│   ├── scan_camera.dart               # Camera integration for scanning
│   ├── scan_screen.dart               # Scan results display
│   ├── drug_detail_screen.dart        # Drug information details
│   ├── interaction_screen.dart        # Drug-drug interactions view
│   ├── saved_medicines_screen.dart    # Saved medicines library
│   ├── reminders_screen.dart          # All reminders/schedules
│   ├── reminder_preferences_screen.dart # Customize reminders
│   ├── notifications_screen.dart      # Notification history
│   ├── notification_setting_screen.dart # Notification settings
│   ├── chatbot_screen.dart            # AI chatbot for drug info
│   ├── profile_screen.dart            # User profile & settings
│   ├── edit_profile_screen.dart       # Edit profile information
│   ├── personal_details_screen.dart   # Personal health details
│   ├── change_password_screen.dart    # Password management
│   ├── privacy_security_screen.dart   # Privacy & security settings
│   ├── appearance_screen.dart         # Theme/language preferences
│   ├── premium_screen.dart            # Premium features/subscription
│   ├── support_screen.dart            # Help & support
│   └── privacy_policy_screen.dart     # Legal documents
├── services/                          # Business logic & API services
│   ├── language_service.dart          # Language persistence
│   └── notification_service.dart      # Local notifications engine
├── utils/                             # Utility functions & helpers
└── widgets/                           # Reusable UI components
    ├── interaction_warning_badge.dart # Warning indicator for drug interactions
    └── interaction_bottom_sheet.dart  # Interaction details modal
```

---

## 🎨 Key Features

### 1. **Medication Management**
- Add medications manually or via OCR scanning
- Set up medication reminders with time schedules
- Categorize and organize medicines
- Track medication history

### 2. **Smart Notifications**
- Local push notifications for medication reminders
- Timezone-aware scheduling using `timezone` package
- Background notification delivery on Android
- Auto-reschedule notifications after device boot
- Test notification functionality in debug mode

### 3. **Drug Interaction Detection**
- Real-time drug-drug interaction checking
- Clean, modern warning UI on medication cards
- Compact warning badges showing interaction count
- Detailed interaction information in bottom sheets
- Takes Dose dialog includes interaction warnings

### 4. **Medicine Database**
- Comprehensive drug information
- Medical details and dosage info
- Alternative names and drug synonyms
- Contraindications and warnings

### 5. **OCR Medicine Scanning**
- Camera-based medicine package scanning
- Extract medicine details from package images
- Pre-fill medication form with scan results

### 6. **User Profiles & Security**
- User authentication system
- Profile management
- Personal health information storage
- Change password functionality
- Privacy & security settings

### 7. **Language & Localization**
- Multi-language support (Arabic, English, etc.)
- Persistent language preferences
- Flutter localization framework

### 8. **Premium Features**
- Subscription management
- In-app payment system (fake payment for testing)
- Premium-only features access control

### 9. **Support & Help**
- In-app chatbot for drug information
- Support ticket system
- Help documentation
- Contact support functionality

---

## 🔑 Important Implementations

### Notifications System (IMPLEMENTED)
**Status**: ✅ Complete with advanced features

**Features**:
- Timezone-aware scheduling with `flutter_timezone` detection
- Android notification channel setup with max importance
- Android boot receiver for post-restart rescheduling
- Background notification delivery using `exactAllowWhileIdle`
- Test utilities in Settings → Debug & Test
- Comprehensive logging with emoji indicators

**Android Permissions** (AndroidManifest.xml):
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```

**Notification Service Methods**:
- `initialize()` - Setup timezone and notification channel
- `scheduleNotifications(schedule)` - Schedule medication reminders
- `testInstantNotification()` - Send test notification immediately
- `testNotificationAfterDelay(duration)` - Test delayed notification
- `getPendingNotifications()` - List all scheduled notifications
- `cancelAllNotifications()` / `cancelNotification(id)` - Cancel notifications
- `verifyNotificationSystem()` - Debug verification

---

### Drug Interaction Warning UI (IMPLEMENTED)
**Status**: ✅ Complete with clean UI design

**Components Created**:

1. **`interaction_warning_badge.dart`**
   - Small icon badge (top-right of medication card)
   - Shows interaction count (only if count > 0)
   - Orange warning color (#FF9800)
   - Tappable to open details

2. **`interaction_bottom_sheet.dart`**
   - Full-screen bottom sheet for interaction details
   - Shows medication name + all interactions
   - Lists: interacting drug name + reason
   - Info disclaimer box with healthcare provider note
   - Orange theme matching warning badge
   - Scrollable content for many interactions

3. **Home Screen Integration**:
   - Medication cards display orange warning badge when `hasInteractions == true`
   - Info note below card: "Tap the warning badge to view interactions"
   - Badge tap opens `InteractionBottomSheet`
   - Take Dose modal includes dedicated "Drug Interactions Detected" section

**Data Model** (from TodaySchedule):
```dart
class TodaySchedule {
  bool hasInteractions;
  List<Map<String, String>> interactions; // Format: {'withMedication': 'X', 'reason': 'Y'}
}
```

**UI Behavior**:
- Card level: Small orange badge only appears if interactions exist
- Non-blocking: Interactions don't prevent Take/Snooze/Skip actions
- Two-level display: Badge on card + full details in bottom sheet
- User-initiated: Only opens when user taps (no auto-popup)

---

## 📊 Data Models

### Medicine Model
```dart
class Medicine {
  String id;
  String name;
  String genericName;
  String dosage;
  String form; // tablet, capsule, liquid, etc.
  String manufacturer;
  List<String> indications; // uses/conditions
  List<String> contraindications; // warnings
  String storageInstructions;
  // ... more fields
}
```

### Notification Schedule Model
```dart
class NotificationSchedule {
  String id;
  String medicineId;
  String medicineName;
  DateTime nextDose;
  String frequency; // daily, twice daily, etc.
  String time;
  bool isActive;
  bool hasInteractions; // NEW
  List<Map<String, String>> interactions; // NEW: [{'withMedication': 'X', 'reason': 'Y'}]
  // ... more fields
}
```

### Alert Model
```dart
class Alert {
  String id;
  String title;
  String description;
  String severity; // low, medium, high
  DateTime createdAt;
  bool isRead;
}
```

### Premium Status Model
```dart
class PremiumStatus {
  bool isPremium;
  DateTime? expiryDate;
  String? subscriptionPlan;
}
```

### Support Ticket Model
```dart
class SupportTicket {
  String id;
  String subject;
  String message;
  String status; // open, in_progress, resolved
  DateTime createdAt;
}
```

---

## 🏗️ Architecture

### State Management
- **Provider Pattern**: ChangeNotifier providers for reactive state
- **MultiProvider**: Multiple providers injected at app root
- **Separation of Concerns**: Providers, services, and UI layers separated

### Providers
1. **LanguageProvider** - Language/localization state
2. **MedicineProvider** - Medicine database and search
3. **UserProvider** - Authentication and user profile
4. **SavedMedicinesProvider** - User's saved medicines
5. **AlertsProvider** - Drug interaction alerts
6. **NotificationsProvider** - Notification scheduling and management
7. **SupportProvider** - Support tickets and help
8. **PremiumProvider** - Premium features and subscription

### Services
- **LanguageService** - Persistent language settings (SharedPreferences)
- **NotificationService** - Local notifications with timezone support

### API Integration
- Uses `dio` and `http` packages for HTTP requests
- No Firebase (local notifications only)
- Error handling and logging implemented

---

## 🎨 Theme & Design

### Colors (defined in main.dart)
```dart
class AppColors {
  // Primary, secondary, accent colors
  // Warning: Orange (#FF9800, #FFF3E0)
  // Error, success, background colors
  // Dialog, card, and surface colors
}
```

### Typography
- Material Design principles
- Responsive text scaling
- RTL support (for Arabic)

### Localization
- English & Arabic support (expandable)
- Flutter localization with `intl` package
- Persistent language preference

---

## 📱 Screens Overview

### Authentication Flow
- **auth_screens.dart**: Login, Register, Password reset

### Main Navigation
- **home.dart**: Navigation hub
- **home_screen.dart**: Today/Home dashboard (medication schedule)

### Medicine Management
- **add_medicine_screen.dart**: Add new medicine
- **medicine_scan_screen.dart**: Scan medicine packages
- **scan_camera.dart**: Camera interface for OCR
- **drug_detail_screen.dart**: Medicine information details
- **saved_medicines_screen.dart**: Medicine library

### Reminders & Notifications
- **add_reminder_screen.dart**: Create medication reminders
- **reminders_screen.dart**: View all medication schedules
- **reminder_preferences_screen.dart**: Customize reminder settings
- **notifications_screen.dart**: Notification history
- **notification_setting_screen.dart**: Notification preferences

### Interactions & Safety
- **interaction_screen.dart**: View drug-drug interactions

### User Profile & Settings
- **profile_screen.dart**: User profile dashboard
- **edit_profile_screen.dart**: Edit profile information
- **personal_details_screen.dart**: Health details
- **change_password_screen.dart**: Password management
- **appearance_screen.dart**: Theme/language preferences
- **privacy_security_screen.dart**: Security settings

### Support & Premium
- **chatbot_screen.dart**: AI chatbot for medicine information
- **support_screen.dart**: Help & contact support
- **premium_screen.dart**: Premium features and subscription
- **fake_payment_screen.dart**: Test payment system

### Legal
- **privacy_policy_screen.dart**: Privacy policy document

---

## 🔧 Configuration Files

### pubspec.yaml
- **App ID**: final88
- **Environment**: SDK ^3.8.1
- **Publishing**: Set to 'none' (private package)
- **Material Icons**: Enabled

### analysis_options.yaml
- Dart linting rules

### devtools_options.yaml
- DevTools configuration

### Android Configuration
- **gradle.properties**: Build configuration
- **build.gradle.kts**: Gradle build system
- **AndroidManifest.xml**: Permissions and manifest
- **NotificationBootReceiver.kt**: Boot completion handling

### iOS Configuration
- **Runner.xcodeproj**: iOS project configuration
- **AppDelegate.swift**: iOS app delegate
- **podspec**: Dependency management

---

## 🚀 Initialization Flow

```
main() 
  ↓
WidgetsFlutterBinding.ensureInitialized()
  ↓
LanguageService.init() (load persisted language)
  ↓
NotificationsProvider.initialize() 
  (setup timezone, notification channel, register callback)
  ↓
NotificationsProvider.verifyNotificationSystem() (debug check)
  ↓
NotificationsProvider.checkPendingNotifications() (debug check)
  ↓
MultiProvider setup with all providers
  ↓
DrugSafeApp() (main app widget)
```

---

## 🐛 Debug & Testing Features

Located in **Settings → Debug & Test**:
1. "Test Instant Notification" - Send test notification immediately
2. "Test Delayed Notification" - Schedule test after 10 seconds
3. "Refresh Medication Notifications" - Fetch and reschedule all notifications
4. "Cancel All Notifications" - Clear all scheduled notifications

All operations log with emoji indicators for easy debugging:
- 🚀 Initialization
- ✅ Success
- ❌ Error
- 📲 Notification tap
- ⏰ Scheduling

---

## 📋 Known Implementation Details

### Home Screen (Today/Home Dashboard)
- Shows today's medication schedule in card format
- Each medication card displays:
  - Medicine name and dosage
  - Next dose countdown
  - Status badge (Taken, Missed)
  - Stock warnings (if low)
  - **Drug interaction warning badge** (if interactions exist)
  - Action buttons (Take, Snooze, Skip)
- Bottom sheet for Take Dose action includes all details and interactions

### Notification System
- Timezone-aware: Uses device's local timezone
- Android: Uses exactAllowWhileIdle for reliability
- Boot Receiver: Reschedules after device restart
- Payload: Supports custom data for tap handling

### Drug Interaction Detection
- Integrated into home screen medication cards
- Non-blocking: Info only, doesn't prevent actions
- Visual hierarchy: Badge on card → details in bottom sheet
- Take Dose dialog includes full interaction section

---

## 🔐 Security & Privacy

- Persists sensitive data locally (SharedPreferences)
- No Firebase or external analytics
- Privacy policy accessible in app
- Change password functionality
- Privacy & security settings screen

---

## 🌍 Localization

- **Supported Languages**: English, Arabic (expandable)
- **Framework**: Flutter localization with intl package
- **Persistence**: Language preference saved locally
- **RTL Support**: Arabic right-to-left text handling

---

## 📞 Support & Help

- In-app chatbot for medicine information queries
- Support ticket system for user issues
- Contact support functionality
- Help documentation

---

## ⚠️ Current Status & Next Steps

**Completed Features**:
✅ Medicine management (add, edit, delete)
✅ OCR medicine scanning
✅ Local notifications with timezone support
✅ Drug interaction warnings and UI
✅ User authentication
✅ Profile management
✅ Localization (Arabic/English)
✅ Premium subscription system
✅ Support/Help system
✅ Debug testing utilities

**Known Issues/Areas**:
- [Note any known bugs or areas needing attention]
- [If specific issues exist, list them here]

---

## 📝 Code Style & Conventions

- **Naming**: camelCase for variables/functions, PascalCase for classes
- **Formatting**: Dart style guide compliant
- **Error Handling**: Try-catch with proper logging
- **Comments**: Emoji indicators for quick visual scanning
- **Provider Pattern**: ChangeNotifier with ChangeNotifierProvider
- **Async**: Proper async/await patterns with error handling

---

## 🔗 Important Files to Reference

When working with this codebase, key files to reference:
- `lib/main.dart` - Theme, colors, initialization, app entry
- `lib/screens/home_screen.dart` - Main medication dashboard
- `lib/providers/notifications_provider.dart` - Notification logic
- `lib/providers/alerts_provider.dart` - Drug interaction logic
- `lib/services/notification_service.dart` - Notification engine
- `lib/widgets/interaction_warning_badge.dart` - Interaction UI
- `pubspec.yaml` - Dependencies and project configuration
- `android/app/src/main/AndroidManifest.xml` - Android permissions
- `.android/app/src/main/kotlin/.../NotificationBootReceiver.kt` - Boot handling

---

## 💡 Tips for Development

1. **Testing Notifications**: Use debug features in Settings
2. **Hot Reload**: Use `flutter run` with hot reload enabled
3. **Device Testing**: Test on both Android and iOS devices
4. **Localization**: Remember to add strings to localization files
5. **Provider Access**: Use `Provider.of<T>(context)` or `context.read<T>()`
6. **Error Logs**: Look for emoji indicators in logs for debugging

---

**Last Updated**: May 25, 2026
**Project Version**: 1.0.0+1
**Dart Version**: 3.8.1+
