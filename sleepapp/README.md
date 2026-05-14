# Itri Sleep — AI Sleep Analysis App

A full-stack mobile sleep analysis application built as a final-year Computer Science honours project. Analyses personal Garmin wearable data using a RAG-powered AI coach, a trained Random Forest model, and a Flutter mobile frontend.

---

## Features

- **AI Sleep Coach** — context-aware chatbot powered by GPT-4o mini with a dual RAG pipeline: retrieves relevant personal sleep nights + sleep research papers before generating responses
- **279 nights of real data** — personal Garmin wearable exports (Jul 2025 – May 2026), bundled as structured CSV assets
- **Random Forest model** — trained on personal sleep data, used for feature importance analysis (top drivers: Body Battery, HRV, REM sleep)
- **Trends screen** — week-by-week sleep history with expandable weekly cards, clickable individual nights, and a 12-week score line chart
- **Insights screen** — 7-night averages, key factor progress bars, RF feature importance visualisation, sleep stage breakdown
- **Dashboard** — latest night summary with sleep score ring, stage breakdown, and key metrics
- **Onboarding, Profile & Goals** — personalised sleep targets stored locally via SharedPreferences

---

## Tech Stack

**Frontend**
- Flutter (Dart) — cross-platform mobile app
- Riverpod — state management
- fl_chart — data visualisation
- GoRouter — navigation
- google_fonts, shimmer, shared_preferences

**Backend** ([separate repo](https://github.com/MehdiTouhami/itri-sleep-backend))
- Python FastAPI — REST API
- LangChain + ChromaDB — dual vector store RAG pipeline
- OpenAI GPT-4o mini — sleep coach LLM
- scikit-learn — Random Forest Regressor
- Deployed on Railway

---

## Architecture

```
Flutter App (mobile)
      │
      │ HTTPS API calls
      ▼
FastAPI Backend (Railway)
      │
      ├── ChromaDB (personal nights)   ← top 5 similar nights retrieved per query
      ├── ChromaDB (research papers)   ← top 3 relevant papers retrieved per query
      │         ↓ concatenated context
      └── GPT-4o mini → response
```

**RAG details:**
- Chunking: document-level (one Garmin night = one document, one paper summary = one document)
- Embedding: `text-embedding-3-small`
- Retrieval: cosine similarity via ChromaDB — top 5 personal nights + top 3 research chunks
- ~1,500–1,800 tokens per request (~$0.0003/message)

---

## ML Model

Random Forest Regressor trained on personal Garmin sleep data.

| Metric | Value |
|--------|-------|
| Dataset | 279 nights (Jul 2025 – May 2026) |
| Features | Body Battery, HRV, REM, Deep Sleep, Respiration, Stress, Resting HR |
| Top driver | Body Battery Change (21.6%) |

> Model is used for feature importance analysis rather than prediction — a deliberate engineering decision given the single-user dataset.

---

## Project Structure

```
lib/
├── core/
│   ├── constants/       # AppConfig (base URL), SharedPreferences keys
│   ├── data/            # SleepRepository — loads + caches all 279 CSV nights
│   ├── models/          # SleepNight (13 fields)
│   ├── providers/       # Riverpod providers (sleep data, goals, feature importance)
│   ├── services/        # AIService, InsightsService
│   ├── theme/           # AppColors, AppTheme (Inter font, dark design system)
│   └── utils/           # durationToMinutes, minutesToDuration
├── screens/
│   ├── dashboard_screen.dart
│   ├── trends_screen.dart
│   ├── insights_screen.dart
│   ├── coach_screen.dart
│   ├── sleep_detail_screen.dart
│   ├── profile_screen.dart
│   ├── settings_screen.dart
│   ├── onboarding_screen.dart
│   └── splash_screen.dart
└── widgets/
    ├── score_ring.dart        # Reusable animated score ring
    ├── metric_card.dart       # Reusable metric display card
    ├── glass_card.dart        # Frosted glass card container
    └── sleep_stage_timeline.dart
assets/
└── data/
    └── Sleep-1.csv … Sleep-279.csv   # Garmin sleep exports (279 nights)
```

---

## Running Locally

The backend is deployed on Railway — no local backend setup needed.

```bash
git clone https://github.com/MehdiTouhami/itri-sleep-app.git
cd itri-sleep-app
flutter pub get
flutter run -d chrome
```

To point at a local backend instead of Railway, change `kBaseUrl` in `lib/core/constants/app_config.dart`.

---

## Backend

The FastAPI backend (RAG pipeline, RF model, ChromaDB) lives in a separate repository:
**[github.com/MehdiTouhami/itri-sleep-backend](https://github.com/MehdiTouhami/itri-sleep-backend)**
