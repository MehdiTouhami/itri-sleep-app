# Itri Sleep — Build Log v5
> **Read this at the start of every new session.** Full project state, completed work, conventions, and what to do next.

**Project:** CO3008 Honours Project — AI Sleep Analysis Mobile App (now portfolio/job project)
**Student:** Mehdi Touhami · `touhamimehdigpt2@gmail.com`
**Stack:** Flutter (Dart) · Python FastAPI · GPT-4o mini · LangChain · ChromaDB · Garmin CSV data · Random Forest (R²=0.969)
**Real project path:** `~/Desktop/MehdiTouhamiFinal/sleepapp/` ← Flutter app lives here
**Backend path:** `~/Desktop/MehdiTouhamiFinal/backend/` ← Python RAG backend lives here
**Backend GitHub:** `https://github.com/MehdiTouhami/itri-sleep-backend`
**Backend deployed:** `https://web-production-a9ef4.up.railway.app` (Railway — always live, no local backend needed)

---

## How to Run the Project

### Every session — backend is deployed, only Flutter needed locally:

```bash
cd ~/Desktop/MehdiTouhamiFinal/sleepapp
flutter run -d chrome
```

**Hot reload:** `r` · **Full restart:** `R` (required after model/provider/main.dart changes)

### Running backend locally (only for backend development):
```bash
lsof -ti:8000 | xargs kill -9
cd ~/Desktop/MehdiTouhamiFinal/backend
python3 -m uvicorn main:app --reload --port 8000
```
> ⚠️ If running locally, change `AppConfig.kBaseUrl` in `sleepapp/lib/core/constants/app_config.dart` to `http://localhost:8000`. Change back to Railway URL when done.

### Deploy backend changes:
```bash
cd ~/Desktop/MehdiTouhamiFinal/backend
git add .
git commit -m "describe change"
git push
# Railway auto-redeploys in ~2 minutes
```

### Health checks:
```bash
curl https://web-production-a9ef4.up.railway.app/health
curl https://web-production-a9ef4.up.railway.app/feature-importance
```

---

## Complete File Tree (current state)

