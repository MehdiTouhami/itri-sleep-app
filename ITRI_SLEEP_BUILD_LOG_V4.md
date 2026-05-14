# Itri Sleep — Build Log v4
> **Read this at the start of every new session.** Full project state, completed work, conventions, and what to do next.

**Project:** CO3008 Honours Project — AI Sleep Analysis Mobile App (now portfolio/job project)
**Student:** Mehdi Touhami · `touhamimehdigpt2@gmail.com`
**Stack:** Flutter (Dart) · Python FastAPI · GPT-4o mini · LangChain · ChromaDB · Garmin CSV data · Random Forest (R²=0.969)
**Real project path:** `~/Desktop/MehdiTouhamiFinal/sleepapp/` ← Flutter app lives here
**Backend path:** `~/Desktop/MehdiTouhamiFinal/backend/` ← Python RAG backend lives here
**Reference folder:** `~/Desktop/Sleep analysis app RAG/` ← flat file copies only, not the real project
**Backend GitHub:** `https://github.com/MehdiTouhami/itri-sleep-backend`
**Backend deployed:** `https://web-production-a9ef4.up.railway.app` (Railway — always live, no local backend needed)

---

## How to Run the Project

### Every session — backend is deployed, only Flutter needed locally:

**Terminal (Flutter):**
```bash
cd ~/Desktop/MehdiTouhamiFinal/sleepapp
flutter run -d chrome
```

**Hot reload:** `r` · **Full restart:** `R` (required after model/provider/main.dart changes)

### Running backend locally (only needed for backend development):
```bash
# Kill anything on port 8000 first
lsof -ti:8000 | xargs kill -9

cd ~/Desktop/MehdiTouhamiFinal/backend
python3 -m uvicorn main:app --reload --port 8000
```
> ⚠️ If running locally, change `AppConfig.kBaseUrl` in `sleepapp/lib/core/constants/app_config.dart` back to `http://localhost:8000`. Change it back to the Railway URL when done.

### One-time setup commands (already done — do NOT re-run unless rebuilding):
```bash
cd ~/Desktop/MehdiTouhamiFinal/backend
pip3 install -r requirements.txt
python3 ingest.py           # embeds Garmin nights → ./chroma_db/
python3 ingest_research.py  # embeds 18 research papers → ./chroma_research/
```

### Health check (deployed):
```bash
curl https://web-production-a9ef4.up.railway.app/health           # → {"status":"ok"}
curl https://web-production-a9ef4.up.railway.app/feature-importance  # → RF importances
```

### Test RAG (deployed):
```bash
curl -X POST https://web-production-a9ef4.up.railway.app/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Why is my HRV low and what does research say about it?", "history": []}'
```

### Deploy backend changes:
```bash
cd ~/Desktop/MehdiTouhamiFinal/backend
git add .
git commit -m "describe your change"
git push
# Railway auto-redeploys on push — takes ~2 minutes
```

---

## Complete File Tree (current state)

