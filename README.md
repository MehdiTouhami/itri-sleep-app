# Itri Sleep

A mobile sleep analysis app built as a final-year Computer Science project. It analyses 279 nights of personal Garmin wearable data using a RAG-powered AI coach, a trained Random Forest model, and a Flutter frontend.

Live backend: [itri-sleep-app.onrender.com/health](https://itri-sleep-app.onrender.com/health)

---

## Features

- **Sleep Coach** - context-aware AI chatbot powered by Gemini 3.6 Flash with a dual RAG pipeline: retrieves relevant personal sleep nights and sleep research papers before generating each response
- **279 nights of real data** - personal Garmin wearable exports (Jul 2025 - May 2026), bundled as structured CSV assets
- **Random Forest model** - trained on personal sleep data, used for feature importance analysis (top drivers: Body Battery, HRV, REM sleep)
- **Trends** - week-by-week sleep history with expandable weekly cards, clickable individual nights, and a 12-week score line chart
- **Insights** - 7-night averages, key factor progress bars, RF feature importance visualisation, sleep stage breakdown
- **Dashboard** - latest night summary with sleep score ring, stage breakdown, and key metrics
- **Onboarding and Goals** - personalised sleep targets stored locally via SharedPreferences

---

## Stack

**Mobile app** (`sleepapp/`)
- Flutter (Dart)
- Riverpod for state management
- fl_chart for data visualisation
- GoRouter, google_fonts, shared_preferences

**Backend** (`backend/`)
- Python FastAPI, deployed on Render
- LangChain + ChromaDB (dual vector store RAG pipeline)
- Google Gemini (gemini-3.6-flash + gemini-embedding-001)
- scikit-learn Random Forest Regressor

---

## Architecture

```
Flutter app (mobile)
       |
       | HTTPS
       v
FastAPI backend (Render)
       |
       |-- ChromaDB: personal nights    top 5 similar nights retrieved per query
       |-- ChromaDB: research papers    top 3 relevant papers retrieved per query
       |            |
       |            v (concatenated context)
       +-- Gemini 3.6 Flash generates response
```

RAG details:
- Chunking: document-level (one Garmin night = one document, one paper = one document)
- Embedding model: `gemini-embedding-001`
- Retrieval: cosine similarity via ChromaDB, top 5 personal nights + top 3 research chunks
- Around 1,500-1,800 tokens per request

---

## ML Model

Random Forest Regressor trained on personal Garmin sleep data.

| | |
|---|---|
| Dataset | 279 nights (Jul 2025 - May 2026) |
| Features | Body Battery, HRV, REM, Deep Sleep, Respiration, Stress, Resting HR, Day of Week |
| Top predictor | Body Battery Change |
| Cross-validated R2 | 0.96+ |

Used for feature importance analysis rather than live prediction. With a single-user dataset, interpretability is more valuable than generalisation.

Training script: `train_model.py`. Original training notebook: `SleepDataTraining.ipynb`.

---

## Running locally

The backend is deployed on Render's free tier (it spins down after 15 minutes of inactivity and takes ~30-50s to wake on the next request), so no local backend setup is needed to run the app.

```bash
git clone https://github.com/MehdiTouhami/itri-sleep-app.git
cd itri-sleep-app/sleepapp
flutter pub get
flutter run
```

To run the backend locally, set a `GOOGLE_API_KEY` in `backend/.env` (get one from [Google AI Studio](https://aistudio.google.com/apikey)):

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
        data/           SleepRepository (loads and caches all 279 nights)
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
