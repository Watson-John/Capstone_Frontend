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

## Run locally

```bash
flutter pub get
flutter run
```
