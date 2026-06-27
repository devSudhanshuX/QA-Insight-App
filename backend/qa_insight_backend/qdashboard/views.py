import csv
from datetime import datetime
from io import StringIO

from django.contrib.auth.models import User
from django.db.models import Avg, Count, F, Sum
from django.http import HttpResponse
from django.utils import timezone
from rest_framework import status, viewsets
from rest_framework.authtoken.models import Token
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from qdashboard.models import (
    BusinessUnit,
    MonthlySubmission,
    ReportingPeriod,
    Site,
    SubmissionStatus,
    UserProfile,
    UserRole,
)
from qdashboard.permissions import (
    CanManageSubmissions,
    CanReviewSubmissions,
    IsAdminOrReadOnly,
)
from qdashboard.serializers import (
    AuthResponseSerializer,
    BusinessUnitSerializer,
    LoginSerializer,
    MonthlySubmissionSerializer,
    ReportingPeriodSerializer,
    ReviewActionSerializer,
    SiteSerializer,
    UserMasterSerializer,
    UserProfileSerializer,
)


def _apply_submission_filters(request, queryset):
    site_id = request.query_params.get("site")
    bu_id = request.query_params.get("business_unit")
    period_id = request.query_params.get("period")
    status_key = request.query_params.get("status")

    if site_id:
        queryset = queryset.filter(site_id=site_id)
    if bu_id:
        queryset = queryset.filter(business_unit_id=bu_id)
    if period_id:
        queryset = queryset.filter(reporting_period_id=period_id)
    if status_key:
        queryset = queryset.filter(status=status_key)
    return queryset


def _escape_pdf_text(value: str) -> str:
    return value.replace("\\", "\\\\").replace("(", "\\(").replace(")", "\\)")