```
MehdiTouhamiFinal/
├── ITRI_SLEEP_BUILD_LOG_V4.md           ← this file
├── SleepDataTraining.ipynb              ← RF model training notebook (R²=0.969, trained in Colab)
│
├── backend/                             ✅ RAG backend — deployed on Railway
│   ├── main.py                          ✅ FastAPI — /chat POST, /health GET, /feature-importance GET, CORS
│   ├── rag_chain.py                     ✅ Dual RAG: personal data + research papers (langchain_core imports)
│   ├── ingest.py                        ✅ Parses Garmin CSVs → chroma_db/
│   ├── ingest_research.py               ✅ 18 peer-reviewed papers → chroma_research/
│   ├── requirements.txt                 ✅ All Python deps incl. scikit-learn + joblib
│   ├── Procfile                         ✅ web: uvicorn main:app --host 0.0.0.0 --port $PORT
│   ├── .gitignore                       ✅ Excludes .env, keeps chroma_db/ and .pkl
│   ├── .env                             ✅ OPENAI_API_KEY (never commit — also set in Railway Variables)
│   ├── sleep_score_model.pkl            ✅ Trained RF model — loaded at startup for feature importance
│   ├── chroma_db/                       ✅ Vector store — 30 personal sleep nights
│   └── chroma_research/                 ✅ Vector store — 18 research papers
│
└── sleepapp/
    ├── lib/
    │   ├── main.dart                                ✅ ProviderScope → MaterialApp.router → GoRouter
    │   ├── core/
    │   │   ├── constants/
    │   │   │   ├── app_config.dart                  ✅ kBaseUrl = Railway URL (change for local dev)
    │   │   │   └── prefs_keys.dart                  ✅ kUserName, kSleepGoalMins, kBedtimeTarget, kWakeTime, kOnboardingDone
    │   │   ├── data/
    │   │   │   └── sleep_repository.dart            ✅ Loads all 30 CSVs, static cache, newest-first sort
    │   │   ├── models/
    │   │   │   └── sleep_night.dart                 ✅ 13 fields incl. bodyBattery + respiration
    │   │   ├── providers/
    │   │   │   ├── sleep_provider.dart              ✅ sleepDataProvider, latestNightProvider, recentNightsProvider, featureImportanceProvider, FeatureImportanceItem
    │   │   │   └── goals_provider.dart              ✅ UserGoals model + GoalsNotifier + goalsProvider
    │   │   ├── services/
    │   │   │   ├── ai_service.dart                  ✅ Calls AppConfig.kBaseUrl/chat with message + history
    │   │   │   └── insights_service.dart            ✅ Uses shared durationToMinutes
    │   │   ├── theme/
    │   │   │   ├── app_colors.dart                  ✅ All design tokens as static const
    │   │   │   └── app_theme.dart                   ✅ Full ThemeData: Inter, NavBar, ColorScheme
    │   │   └── utils/
    │   │       └── duration_utils.dart              ✅ durationToMinutes() + minutesToDuration()
    │   ├── screens/
    │   │   ├── app_shell.dart                       ✅ IndexedStack + _NavBar (outlined/filled icons)
    │   │   ├── splash_screen.dart                   ✅ Animation → checks SharedPreferences → routes
    │   │   ├── onboarding_screen.dart               ✅ 3-step: name → sleep goal slider → bedtime/wake
    │   │   ├── profile_screen.dart                  ✅ Avatar initials, goals summary, Edit Goals sheet
    │   │   ├── settings_screen.dart                 ✅ Edit Goals, About section
    │   │   ├── dashboard_screen.dart                ✅ Profile avatar icon → context.push('/profile')
    │   │   ├── insights_screen.dart                 ✅ Weekly trend, Key Factors, RF "What Drives Your Score" card, Sleep Stages, Recommendations
    │   │   ├── schedule_screen.dart                 ✅ Real goals from goalsProvider, editable
    │   │   ├── coach_screen.dart                    ✅ RAG-powered — sends message + history to deployed backend
    │   │   └── sleep_detail_screen.dart             ✅ Uses ScoreRing + MetricCard
    │   └── widgets/
    │       ├── glass_card.dart                      ✅
    │       ├── sleep_stage_timeline.dart            ✅
    │       ├── score_ring.dart                      ✅ Reusable ScoreRing (size, strokeWidth, showLabel)
    │       └── metric_card.dart                     ✅ Reusable MetricCard
    ├── assets/data/
    │   └── Sleep-1.csv … Sleep-30.csv              ✅ All 30 declared in pubspec.yaml
    ├── .env                                         ✅ OPENAI_API_KEY (Flutter side — now unused, kBaseUrl handles routing)
    ├── .gitignore                                   ✅ .env is ignored
    └── pubspec.yaml                                 ✅ All packages installed
```

---

## What's Been Completed

### Steps 1–9 (all done)
- ✅ Design system: `app_colors.dart`, `app_theme.dart`, Inter font
- ✅ Shared utils: `duration_utils.dart`
- ✅ Shared widgets: `score_ring.dart`, `metric_card.dart`
- ✅ `SleepRepository` loads all 30 CSVs
- ✅ `flutter_riverpod` + `SleepNotifier` state management
- ✅ `NavigationBarTheme` + `AppShell` styling
- ✅ Splash screen with animation
- ✅ Profile, Settings, Onboarding screens
- ✅ Schedule screen with real editable goals
- ✅ API key moved to `.env` via `flutter_dotenv`

