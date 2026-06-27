# QA Insight Hub

`QA Insight Hub` (`Model Name: Q Dashboard`) is an end-to-end Flutter + Django solution for QA data submission, approval workflows, KPI tracking, and reporting.

## Implemented modules

- User management with role-based login:
  - Assembly User
  - QA Representative
  - Management Viewer
  - Admin
- Master data:
  - Site master
  - BU master
  - User master
  - Reporting period master
- Submission module:
  - Monthly QA data entry
  - Mandatory field validation
  - Cut-off date validation
  - Submission acknowledgment ID generation
- Review & approval:
  - Pending submissions list
  - Review remarks
  - Approve / reject / send back / reviewed actions
  - Approval status tracking
- Dashboard:
  - Auto-calculated KPIs
  - Trend chart
  - Comparative analysis by BU
  - Status breakdown
- Reports:
  - PDF export
  - Excel-compatible CSV export
  - Standard templates endpoint
  - Custom report generation endpoint

## Tech stack

- Frontend: Flutter (Android + iOS)
- Backend: Python, Django, Django REST Framework
- Database: SQLite (dev-ready, can be switched to PostgreSQL)
- Auth: DRF token authentication

## Run backend

1. `cd backend/qa_insight_backend`
2. `python3 -m pip install -r ../requirements.txt`
3. `python3 manage.py migrate`
4. `python3 manage.py bootstrap_demo_data`
5. `python3 manage.py runserver`

Backend base URL: `http://127.0.0.1:8000/api`

## Run frontend

1. `cd frontend`
2. `flutter pub get`
3. `flutter run`

Default API base URL in app: `http://10.0.2.2:8000/api` (Android emulator).

## Demo credentials

- `assembly_user / assembly123`
- `qa_representative / qa123`
- `management_viewer / viewer123`
- `admin / admin123`

## Completion target

Assignment target timeline: **June 29, 2026**.