```
MehdiTouhamiFinal/
├── ITRI_SLEEP_BUILD_LOG_V5.md           ← this file
├── SleepDataTraining.ipynb              ← RF model training notebook (R²=0.969, trained in Colab)
│
├── backend/
│   ├── main.py                          ✅ FastAPI — /chat, /health, /feature-importance, CORS
│   ├── rag_chain.py                     ✅ Dual RAG: personal data + research (langchain_core imports)
│   ├── ingest.py                        ✅ Parses Garmin CSVs → chroma_db/
│   ├── ingest_research.py               ✅ 18 research paper summaries → chroma_research/
│   ├── requirements.txt                 ✅ All deps incl. scikit-learn + joblib
│   ├── Procfile                         ✅ web: uvicorn main:app --host 0.0.0.0 --port $PORT
│   ├── .gitignore                       ✅ Excludes .env, keeps chroma_db/ and .pkl
│   ├── .env                             ✅ OPENAI_API_KEY (never commit — also set in Railway Variables)
│   ├── sleep_score_model.pkl            ✅ Trained RF model for feature importance
│   ├── chroma_db/                       ✅ Vector store — personal sleep nights (currently 30)
│   └── chroma_research/                 ✅ Vector store — 18 research papers
│
└── sleepapp/
    ├── lib/
    │   ├── main.dart                                ✅ ProviderScope → MaterialApp.router → GoRouter
    │   ├── core/
    │   │   ├── constants/
    │   │   │   ├── app_config.dart                  ✅ kBaseUrl = Railway URL
    │   │   │   └── prefs_keys.dart                  ✅ SharedPreferences keys
    │   │   ├── data/
    │   │   │   └── sleep_repository.dart            ✅ Loads all CSVs, static cache, newest-first
    │   │   ├── models/
    │   │   │   └── sleep_night.dart                 ✅ 13 fields incl. bodyBattery + respiration
    │   │   ├── providers/
    │   │   │   ├── sleep_provider.dart              ✅ sleepDataProvider, latestNightProvider, recentNightsProvider, featureImportanceProvider, FeatureImportanceItem
    │   │   │   └── goals_provider.dart              ✅ UserGoals + GoalsNotifier + goalsProvider
    │   │   ├── services/
    │   │   │   ├── ai_service.dart                  ✅ Calls AppConfig.kBaseUrl/chat
    │   │   │   └── insights_service.dart            ✅ Uses shared durationToMinutes
    │   │   ├── theme/
    │   │   │   ├── app_colors.dart                  ✅ All design tokens
    │   │   │   └── app_theme.dart                   ✅ Inter font, NavBar, ColorScheme
    │   │   └── utils/
    │   │       └── duration_utils.dart              ✅ durationToMinutes() + minutesToDuration()
    │   ├── screens/
    │   │   ├── app_shell.dart                       ✅ IndexedStack + _NavBar
    │   │   ├── splash_screen.dart                   ✅ Animation → SharedPreferences → routes
    │   │   ├── onboarding_screen.dart               ✅ 3-step onboarding
    │   │   ├── profile_screen.dart                  ✅ Avatar initials, goals, Edit Goals sheet
    │   │   ├── settings_screen.dart                 ✅ Edit Goals, About
    │   │   ├── dashboard_screen.dart                ✅ Latest night, profile avatar
    │   │   ├── insights_screen.dart                 ✅ Weekly trend, Key Factors, RF card, Stages, Recommendations
    │   │   ├── schedule_screen.dart                 ✅ Editable goals from goalsProvider
    │   │   ├── coach_screen.dart                    ✅ RAG chat → deployed backend
    │   │   └── sleep_detail_screen.dart             ✅ ScoreRing + MetricCard breakdown
    │   └── widgets/
    │       ├── glass_card.dart                      ✅
    │       ├── sleep_stage_timeline.dart            ✅
    │       ├── score_ring.dart                      ✅ Reusable (size, strokeWidth, showLabel)
    │       └── metric_card.dart                     ✅ Reusable
    ├── assets/data/
    │   └── Sleep-1.csv … Sleep-30.csv              ✅ All 30 declared in pubspec.yaml
    └── pubspec.yaml                                 ✅ All packages installed
```

---

## What's Been Completed

### Steps 1–10 — Full App + RAG Backend
- ✅ Design system, shared utils, shared widgets
- ✅ SleepRepository loads all CSVs, Riverpod state management
- ✅ All screens: Dashboard, Insights, Schedule, Coach, Sleep Detail, Profile, Settings, Onboarding, Splash
- ✅ RAG backend: dual ChromaDB (personal nights + research papers), GPT-4o mini, LangChain LCEL chain

### Step 11 — RF Feature Importance
- ✅ `GET /feature-importance` endpoint loads `sleep_score_model.pkl` at startup
- ✅ `featureImportanceProvider` in Flutter fetches and caches results
- ✅ "What Drives Your Score" GlassCard in Insights — top 5 RF features as scaled bars + ML Model badge
- ✅ Top driver: Body Battery (21.6%), 7-Day HRV (12.7%), REM Sleep (12.7%), HRV (12.0%), Deep Sleep (12.0%)
- ✅ Graceful fallback if backend unreachable

### Step 12 — Backend Deployed to Railway
- ✅ Procfile, .gitignore, langchain_core import fix
- ✅ Live at `https://web-production-a9ef4.up.railway.app`
- ✅ GitHub: `https://github.com/MehdiTouhami/itri-sleep-backend`
- ✅ `AppConfig.kBaseUrl` centralises backend URL across Flutter

---

## RAG Architecture