### Step 10 — RAG Backend
- ✅ `backend/ingest.py` — parses all 30 Garmin key-value CSVs, embeds into ChromaDB
- ✅ `backend/ingest_research.py` — embeds 18 verified peer-reviewed sleep science papers
- ✅ `backend/rag_chain.py` — dual retrieval LCEL chain (personal data + research)
- ✅ `backend/main.py` — FastAPI `/chat` + `/health` with CORS for Chrome
- ✅ `ai_service.dart` — calls backend `/chat`, no OpenAI key in Flutter
- ✅ `coach_screen.dart` — sends raw message + conversation history, backend handles context

### Step 11 — RF Feature Importance in Insights Screen
- ✅ `sleep_score_model.pkl` — downloaded from Google Drive, placed in `backend/`
- ✅ `backend/requirements.txt` — added `scikit-learn` and `joblib`
- ✅ `backend/main.py` — loads `.pkl` at startup, `GET /feature-importance` returns 14 features sorted by importance
- ✅ `sleep_provider.dart` — added `FeatureImportanceItem` model + `featureImportanceProvider` FutureProvider
- ✅ `insights_screen.dart` — "What Drives Your Score" GlassCard with top 5 RF features as scaled bars + ML Model badge. Graceful fallback message if backend is unreachable.
- ✅ Top driver: Body Battery (21.6%), 7-Day HRV (12.7%), REM Sleep (12.7%), HRV (12.0%), Deep Sleep (12.0%)

### Step 12 — Backend Deployed to Railway
- ✅ `backend/Procfile` — `web: uvicorn main:app --host 0.0.0.0 --port $PORT`
- ✅ `backend/.gitignore` — excludes `.env`, keeps `chroma_db/`, `chroma_research/`, `.pkl`
- ✅ `rag_chain.py` — fixed import: `langchain.prompts` → `langchain_core.prompts` (newer LangChain compatibility)
- ✅ Backend pushed to GitHub: `https://github.com/MehdiTouhami/itri-sleep-backend`
- ✅ Deployed on Railway: `https://web-production-a9ef4.up.railway.app`
- ✅ `OPENAI_API_KEY` set as Railway environment variable
- ✅ `app_config.dart` — centralised `kBaseUrl`, both `ai_service.dart` and `sleep_provider.dart` use it
- ✅ Flutter `kBaseUrl` updated to Railway URL — Sleep Coach and feature importance work 24/7 without local backend

---

## RAG Architecture

```
User question
      ↓
┌─────────────────────────────────────┐
│    FastAPI /chat — Railway server    │
│                                     │
│  ┌──────────────┐  ┌─────────────┐  │
│  │ ChromaDB     │  │ ChromaDB    │  │
│  │ chroma_db/   │  │chroma_      │  │
│  │ (30 Garmin   │  │research/    │  │
│  │  nights)     │  │(18 papers)  │  │
│  │ top 5 nights │  │top 3 papers │  │
│  └──────┬───────┘  └──────┬──────┘  │
│         └────────┬─────────┘         │
│                  ↓                   │
│         Prompt with both contexts    │
│                  ↓                   │
│            GPT-4o mini               │
└─────────────────────────────────────┘
      ↓
Response citing real dates + research papers
```

---

## 18 Verified Research Papers in ChromaDB

