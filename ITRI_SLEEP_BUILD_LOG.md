# Itri Sleep — Build Log & Handoff Document
> **Read this at the start of every new session.** It contains the full project state, what has been done, what is next, and all conventions used.

**Project:** CO3008 Honours Project — AI Sleep Analysis Mobile App  
**Student:** Mehdi Touhami · `touhamimehdigpt2@gmail.com`  
**Stack:** Flutter (Dart) · Python FastAPI · GPT-4o mini · Garmin CSV data · Random Forest (R²=0.969)  
**Real project path:** `~/Desktop/MehdiTouhamiFinal/sleepapp/` ← always work here  
**Reference folder:** `~/Desktop/Sleep analysis app RAG/` ← flat file copies only, not the real project  
**Run app:** `cd ~/Desktop/MehdiTouhamiFinal/sleepapp && flutter run` → choose Chrome  
**After pubspec changes:** `flutter pub get` inside `sleepapp/`  
**Hot reload:** `r` · **Full restart:** `R` (required after model/provider changes)

---

## Complete File Tree (current state)

```
sleepapp/
├── lib/
│   ├── main.dart                            ✅ ProviderScope → ItriSleepApp → AppTheme.dark()
│   ├── core/
│   │   ├── data/
│   │   │   └── sleep_repository.dart        ✅ Loads all 30 CSVs, static cache, newest-first sort
│   │   ├── models/
│   │   │   └── sleep_night.dart             ✅ 13 fields incl. bodyBattery + respiration
│   │   ├── providers/
│   │   │   └── sleep_provider.dart          ✅ sleepDataProvider, latestNightProvider, recentNightsProvider
│   │   ├── services/
│   │   │   ├── ai_service.dart              ⚠️  API KEY HARDCODED — fix before any git push
│   │   │   └── insights_service.dart        ✅ Uses shared durationToMinutes
│   │   ├── theme/
│   │   │   ├── app_colors.dart              ✅ All design tokens as static const
│   │   │   └── app_theme.dart               ✅ Full ThemeData: Inter, NavBar, ColorScheme
│   │   └── utils/
│   │       └── duration_utils.dart          ✅ durationToMinutes() + minutesToDuration()
│   ├── screens/
│   │   ├── app_shell.dart                   ✅ IndexedStack + _NavBar (outlined/filled icons)
│   │   ├── splash_screen.dart               ✅ Animated logo scale+fade, text slide-up, fade nav
│   │   ├── dashboard_screen.dart            ✅ ConsumerWidget using sleepDataProvider
│   │   ├── insights_screen.dart             ✅ ConsumerWidget using sleepDataProvider
│   │   ├── schedule_screen.dart             ✅ ConsumerWidget — goals still hardcoded (Step 9)
│   │   ├── coach_screen.dart                ✅ ConsumerStatefulWidget using sleepDataProvider
│   │   └── sleep_detail_screen.dart         ✅ Uses ScoreRing + MetricCard
│   └── widgets/
│       ├── glass_card.dart                  (original, untouched)
│       ├── sleep_score_ring.dart            ⚠️  DEAD CODE — superseded by score_ring.dart, delete it
│       ├── sleep_stage_timeline.dart        (original, untouched)
│       ├── score_ring.dart                  ✅ Reusable ScoreRing (size, strokeWidth, showLabel)
│       └── metric_card.dart                 ✅ Reusable MetricCard (icon, title, value, subtitle)
├── assets/data/
│   └── Sleep-1.csv … Sleep-30.csv          ✅ All 30 declared in pubspec.yaml
└── pubspec.yaml                             ✅ See dependencies section below
```

---

## pubspec.yaml — Current Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.0
  fl_chart: ^0.68.0
  flutter_riverpod: ^2.5.1
  google_fonts: ^6.2.1
  cupertino_icons: ^1.0.8