```
User question
      ↓
┌─────────────────────────────────────┐
│    FastAPI /chat — Railway server    │
│                                     │
│  ChromaDB (personal)  ChromaDB      │
│  top 5 nights    +    (research)    │
│                       top 3 papers  │
│         ↓ concatenated context ↓    │
│              GPT-4o mini            │
└─────────────────────────────────────┘
```

### RAG Technical Details (for interviews)

**Chunking strategy:** Document-level — each Garmin night is one document, each research paper is one manually written summary. No splitter used. Documents are 80–150 tokens each, well within the 8,191 token limit of `text-embedding-3-small`.

**Retrieval:** Naive dense retrieval — cosine similarity vector search via ChromaDB. No hybrid BM25, no reranking, no MMR. Top 5 personal nights + top 3 research chunks per query.

**Token cost per request:** ~1,500–1,800 tokens total. At GPT-4o mini pricing this is ~$0.0003 per message — negligible for portfolio/demo use.

**Known improvement:** Research paper summaries currently contain narrative framing (~130 tokens each). Trimming to conclusion + implication + citation (~50 tokens each) would reduce context by ~240 tokens per request and improve signal-to-noise. **This is planned for next session.**

**Interview answer on cost:** *"I chose GPT-4o mini deliberately — 10x cheaper than GPT-4. Documents are short by design so context stays bounded. For production scale I'd add similarity thresholding to skip low-relevance chunks and trim paper summaries to conclusions only."*

**Interview answer on chunking:** *"I used document-level chunking because each unit of data is naturally bounded — one night, one paper. For longer documents I'd use RecursiveCharacterTextSplitter with ~500 token chunks and 50 token overlap."*

**Interview answer on retrieval:** *"Naive dense retrieval — cosine similarity in ChromaDB. Improvements would be MMR to reduce redundant nights, a cross-encoder reranker on top of initial retrieval, and similarity thresholding to filter irrelevant results."*

---

## What's Next — Priority Order

### 🔴 Priority 1 — Garmin Full Dataset (IN PROGRESS)
Mehdi is currently exporting ~10 months (~300 nights) from Garmin Connect.

**Export steps:**
- Go to connect.garmin.com → Account (top right) → Data Management → Export Your Data
- Download the zip — look for the Sleep folder containing individual CSV files
- **Warning:** Garmin bulk export format may differ from the current key-value CSV format
- The current `ingest.py` parser reads key-value pairs (row[0] = key, row[1] = value) — check the new format first before running

**Once you have the files:**
1. Check one CSV file matches the existing format — open it and compare to `Sleep-1.csv`
2. If format matches: copy all CSVs to `backend/` (or a temp folder), run `python3 ingest.py`
3. If format differs: update the parser in `ingest.py` first
4. Push to GitHub → Railway auto-redeploys with new chroma_db
5. Also copy new CSVs to `sleepapp/assets/data/` and declare them in `pubspec.yaml`

### 🟡 Priority 2 — Tighten Research Paper Summaries
Rewrite 18 paper summaries in `ingest_research.py` to conclusion + implication + citation only (~50 tokens each, down from ~130). Re-run `ingest_research.py`, push to GitHub.

**Why:** Reduces context tokens by ~240 per request, improves signal-to-noise in prompts, makes RAG responses sharper.

### 🟡 Priority 3 — Retrain RF on Full Dataset
Once 300 nights are available, retrain in Colab with k-fold cross-validation. Save new `.pkl`, replace `backend/sleep_score_model.pkl`, push → Railway redeploys.

### 🟢 Priority 4 — Nice to Have
- Shimmer loading skeletons on all screens
- Trends screen (week-over-week chart)
- Real Garmin API integration (replaces CSV exports)

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
| `deepSleep` | `#A98BFF` | Purple |
| `remSleep` | `#5AA8FF` | Blue |
| `lightSleep` | `#35D0A5` | Teal-green |
| `awake` | `#FF8FA3` | Pink-red |
| `textPrimary` | `#FFFFFF` | Main text |
| `textSecondary` | `#B0BEC5` | Labels |
| `textMuted` | `#607080` | De-emphasised |
| `navBar` | `#0F1825` | Bottom nav |

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

