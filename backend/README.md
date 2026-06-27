# Backend - QA Insight Hub

Django REST backend for `Q Dashboard` with module coverage for:

- Role-based authentication (Token auth)
- Master data (BU, Site, Reporting Period, Users)
- Monthly QA submission + cut-off validation + acknowledgment
- Review workflow (approve / reject / send back / reviewed)
- Dashboard KPIs, trend, comparative analysis
- Report templates, custom report, PDF + Excel-compatible export

## Quick start

1. `cd qa_insight_backend`
2. `python3 -m pip install -r ../requirements.txt`
3. `python3 manage.py migrate`
4. `python3 manage.py bootstrap_demo_data`
5. `python3 manage.py runserver`

API base: `http://127.0.0.1:8000/api`

## Demo users

- `assembly_user / assembly123`
- `qa_representative / qa123`
- `management_viewer / viewer123`
- `admin / admin123`