```

### Packages still to add

| Package | Version | Purpose | Step |
|---|---|---|---|
| `flutter_dotenv` | `^5.1.0` | Secure API key management | ASAP |
| `shared_preferences` | `^2.3.0` | Persist user goals/settings | Step 9 |
| `go_router` | `^14.0.0` | Declarative navigation | Step 8 |
| `intl` | `^0.19.0` | Date formatting | Step 8 |
| `shimmer` | `^3.0.0` | Loading skeletons | Step 8 |
| `lottie` | `^3.1.0` | Lottie animations (optional) | Step 7+ |

---

## Design Tokens (AppColors)

| Token | Hex | Usage |
|---|---|---|
| `background` | `#0B1220` | Scaffold background |
| `surface` | `#121A2B` | Cards, panels |
| `surfaceAlt` | `#1A2540` | Lifted/elevated cards |
| `primary` | `#3B82F6` | Brand blue, buttons, selected nav |
| `accentCyan` | `#22D3EE` | Highlights |
| `accentBlue` | `#67D6FF` | Secondary accent |
| `deepSleep` | `#A98BFF` | Purple — deep sleep stage |
| `remSleep` | `#5AA8FF` | Blue — REM stage |
| `lightSleep` | `#35D0A5` | Teal-green — light sleep stage |
| `awake` | `#FF8FA3` | Pink-red — awake time |
| `textPrimary` | `#FFFFFF` | Main text |
| `textSecondary` | `#B0BEC5` | Labels, captions |
| `textMuted` | `#607080` | De-emphasised text |
| `divider` | `#1E2D45` | Borders, separators |
| `navBar` | `#0F1825` | Bottom nav background |

**Helper methods:**
- `AppColors.forScore(int score)` → green ≥80, blue ≥65, amber ≥50, red <50
- `AppColors.forStage(String stage)` → returns stage colour by name ("deep", "rem", "light", "awake")

---

## SleepNight Model

```dart
class SleepNight {
  final String date;           // "11/30/25" — MM/DD/YY Garmin format
  final String sleepDuration;  // "7h 30m"
  final int    sleepScore;     // 0–100
  final String quality;        // "Good" / "Fair" / "Poor"
  final String deepSleep;      // "1h 10m"
  final String lightSleep;     // "4h 00m"
  final String remSleep;       // "1h 20m"
  final String awakeTime;      // "22m"
  final String restingHR;      // "52"
  final String hrv;            // "56" — Avg Overnight HRV
  final String stressAvg;      // "20.68"
  final String bodyBattery;    // "34" — Body Battery Change
  final String respiration;    // "16.9" — Avg Respiration
}
```

**Garmin CSV column → model field mapping:**
```
Sleep Score          → sleepScore
Date                 → date
Sleep Duration       → sleepDuration  (appears twice in CSV, first occurrence wins)
Quality              → quality
Stress Avg           → stressAvg
Deep Sleep Duration  → deepSleep
Light Sleep Duration → lightSleep
REM Duration         → remSleep
Awake Time           → awakeTime
Resting Heart Rate   → restingHR
Avg Overnight HRV    → hrv
Body Battery Change  → bodyBattery
Avg Respiration      → respiration
```

---

## Riverpod Providers

```dart
// lib/core/providers/sleep_provider.dart

sleepRepositoryProvider          // Provider<SleepRepository>
sleepDataProvider                // FutureProvider<List<SleepNight>> — loads once, shared globally
latestNightProvider              // Provider<SleepNight?> — most recent night
recentNightsProvider(n)         // Provider.family<List<SleepNight>, int> — last N nights
```

**Standard screen pattern:**
```dart
class MyScreen extends ConsumerWidget {
  const MyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(sleepDataProvider).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:   (e, _) => Center(child: Text('Error: $e')),
      data:    (nights) {
        final latest = nights.first;
        // build UI
      },
    );
  }
}
```

**StatefulWidget pattern (e.g. CoachScreen):**
```dart
class MyScreen extends ConsumerStatefulWidget {
  const MyScreen({super.key});
  @override
  ConsumerState<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends ConsumerState<MyScreen> {
  @override
  Widget build(BuildContext context) {
    final nights = ref.watch(sleepDataProvider).asData?.value ?? [];
    // build UI with local state + provider data
  }
}
```

---

## What Has Been Completed

### ✅ Step 1 — Design System & Theme
- `lib/core/theme/app_colors.dart` — all tokens, `forScore()`, `forStage()` helpers
- `lib/core/theme/app_theme.dart` — full `ThemeData.dark()`: Inter font, `NavigationBarTheme` (64px, indicator, outlined↔filled icons), `ColorScheme`, `CardTheme`, `AppBarTheme`, `ChipTheme`, `SnackBarTheme`
- `google_fonts: ^6.2.1` added to pubspec

### ✅ Step 2 — Shared Utils
- `lib/core/utils/duration_utils.dart` — `durationToMinutes()` + `minutesToDuration()`
- Removed duplicate private functions from: `dashboard_screen`, `insights_screen`, `schedule_screen`, `sleep_detail_screen`, `coach_screen`, `insights_service`