**Garmin CSV column → model field:**
```
Sleep Score          → sleepScore
Date                 → date
Sleep Duration       → sleepDuration  (first occurrence wins)
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

---

## Key Code Patterns Reference

### AppConfig (base URL)
```dart
import '../constants/app_config.dart';
// AppConfig.kBaseUrl = 'https://web-production-a9ef4.up.railway.app'
// Change to 'http://localhost:8000' for local backend dev only
```

### AppColors
```dart
color: AppColors.primary
color: AppColors.forScore(night.sleepScore)
color: AppColors.forStage('rem')
```

### Duration utils
```dart
durationToMinutes('7h 30m')  // → 450
minutesToDuration(450)        // → "7h 30m"
```

### ScoreRing
```dart
ScoreRing(score: night.sleepScore)
ScoreRing(score: score, size: 76, strokeWidth: 5, showLabel: false)
```

### MetricCard
```dart
MetricCard(icon: Icons.bedtime_rounded, iconColor: AppColors.deepSleep, title: 'Deep Sleep', value: night.deepSleep, subtitle: 'Goal: 1h 30m')
```

### AIService
```dart
final reply = await ai.sendMessage(message, history: history);
// history: [[userMsg, aiMsg], ...]
```

---

## Known Issues & Tech Debt

| Issue | Priority |
|---|---|
| `sleep_score_ring.dart` dead code in `lib/widgets/` | 🟡 Delete it |
| Research paper summaries too verbose (~130 tokens, should be ~50) | 🟡 Rewrite + re-ingest |
| Only 30 nights in chroma_db | 🔴 Export in progress |
| Flutter `.env` has unused OpenAI key | 🟢 Clean up later |
| `sleep_stage_timeline.dart` unused | 🟢 Review later |

---

## ML Model Notes

**Current:** RF trained on 30 nights, R²=0.969 (overfitted — small dataset). Used for feature importance only, not prediction. Saved as `backend/sleep_score_model.pkl`.

**Interview answer:** *"I used it for feature importance rather than prediction because 30 samples don't justify prediction confidence. That's a considered engineering decision. When I have 300 nights I'll retrain with k-fold CV for an honest held-out R²."*

**When 300 nights available:** Retrain in Colab → download `.pkl` → replace in `backend/` → `git push` → Railway redeploys.

---

## Other Portfolio Projects (for context)

Mehdi has two other projects being prepared for GitHub alongside this one:

**FER — Facial Emotion Recognition (EfficientNet-B0)**
- Trained on FER-2013 (35,887 images) → 72.4% accuracy
- Fine-tuned on JAFFE (213 images) → 89.1% accuracy
- Two-phase training: warm-up head → full fine-tune with cosine annealing
- Ablation study (augmentation +4.6%), Grad-CAM visualisations
- Code lost — needs to be redone cleanly and pushed to GitHub

**Distributed Systems — Microservices on Azure**
- Docker, Kong API Gateway, RabbitMQ, MySQL, Terraform, Azure VMs
- Options 1-3 complete (submitted at 68% / High 2:1)
- Plan: add Option 4 (moderate microservice + ECST pub/sub pattern) then deploy and push to GitHub

---

## Session Notes
- Mehdi is a final-year CS student in the UK, job hunting — keep everything portfolio-quality
- Runs Flutter on **Chrome** for development
- `python3` and `pip3` (not `python`/`pip`) on this Mac
- Use `python3 -m uvicorn` (not just `uvicorn`) to avoid PATH issues
- Backend is deployed — no need to run locally unless doing backend development
- Never commit `.env` files — OPENAI_API_KEY is set in Railway Variables
- Do NOT mix girlfriend's Garmin data — personalisation depends on single-user data
