# Frontend - QA Insight Hub

Flutter app for Android and iOS for the `Q Dashboard` assignment.

## Implemented screens

- Animated role-based login
- Dashboard with KPI cards, trend chart, and comparative insights
- Submission module with mandatory field validation and acknowledgment flow
- Review/approval queue for QA Representative/Admin
- Master data explorer
- Reports screen with template list, export, and custom report trigger

## Run

1. `flutter pub get`
2. `flutter run`

Backend expected at: `http://10.0.2.2:8000/api` (Android emulator).

If testing on iOS simulator, update API base URL in:

`lib/core/services/api_service.dart`
