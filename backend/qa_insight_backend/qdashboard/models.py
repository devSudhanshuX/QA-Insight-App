from django.contrib.auth.models import User
from django.db import models
from django.utils import timezone


class UserRole(models.TextChoices):
    ASSEMBLY = "assembly_user", "Assembly User"
    QA = "qa_representative", "QA Representative"
    MANAGEMENT = "management_viewer", "Management Viewer"
    ADMIN = "admin", "Admin"


class SubmissionStatus(models.TextChoices):
    PENDING = "pending", "Pending"
    REVIEWED = "reviewed", "Reviewed"
    APPROVED = "approved", "Approved"
    REJECTED = "rejected", "Rejected"
    SEND_BACK = "send_back", "Send Back"


class UserProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="profile")
    role = models.CharField(max_length=32, choices=UserRole.choices, default=UserRole.ASSEMBLY)

    def __str__(self) -> str:
        return f"{self.user.username} ({self.get_role_display()})"


class BusinessUnit(models.Model):
    name = models.CharField(max_length=120, unique=True)
    code = models.CharField(max_length=20, unique=True)
    is_active = models.BooleanField(default=True)

    def __str__(self) -> str:
        return f"{self.code} - {self.name}"


class Site(models.Model):
    name = models.CharField(max_length=120)
    code = models.CharField(max_length=20, unique=True)
    business_unit = models.ForeignKey(BusinessUnit, on_delete=models.PROTECT, related_name="sites")
    is_active = models.BooleanField(default=True)

    class Meta:
        unique_together = ("name", "business_unit")

    def __str__(self) -> str:
        return f"{self.code} - {self.name}"


class ReportingPeriod(models.Model):
    year = models.PositiveIntegerField()
    month = models.PositiveIntegerField()
    start_date = models.DateField()
    end_date = models.DateField()
    cutoff_date = models.DateField()
    is_locked = models.BooleanField(default=False)

    class Meta:
        unique_together = ("year", "month")
        ordering = ("-year", "-month")

    def __str__(self) -> str:
        return f"{self.month:02d}-{self.year}"


class MonthlySubmission(models.Model):
    site = models.ForeignKey(Site, on_delete=models.PROTECT, related_name="submissions")
    business_unit = models.ForeignKey(BusinessUnit, on_delete=models.PROTECT, related_name="submissions")
    reporting_period = models.ForeignKey(
        ReportingPeriod, on_delete=models.PROTECT, related_name="submissions"
    )
    submitted_by = models.ForeignKey(
        User, on_delete=models.PROTECT, related_name="submitted_monthly_data"
    )
    total_checks = models.PositiveIntegerField()
    defects_found = models.PositiveIntegerField()
    audit_score = models.DecimalField(max_digits=5, decimal_places=2)
    observations = models.TextField()
    acknowledgment_id = models.CharField(max_length=30, unique=True)
    status = models.CharField(
        max_length=20, choices=SubmissionStatus.choices, default=SubmissionStatus.PENDING
    )
    review_remarks = models.TextField(blank=True)
    reviewed_by = models.ForeignKey(
        User,
        on_delete=models.PROTECT,
        related_name="reviewed_monthly_data",
        null=True,
        blank=True,
    )
    submitted_at = models.DateTimeField(default=timezone.now)
    reviewed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        unique_together = ("site", "reporting_period")
        ordering = ("-submitted_at",)

    @property
    def defect_rate(self) -> float:
        if self.total_checks == 0:
            return 0.0
        return round((self.defects_found / self.total_checks) * 100, 2)

    def __str__(self) -> str:
        return f"{self.acknowledgment_id} - {self.site.code} - {self.reporting_period}"

# Create your models here.