def _build_simple_pdf(lines):
    text_instructions = ["BT", "/F1 11 Tf", "50 790 Td"]
    for index, line in enumerate(lines):
        if index > 0:
            text_instructions.append("0 -16 Td")
        text_instructions.append(f"({_escape_pdf_text(line[:110])}) Tj")
    text_instructions.append("ET")
    stream_data = "\n".join(text_instructions).encode("latin-1", errors="ignore")

    objects = []
    objects.append(b"<< /Type /Catalog /Pages 2 0 R >>")
    objects.append(b"<< /Type /Pages /Kids [3 0 R] /Count 1 >>")
    objects.append(
        b"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>"
    )
    objects.append(b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>")
    objects.append(
        b"<< /Length "
        + str(len(stream_data)).encode("ascii")
        + b" >>\nstream\n"
        + stream_data
        + b"\nendstream"
    )

    pdf_data = b"%PDF-1.4\n"
    offsets = [0]
    for index, obj in enumerate(objects, start=1):
        offsets.append(len(pdf_data))
        pdf_data += f"{index} 0 obj\n".encode("ascii") + obj + b"\nendobj\n"

    xref_offset = len(pdf_data)
    pdf_data += f"xref\n0 {len(objects) + 1}\n".encode("ascii")
    pdf_data += b"0000000000 65535 f \n"
    for offset in offsets[1:]:
        pdf_data += f"{offset:010} 00000 n \n".encode("ascii")

    pdf_data += (
        b"trailer\n<< /Size "
        + str(len(objects) + 1).encode("ascii")
        + b" /Root 1 0 R >>\nstartxref\n"
        + str(xref_offset).encode("ascii")
        + b"\n%%EOF"
    )
    return pdf_data


class LoginView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.validated_data["user"]
        payload = AuthResponseSerializer.from_user(user)
        return Response(payload)


class LogoutView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        Token.objects.filter(user=request.user).delete()
        return Response({"message": "Logged out successfully."})


class MeView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        profile, _ = UserProfile.objects.get_or_create(user=request.user)
        return Response(
            {
                "id": request.user.id,
                "username": request.user.username,
                "full_name": request.user.get_full_name(),
                "email": request.user.email,
                "role": profile.role,
                "role_name": profile.get_role_display(),
            }
        )


class UserMasterViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all().select_related("profile").order_by("username")
    serializer_class = UserMasterSerializer
    permission_classes = [IsAuthenticated, IsAdminOrReadOnly]


class UserProfileListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        users = User.objects.select_related("profile").all().order_by("username")
        serializer = UserProfileSerializer([u.profile for u in users], many=True)
        return Response(serializer.data)


class BusinessUnitViewSet(viewsets.ModelViewSet):
    queryset = BusinessUnit.objects.all().order_by("name")
    serializer_class = BusinessUnitSerializer
    permission_classes = [IsAuthenticated, IsAdminOrReadOnly]


class SiteViewSet(viewsets.ModelViewSet):
    queryset = Site.objects.select_related("business_unit").all().order_by("name")
    serializer_class = SiteSerializer
    permission_classes = [IsAuthenticated, IsAdminOrReadOnly]


class ReportingPeriodViewSet(viewsets.ModelViewSet):
    queryset = ReportingPeriod.objects.all().order_by("-year", "-month")
    serializer_class = ReportingPeriodSerializer
    permission_classes = [IsAuthenticated, IsAdminOrReadOnly]


class MonthlySubmissionViewSet(viewsets.ModelViewSet):
    serializer_class = MonthlySubmissionSerializer
    permission_classes = [IsAuthenticated, CanManageSubmissions]

    def get_queryset(self):
        profile, _ = UserProfile.objects.get_or_create(user=self.request.user)
        role = profile.role
        queryset = (
            MonthlySubmission.objects.select_related(
                "site",
                "business_unit",
                "reporting_period",
                "submitted_by",
                "reviewed_by",
            )
            .all()
            .order_by("-submitted_at")
        )
        queryset = _apply_submission_filters(self.request, queryset)
        if role == UserRole.ASSEMBLY:
            queryset = queryset.filter(submitted_by=self.request.user)
        return queryset

    def get_serializer_context(self):
        context = super().get_serializer_context()
        context["request"] = self.request
        return context


class PendingReviewList(APIView):
    permission_classes = [IsAuthenticated, CanReviewSubmissions]

    def get(self, request):
        pending_items = (
            MonthlySubmission.objects.select_related(
                "site", "business_unit", "reporting_period", "submitted_by"
            )
            .filter(status=SubmissionStatus.PENDING)
            .order_by("-submitted_at")
        )
        serializer = MonthlySubmissionSerializer(pending_items, many=True)
        return Response(serializer.data)


class ReviewActionView(APIView):
    permission_classes = [IsAuthenticated, CanReviewSubmissions]

    def post(self, request, submission_id):
        serializer = ReviewActionSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            submission = MonthlySubmission.objects.get(pk=submission_id)
        except MonthlySubmission.DoesNotExist:
            return Response({"message": "Submission not found."}, status=status.HTTP_404_NOT_FOUND)

        submission.status = serializer.validated_data["action"]
        submission.review_remarks = serializer.validated_data["remarks"]
        submission.reviewed_by = request.user
        submission.reviewed_at = timezone.now()
        submission.save()

        return Response(
            {"message": "Review decision recorded successfully.", "status": submission.status}
        )


class DashboardOverviewView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        submissions = _apply_submission_filters(request, MonthlySubmission.objects.all())
        totals = submissions.aggregate(
            total_submissions=Count("id"),
            total_checks=Sum("total_checks"),
            total_defects=Sum("defects_found"),
            avg_audit_score=Avg("audit_score"),
        )
        status_counts = submissions.values("status").annotate(count=Count("id"))
        comparative_by_bu = submissions.values(name=F("business_unit__name")).annotate(
            avg_score=Avg("audit_score"),
            submissions=Count("id"),
        )

        total_checks = totals["total_checks"] or 0
        total_defects = totals["total_defects"] or 0
        defect_rate = 0.0 if total_checks == 0 else round((total_defects / total_checks) * 100, 2)

        return Response(
            {
                "kpis": {
                    "total_submissions": totals["total_submissions"] or 0,
                    "avg_audit_score": round(float(totals["avg_audit_score"] or 0), 2),
                    "defect_rate": defect_rate,
                },
                "status_breakdown": list(status_counts),
                "comparative_analysis": list(comparative_by_bu),
            }
        )


class DashboardTrendView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        submissions = _apply_submission_filters(request, MonthlySubmission.objects.all())
        trend_data = (
            submissions.values("reporting_period__year", "reporting_period__month")
            .annotate(avg_audit_score=Avg("audit_score"), total_checks=Sum("total_checks"))
            .order_by("reporting_period__year", "reporting_period__month")
        )
        return Response({"trend": list(trend_data)})


class ReportTemplateListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        return Response(
            [
                {"id": "standard_monthly", "name": "Standard Monthly QA Summary"},
                {"id": "site_comparative", "name": "Site Comparative Performance"},
            ]
        )


class CustomReportView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        submissions = _apply_submission_filters(request, MonthlySubmission.objects.all())
        serializer = MonthlySubmissionSerializer(submissions, many=True)
        return Response(
            {
                "generated_at": timezone.now(),
                "count": submissions.count(),
                "results": serializer.data,
            }
        )


class ExportExcelReportView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        submissions = _apply_submission_filters(
            request,
            MonthlySubmission.objects.select_related("site", "business_unit", "reporting_period"),
        ).order_by("-submitted_at")

        output = StringIO()
        writer = csv.writer(output)
        writer.writerow(
            [
                "Acknowledgment",
                "Site",
                "Business Unit",
                "Reporting Period",
                "Checks",
                "Defects",
                "Audit Score",
                "Defect Rate",
                "Status",
            ]
        )
        for item in submissions:
            writer.writerow(
                [
                    item.acknowledgment_id,
                    item.site.name,
                    item.business_unit.name,
                    str(item.reporting_period),
                    item.total_checks,
                    item.defects_found,
                    float(item.audit_score),
                    item.defect_rate,
                    item.status,
                ]
            )

        response = HttpResponse(
            output.getvalue(),
            content_type="text/csv",
        )
        response["Content-Disposition"] = 'attachment; filename="qa_insight_report_excel.csv"'
        return response


class ExportPdfReportView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        submissions = _apply_submission_filters(
            request,
            MonthlySubmission.objects.select_related("site", "business_unit", "reporting_period"),
        ).order_by("-submitted_at")[:30]

        report_lines = [
            "QA Insight Hub - Standard Monthly Report",
            f"Generated on: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
            " ",
        ]
        for item in submissions:
            line = (
                f"{item.acknowledgment_id} | {item.site.code} | {item.reporting_period} | "
                f"Score: {item.audit_score} | Defect Rate: {item.defect_rate}% | {item.status}"
            )
            report_lines.append(line)

        pdf_bytes = _build_simple_pdf(report_lines)
        response = HttpResponse(pdf_bytes, content_type="application/pdf")
        response["Content-Disposition"] = 'attachment; filename="qa_insight_report.pdf"'
        return response


class HealthView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        return Response(
            {
                "message": "QA Insight Hub API is running",
                "module": "Q Dashboard",
                "server_time": timezone.now(),
            }
        )

# Create your views here.
