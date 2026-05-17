# Itri Sleep

A mobile sleep analysis app built as a final-year Computer Science project. It analyses 279 nights of personal Garmin wearable data using a RAG-powered AI coach, a trained Random Forest model, and a Flutter frontend.

Live backend: [itri-sleep-app-production.up.railway.app/health](https://itri-sleep-app-production.up.railway.app/health)

---

## Features

- **Sleep Coach** - AI chatbot that retrieves relevant personal sleep nights and peer-reviewed research before answering, using a dual RAG pipeline (ChromaDB + GPT-4o mini)
- **Dashboard** - latest night summary with sleep score, stage breakdown, and key metrics
- **Trends** - week-by-week sleep history with expandable cards, individual night detail, and a 12-week score chart
- **Insights** - 7-night averages, Random Forest feature importance visualisation, sleep stage breakdown
- **Onboarding and Goals** - personalised sleep targets saved locally via SharedPreferences

---

## Stack

**Mobile app** (`sleepapp/`)

- Flutter (Dart), Riverpod, fl_chart, GoRouter, google_fonts, shared_preferences

**Backend** (`backend/`)

- Python FastAPI, deployed on Railway
- LangChain + ChromaDB (dual vector store RAG)
- OpenAI GPT-4o mini
- scikit-learn Random Forest Regressor

---

## Architecture

```
Flutter app
     |
     | HTTPS
     v
FastAPI (Railway)
     |
     |-- ChromaDB: personal nights    top 5 per query
     |-- ChromaDB: research papers    top 3 per query
     |
     v
GPT-4o mini generates response with both sources as context
```

Embedding model: `text-embedding-3-small`. Around 1,500-1,800 tokens per request.

---

## ML Model

Random Forest Regressor trained on personal Garmin sleep data.

| | |
|---|---|
| Dataset | 279 nights (Jul 2025 - May 2026) |
| Features | Body Battery, HRV, REM, Deep Sleep, Respiration, Stress, Resting HR, Day of Week |
| Top predictor | Body Battery Change |

Used for feature importance analysis rather than live prediction. With a single-user dataset, interpretability is more useful than generalisation.

---

## Running locally

The backend is deployed and always live, so no local setup is needed to run the app.

```bash
git clone https://github.com/MehdiTouhami/itri-sleep-app.git
cd itri-sleep-app/sleepapp
flutter pub get
flutter run
```

To run the backend locally:

```bash
cd itri-sleep-app/backend
pip install -r requirements.txt
python ingest.py
python ingest_research.py
uvicorn main:app --reload --port 8000
```

Set `kBaseUrl` in `sleepapp/lib/core/constants/app_config.dart` to `http://localhost:8000`.

---

## Project structure

```
sleepapp/lib/
    core/
        constants/      AppConfig, SharedPreferences keys
        data/           SleepRepository (loads all 279 nights, caches with SharedPreferences)
        models/         SleepNight (13 fields)
        providers/      Riverpod providers
        services/       AIService, InsightsService
        theme/          AppColors, AppTheme (Inter font, dark design system)
        utils/          Duration helpers
    screens/
        dashboard_screen.dart
        trends_screen.dart
        insights_screen.dart
        coach_screen.dart
        sleep_detail_screen.dart
        profile_screen.dart
        settings_screen.dart
        onboarding_screen.dart
        splash_screen.dart
    widgets/
        score_ring.dart
        metric_card.dart
        glass_card.dart

backend/
    main.py               FastAPI: /chat, /health, /feature-importance
    rag_chain.py          Dual RAG pipeline (LangChain LCEL)
    ingest.py             Garmin CSV -> ChromaDB
    ingest_research.py    Research papers -> ChromaDB
    sleep_score_model.pkl
```
