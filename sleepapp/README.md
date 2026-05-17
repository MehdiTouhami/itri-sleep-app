# Itri Sleep

A mobile sleep analysis app built as a final-year Computer Science project. It analyses 279 nights of personal Garmin wearable data using a RAG-powered AI coach, a trained Random Forest model, and a Flutter frontend.

See the [root README](../README.md) for the full project overview, architecture, and setup instructions.

---

## Running the app

The backend is deployed and always live, so no local setup is needed.

```bash
flutter pub get
flutter run
```

To point at a local backend instead of Railway, change `kBaseUrl` in `lib/core/constants/app_config.dart`.

---

## Project structure

```
lib/
    core/
        constants/      AppConfig, SharedPreferences keys
        data/           SleepRepository (loads all 279 nights)
        models/         SleepNight (13 fields)
        providers/      Riverpod providers
        services/       AIService, InsightsService
        theme/          AppColors, AppTheme
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
assets/
    data/
        Sleep-1.csv ... Sleep-279.csv
```
