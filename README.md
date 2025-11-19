# SweatLock – Official README
*The app that makes you earn your screen time with real push-ups*

<img src="https://i.ibb.co/0jY7K7Z/sweatlock-banner.png" alt="SweatLock" width="100%"/>

**Turn doomscrolling into gains.**  
SweatLock blocks your addictive apps (TikTok, Instagram, YouTube, X, etc.) until you complete real, camera-tracked exercises: push-ups, squats, jumping jacks, or sit-ups.

**No reps → No apps.**

## Features (MVP – Launch Ready)

- Lock any app until you complete the required exercise  
- Real-time rep counting using Google ML Kit Pose Detection (on-device, no cheating)  
- Proper form feedback (“Chest to ground!”, “Thighs parallel!”)  
- Auto-plays your Spotify/Apple Music workout playlist  
- Daily & lifetime stats (total push-ups to open memes)  
- Gamification: streaks, badges, confetti on unlock  
- One emergency unlock per day  
- Fully offline after first setup  

## Tech Stack

| Layer                  | Technology                                      |
|------------------------|-------------------------------------------------|
| Frontend               | Flutter 3.24+ (Dart 3)                          |
| Architecture           | Layer-First / Clean Architecture               |
| State Management       | Provider + ChangeNotifier                       |
| Local Database         | Hive                                            |
| Pose Detection         | Google ML Kit Pose Detection (on-device)        |
| Camera                 | camera package                                  |
| Backend                | Node.js (NestJS or Express) + PostgreSQL        |
| ORM                    | Prisma                                          |
| Authentication         | Firebase Authentication                         |
| Analytics & Crash      | Firebase Analytics + Crashlytics                |
| App Blocking (Android) | Accessibility Service + Usage Stats             |
| App Blocking (iOS)     | Guided Access + Shortcuts Automation (user-enabled) |
| Music Integration      | Spotify/Apple Music deep links + just_audio     |
| Payments (future)      | RevenueCat                                      |
| CI/CD                  | GitHub Actions + Codemagic                      |

## Project Structure (Layer-First)

lib/
├── main.dart
├── core/                    # constants, errors, extensions
├── data/
│   ├── local/               # Hive boxes & adapters
│   ├── remote/              # Dio client, API services
│   └── repositories_impl/  # Concrete repository implementations
├── domain/
│   ├── entities/            # Pure Dart models
│   ├── repositories/        # Abstract repository interfaces
│   └── usecases/            # Business logic (CountReps, UnlockApp, etc.)
├── presentation/
│   ├── providers/           # All ChangeNotifier classes
│   ├── screens/             # Onboarding, Dashboard, LockScreen, Stats
│   ├── widgets/             # Reusable UI (RepCounter, PoseOverlay, Confetti)
│   └── theme/               # AppTheme, colors, typography
└── injection.dart           # MultiProvider setup


## Prerequisites

- Flutter 3.24+  
- Dart 3.3+  
- Android Studio / Xcode  
- Node.js 18+ (for backend)  
- PostgreSQL (local or hosted on Railway/Supabase)  
- Firebase project (Auth + Analytics + Crashlytics)

## Quick Start (Mobile)

```bash
# Clone repo
git clone https://github.com/destinyed/sweatlock.git
cd sweatlock

# Get dependencies
flutter pub get

# Run on device/simulator
flutter run
```

## Firebase Setup

Create a Firebase project at https://console.firebase.google.com
Enable Authentication (Anonymous + Google + Apple Sign-in)
Add iOS & Android apps
Download google-services.json (Android) and GoogleService-Info.plist (iOS)
Enable Analytics & Crashlytics

## Contributing

We welcome contributions!

Fork → Create feature branch → Open PR
Follow existing code style
Write tests for new features (test folder coming soon)

## Premium Features (Planned)

Unlimited emergency unlocks
Custom exercises & per-app rep requirements
Friends accountability mode
Advanced stats & CSV export
Extra themes (“Beast Mode Black”, etc.)

## License

MIT License © 2025 SweatLock