# LifeLog Flutter App

This is the Flutter client for LifeLog.

## Why there is a `presentation/` folder

The codebase uses a feature-first structure with explicit layers.

- `presentation/` = UI layer only (pages, widgets, view interactions).
- `domain/` = business rules and use-cases (added as logic grows).
- `data/` = API models, repositories, and data sources (added as backend integration grows).

Using `presentation/` now keeps UI code clean and makes it easier to add `domain` and `data` later without moving everything again.

## Current pattern

Example from Expense Tracker:

- Page layout/composition: `lib/features/expense_tracker/presentation/expense_tracker_page.dart`
- Reusable UI widget(s): `lib/features/expense_tracker/presentation/widgets/scan_button.dart`

The page file stays focused on layout, while UI behavior is extracted into smaller widgets.

## Suggested feature structure

```text
lib/features/<feature_name>/
	presentation/
		<feature>_page.dart
		widgets/
	domain/
	data/
```

## Firebase setup (required for notifications)

This app uses Firebase Cloud Messaging for push notifications.
The Android build requires a `google-services.json` config file.

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Select the **lifelog-capstone** project
3. Navigate to **Project Settings > General**
4. Under **Your apps**, find the Android app (`com.example.lifelog`)
5. Download `google-services.json`
6. Place it at `android/app/google-services.json`

> **Note:** This file is listed in `.gitignore` and must never be committed.

## Environment variables

Copy the example and fill in values:

```bash
cp .env.example .env
```

Required variables:
- `BACKEND_URL` — URL of the Django backend (default: `http://10.0.2.2:8001` for Android emulator)
- `PROTOTYPE_APP_KEY` — Authentication key for expense scanning API

## Run locally

```bash
flutter pub get
flutter run
```