### ✅ Step 3 — Shared Widgets
- `lib/widgets/score_ring.dart` — replaces 3 local `_ScoreRing` / `_InsightScoreRing` implementations. Args: `score`, `size` (default 84), `strokeWidth` (default 7), `showLabel` (default true). Colour from `AppColors.forScore()`.
- `lib/widgets/metric_card.dart` — replaces `_MiniCard` (dashboard) and `_MetricCard` (sleep_detail). Args: `icon`, `iconColor`, `title`, `value`, `subtitle`.
- Wired into `dashboard_screen`, `sleep_detail_screen`, `insights_screen`

### ✅ Step 4 — SleepRepository Fix
- Loads all 30 CSV files (was only loading Sleep-23 to Sleep-30)
- Parses `MM/DD/YY` date, sorts newest-first
- Static `_cache` — parsed once per session
- Graceful skip on missing/malformed files
- `SleepNight` model extended with `bodyBattery` + `respiration`

### ✅ Step 5 — State Management (Riverpod)
- `flutter_riverpod: ^2.5.1` added
- `ProviderScope` wraps app in `main.dart`
- `lib/core/providers/sleep_provider.dart` created
- All 4 screens migrated from `FutureBuilder` to `ref.watch(sleepDataProvider).when()`
- `DashboardScreen`, `InsightsScreen`, `ScheduleScreen` → `ConsumerWidget`
- `CoachScreen` → `ConsumerStatefulWidget` + `ConsumerState` (preserves chat messages)

### ✅ Step 6 — AppShell + NavigationBar
- `IndexedStack` — all pages stay alive, no reload on tab switch
- `_NavBar` extracted as a widget
- Outlined icons unselected, filled when selected
- `AppColors.divider` top border on nav bar
- Colours driven entirely by `NavigationBarTheme` in `AppTheme`

### ✅ Step 7 — Splash Screen Animation
- `AnimationController` (1400ms) with `SingleTickerProviderStateMixin`
- Logo: `ScaleTransition` 0.6→1.0 `easeOutBack` + `FadeTransition`
- Text: `SlideTransition` from `Offset(0, 0.3)` + `FadeTransition`, starts at 40% of animation
- Navigation: `PageRouteBuilder` with 400ms fade into `AppShell`

---

## What Remains — Build Order

### 🔴 URGENT — API Key Security
**Do this before any git commit.**

1. Add `flutter_dotenv: ^5.1.0` to pubspec
2. Create `sleepapp/.env`:
   ```
   OPENAI_API_KEY=sk-your-key-here
   ```
3. Add `.env` to `.gitignore`
4. Add to pubspec assets:
   ```yaml
   assets:
     - .env
   ```
5. In `main()`, before `runApp`:
   ```dart
   await dotenv.load(fileName: '.env');
   ```
6. In `ai_service.dart`, replace hardcoded key:
   ```dart
   final apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
   ```

---

### Step 8 — Profile, Settings, Onboarding Screens

**New files to create:**
- `lib/screens/onboarding_screen.dart` — first-launch multi-step flow
- `lib/screens/profile_screen.dart` — user info + goals summary
- `lib/screens/settings_screen.dart` — preferences, notifications, data

**Packages to add first:**
```bash
flutter pub add go_router shared_preferences intl shimmer
```

**Onboarding flow (3 steps):**
1. Name entry
2. Sleep goal (duration slider — default 8h)
3. Bedtime / wake time pickers

**SharedPreferences keys to use consistently:**
```dart
const kUserName       = 'user_name';        // String
const kSleepGoalMins  = 'sleep_goal_mins';  // int  (e.g. 480 = 8h)
const kBedtimeTarget  = 'bedtime_target';   // String "23:00"
const kWakeTime       = 'wake_time';        // String "07:00"
const kOnboardingDone = 'onboarding_done';  // bool
```

**go_router setup in main.dart:**
```dart
final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/home', builder: (_, __) => const AppShell()),
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
    GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
  ],
);
```

---

### Step 9 — Fix Schedule Screen with Real Editable Goals

Current state: goals are hardcoded. Need to:

1. Create `lib/core/providers/goals_provider.dart`:
   ```dart
   final goalsProvider = StateNotifierProvider<GoalsNotifier, UserGoals>(...);
   ```
2. Load goals from `SharedPreferences` on app start
3. Replace hardcoded values in `schedule_screen.dart` with `ref.watch(goalsProvider)`
4. Add time pickers for bedtime and wake time
5. Add sleep duration slider
6. Save on change via `ref.read(goalsProvider.notifier).updateBedtime(...)`