| Topic | Citation |
|---|---|
| REM Sleep & Memory | Plihal & Born (1999), Psychophysiology |
| Memory Function of Sleep | Diekelmann & Born (2010), Nature Reviews Neuroscience |
| Deep Sleep & Growth Hormone | Van Cauter et al. (2000), JAMA |
| HRV Standards | ESC Task Force (1996), European Heart Journal |
| HRV During Sleep | Otzenberger et al. (1998), American Journal of Physiology |
| RHR & Sleep Stages | Trinder et al. (2001), Journal of Sleep Research |
| Chronic Sleep Restriction | Van Dongen et al. (2003), Sleep |
| Sleep Debt & Recovery | Belenky et al. (2003), Journal of Sleep Research |
| Caffeine & Deep Sleep | Landolt et al. (1995), Neuropsychopharmacology |
| Caffeine Timing | Drake et al. (2013), Journal of Clinical Sleep Medicine |
| Exercise & Sleep | Youngstedt et al. (1997), Sleep |
| Stress & Sleep Architecture | Van Reeth et al. (2000), Sleep Medicine Reviews |
| Insomnia & HPA Axis | Vgontzas et al. (2001), JCEM |
| Blue Light & Melatonin | Chang et al. (2015), PNAS |
| Sleep Regularity | Phillips et al. (2017), Scientific Reports |
| Alcohol & Sleep | Ebrahim et al. (2013), Alcoholism: Clinical & Experimental Research |
| Sleep & Immune Function | Cohen et al. (2009), Archives of Internal Medicine |
| Sleep & Adaptive Immunity | Besedovsky et al. (2012), Pflügers Archiv |

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
  flutter_dotenv: ^5.1.0
  go_router: ^14.0.0
  shared_preferences: ^2.3.0
  intl: ^0.19.0
  shimmer: ^3.0.0
```

---

## backend/requirements.txt

```
fastapi
uvicorn[standard]
langchain
langchain-openai
langchain-chroma
chromadb
openai
python-dotenv
scikit-learn
joblib
```

---

## GoRouter Setup (main.dart)

```dart
final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/',           builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
    GoRoute(path: '/home',       builder: (_, __) => const AppShell()),
    GoRoute(path: '/profile',    builder: (_, __) => const ProfileScreen()),
    GoRoute(path: '/settings',   builder: (_, __) => const SettingsScreen()),
  ],
);
```

---

## Design Tokens (AppColors)

| Token | Hex | Usage |
|---|---|---|
| `background` | `#0B1220` | Scaffold background |
| `surface` | `#121A2B` | Cards, panels |
| `surfaceAlt` | `#1A2540` | Elevated cards |
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
  final String hrv;            // "56"
  final String stressAvg;      // "20.68"
  final String bodyBattery;    // "34"
  final String respiration;    // "16.9"
}
```

**Garmin CSV column → model field mapping:**
```
Sleep Score          → sleepScore
Date                 → date
Sleep Duration       → sleepDuration  (first occurrence wins — appears twice)
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
// sleep_provider.dart
sleepDataProvider               // FutureProvider<List<SleepNight>>
latestNightProvider             // Provider<SleepNight?>
recentNightsProvider(n)         // Provider.family<List<SleepNight>, int>
featureImportanceProvider       // FutureProvider<List<FeatureImportanceItem>>

// goals_provider.dart
goalsProvider                   // StateNotifierProvider<GoalsNotifier, UserGoals>
```

**Standard screen pattern:**
```dart
class MyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider);
    return ref.watch(sleepDataProvider).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:   (e, _) => Center(child: Text('Error: $e')),
      data:    (nights) { /* build UI */ },
    );
  }
}
```

---

## Key Code Patterns Reference

### AppColors
```dart
color: AppColors.primary
color: AppColors.forScore(night.sleepScore)   // green/blue/amber/red
color: AppColors.forStage('rem')              // stage colour
```

### AppConfig (base URL)
```dart
import '../constants/app_config.dart';
// kBaseUrl = 'https://web-production-a9ef4.up.railway.app'
// Change to 'http://localhost:8000' for local backend dev
```

### Duration utils
```dart
import '../core/utils/duration_utils.dart';
durationToMinutes('7h 30m')  // → 450
minutesToDuration(450)        // → "7h 30m"
```

### ScoreRing
```dart
import '../widgets/score_ring.dart';
ScoreRing(score: night.sleepScore)
ScoreRing(score: score, size: 76, strokeWidth: 5, showLabel: false)
```

### MetricCard
```dart
import '../widgets/metric_card.dart';
MetricCard(icon: Icons.bedtime_rounded, iconColor: AppColors.deepSleep, title: 'Deep Sleep', value: night.deepSleep, subtitle: 'Goal: 1h 30m')
```

### goalsProvider
```dart
final goals = ref.watch(goalsProvider);
ref.read(goalsProvider.notifier).update(sleepGoalMins: 480, bedtime: '23:00', wakeTime: '07:00');
```

### AIService (RAG backend)
```dart
// Calls AppConfig.kBaseUrl/chat — deployed on Railway
final reply = await ai.sendMessage(message, history: history);
// history format: [[userMsg, aiMsg], [userMsg, aiMsg], ...]
```

---

## What's Next — Priority Order for Job Portfolio

### ✅ Priority 1 — RF Model Feature Importance in Insights Screen (DONE)
- "What Drives Your Score" card live in Insights screen
- Top 5 features shown as scaled bars with % contribution
- Backend `/feature-importance` endpoint deployed on Railway

### Priority 2 — More Garmin Data
- Mehdi has ~10 months of Garmin data (~300 nights)
- Garmin export: connect.garmin.com → Account → Data Management → Export Your Data
- The bulk export format likely differs from current key-value CSVs — update ingest.py parser
- Re-run ingest.py with all nights, rebuild chroma_db, push to GitHub, Railway auto-redeploys
- Do NOT mix girlfriend's data — personalisation depends on single-user data

### ✅ Priority 3 — Deploy the Backend (DONE)
- Backend live at `https://web-production-a9ef4.up.railway.app`
- GitHub: `https://github.com/MehdiTouhami/itri-sleep-backend`
- Railway auto-redeploys on every `git push`
- Flutter `AppConfig.kBaseUrl` points to Railway URL

