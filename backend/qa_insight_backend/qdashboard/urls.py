from django.urls import include, path
from rest_framework.routers import DefaultRouter

from qdashboard.views import (
    BusinessUnitViewSet,
    CustomReportView,
    DashboardOverviewView,
    DashboardTrendView,
    ExportExcelReportView,
    ExportPdfReportView,
    HealthView,
    LoginView,
    LogoutView,
    MeView,
    MonthlySubmissionViewSet,
    PendingReviewList,
    ReportTemplateListView,
    ReportingPeriodViewSet,
    ReviewActionView,
    SiteViewSet,
    UserMasterViewSet,
    UserProfileListView,
)

router = DefaultRouter()
router.register("master/business-units", BusinessUnitViewSet, basename="business-unit")
router.register("master/sites", SiteViewSet, basename="site")
router.register("master/reporting-periods", ReportingPeriodViewSet, basename="reporting-period")
router.register("master/users", UserMasterViewSet, basename="user-master")
router.register("submissions", MonthlySubmissionViewSet, basename="submission")

urlpatterns = [
    path("health/", HealthView.as_view(), name="health"),
    path("auth/login/", LoginView.as_view(), name="login"),
    path("auth/logout/", LogoutView.as_view(), name="logout"),
    path("auth/me/", MeView.as_view(), name="me"),
    path("master/user-profiles/", UserProfileListView.as_view(), name="user-profiles"),
    path("reviews/pending/", PendingReviewList.as_view(), name="pending-reviews"),
    path("reviews/<int:submission_id>/action/", ReviewActionView.as_view(), name="review-action"),
    path("dashboard/overview/", DashboardOverviewView.as_view(), name="dashboard-overview"),
    path("dashboard/trends/", DashboardTrendView.as_view(), name="dashboard-trends"),
    path("reports/templates/", ReportTemplateListView.as_view(), name="report-templates"),
    path("reports/custom/", CustomReportView.as_view(), name="custom-report"),
    path("reports/export/excel/", ExportExcelReportView.as_view(), name="excel-report"),
    path("reports/export/pdf/", ExportPdfReportView.as_view(), name="pdf-report"),
    path("", include(router.urls)),
]