**UserGoals model:**
```dart
class UserGoals {
  final int sleepGoalMins;    // 480 default
  final String bedtime;       // "23:00"
  final String wakeTime;      // "07:00"
}
```

---

### Step 10 — RAG Backend Integration

**Backend stack:** Python · FastAPI · LangChain · ChromaDB · GPT-4o mini

**Backend file structure to create:**
```
backend/
├── main.py           # FastAPI app with /chat POST endpoint
├── rag_chain.py      # LangChain RAG: embed query → retrieve nights → generate response
├── ingest.py         # Parse 30 CSVs → embed → store in ChromaDB
├── requirements.txt  # fastapi uvicorn langchain chromadb openai python-dotenv
└── .env              # OPENAI_API_KEY=...
```

**FastAPI endpoint:**
```python
@app.post("/chat")
async def chat(body: ChatRequest):
    # body.message, body.history
    response = rag_chain.invoke({"question": body.message, "history": body.history})
    return {"reply": response}
```

**Flutter side — update `AIService`:**
- Replace direct OpenAI call with `http.post` to `http://localhost:8000/chat`
- Pass message + conversation history
- Parse `{"reply": "..."}` response

---

## Known Issues & Tech Debt

| Issue | File | Priority |
|---|---|---|
| API key hardcoded | `lib/core/services/ai_service.dart` | 🔴 Critical |
| `sleep_score_ring.dart` is dead code | `lib/widgets/sleep_score_ring.dart` | 🟡 Delete it |
| `_TopMetric` + `_MetricDivider` duplicated in dashboard + sleep_detail | Both | 🟡 Extract to widgets |
| Schedule screen goals are hardcoded | `schedule_screen.dart` | 🔴 Blocked on Step 9 |
| No shimmer loading skeletons | All screens | 🟡 Add after Step 8 |
| Using `Navigator.push` not `go_router` | All screens | 🟡 Fix in Step 8 |
| `insights_service.dart` not connected to any UI | — | 🟢 Low |
| `sleep_stage_timeline.dart` unused | `lib/widgets/` | 🟢 Review in Step 9 |

---

## Key Code Patterns Reference

### Using AppColors
```dart
color: AppColors.primary
color: AppColors.deepSleep
color: AppColors.forScore(night.sleepScore)   // dynamic based on score
color: AppColors.forStage('rem')              // stage-specific colour
```

### Using TextTheme (Inter font)
```dart
style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)
style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)
style: Theme.of(context).textTheme.labelSmall
```

### Using duration utils
```dart
import '../core/utils/duration_utils.dart';
final mins  = durationToMinutes('7h 30m');  // → 450
final label = minutesToDuration(450);        // → "7h 30m"
```

### Using ScoreRing
```dart
import '../widgets/score_ring.dart';
ScoreRing(score: night.sleepScore)                              // 84px with "Score" label
ScoreRing(score: score, size: 76, strokeWidth: 5, showLabel: false)  // compact
```

### Using MetricCard
```dart
import '../widgets/metric_card.dart';
MetricCard(
  icon: Icons.bedtime_rounded,
  iconColor: AppColors.deepSleep,   // optional
  title: 'Deep Sleep',
  value: night.deepSleep,
  subtitle: 'Goal: 1h 30m',
)
```

### Adding a new provider
```dart
// In lib/core/providers/your_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

final myProvider = Provider<SomeType>((ref) {
  // can watch other providers: ref.watch(sleepDataProvider)
  return SomeType();
});
```

---

## ML Model Reference
- **Algorithm:** Random Forest Regressor
- **R²:** 0.969
- **Input features:** Garmin sleep metrics (duration, stages, HRV, stress, etc.)
- **Target:** Sleep Score (0–100)
- **Saved as:** `.pkl` file
- **Training notebook:** `SleepDataTraining.ipynb` (Google Colab, in project root)

---

## Session Notes
- Mehdi is a final-year CS student in the UK — keep explanations practical, no fluff
- He runs the app on **Chrome** for development
- The `MehdiTouhamiFinal` folder was bought secondhand — the Mac hostname was "Michael-s-A53" (now fixed to MacBook-Pro via `sudo scutil --set HostName/ComputerName`)
- The `Sleep analysis app RAG` Desktop folder has flat copies of lib files — always edit the real project in `MehdiTouhamiFinal/sleepapp/`
- Always work directly in the real project folder — confirmed connected via Cowork