### Priority 4 — Retrain RF on Full Dataset
- Once 300 nights are exported and cleaned, retrain the Random Forest in Colab
- Add proper k-fold cross-validation so R² is credible on held-out data
- With 300 nights, feature importance becomes much more reliable
- Save new .pkl, replace in backend/, push → Railway redeploys automatically

### Priority 5 (Nice to Have)
- Shimmer loading skeletons on all screens
- Weekly sleep PDF report export
- Trends screen (week-over-week chart)
- Real Garmin API integration (replaces CSV exports)

---

## Known Issues & Tech Debt

| Issue | File | Priority |
|---|---|---|
| `sleep_score_ring.dart` dead code | `lib/widgets/` | 🟡 Delete: `rm sleepapp/lib/widgets/sleep_score_ring.dart` |
| `insights_service.dart` not connected to UI | — | 🟢 Low priority now RF card is live |
| `sleep_stage_timeline.dart` unused | `lib/widgets/` | 🟢 Review later |
| No shimmer loading skeletons | All screens | 🟢 Nice to have |
| Flutter `.env` has OpenAI key (now unused) | `sleepapp/.env` | 🟢 Can clean up |
| Only 30 nights in ChromaDB | `backend/` | 🟡 Export full dataset, re-run ingest.py, push |

---

## ML Model Notes

**Current state:** Random Forest Regressor trained on 30 nights, R²=0.969 (overfitted on small dataset). Saved as `backend/sleep_score_model.pkl`. Loaded at startup by FastAPI.

**Do:** Use for feature importance — shows which metrics most influence sleep score. Valid regardless of sample size.

**Don't:** Use for sleep score prediction — unreliable with 30 samples.

**Interview answer:** *"I chose Random Forest because it outperforms neural networks on small tabular datasets and is interpretable. I used it for feature importance analysis rather than prediction because the dataset size didn't justify prediction confidence — that's a considered engineering decision, not a limitation."*

**When 300 nights are available:** Retrain in Colab with k-fold CV → download new .pkl → replace in backend/ → `git push` → Railway auto-redeploys.

---

## Session Notes
- Mehdi is a final-year CS student in the UK, now job hunting — keep everything portfolio-quality
- Runs app on **Chrome** for development
- Has ~10 months of Garmin data (~300 nights) — export pending
- Do NOT mix girlfriend's Garmin data — breaks personalisation
- Always work in `~/Desktop/MehdiTouhamiFinal/sleepapp/` for Flutter
- Always work in `~/Desktop/MehdiTouhamiFinal/backend/` for Python
- The `Sleep analysis app RAG` Desktop folder has flat copies only — not the real project
- The `backend/.env` file contains the real OpenAI API key — never commit it (also set in Railway Variables)
- Backend is deployed — no need to run locally unless doing backend development
- `python3` and `pip3` (not `python`/`pip`) on this Mac
- Use `python3 -m uvicorn` (not just `uvicorn`) to avoid PATH issues
