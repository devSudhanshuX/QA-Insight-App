from datetime import date

from django.contrib.auth.models import User
from django.core.management.base import BaseCommand

from qdashboard.models import BusinessUnit, ReportingPeriod, Site, UserRole


class Command(BaseCommand):
    help = "Bootstraps demo users and master data for QA Insight Hub."

    def handle(self, *args, **options):
        self._create_users()
        self._create_master_data()
        self.stdout.write(self.style.SUCCESS("Demo data bootstrap completed."))

    def _create_users(self):
        user_rows = [
            ("assembly_user", "assembly123", "Assembly", "User", UserRole.ASSEMBLY),
            ("qa_representative", "qa123", "QA", "Representative", UserRole.QA),
            ("management_viewer", "viewer123", "Management", "Viewer", UserRole.MANAGEMENT),
            ("admin", "admin123", "System", "Admin", UserRole.ADMIN),
        ]
        for username, password, first_name, last_name, role in user_rows:
            user, created = User.objects.get_or_create(
                username=username,
                defaults={
                    "first_name": first_name,
                    "last_name": last_name,
                    "email": f"{username}@qainsighthub.com",
                },
            )
            if created:
                user.set_password(password)
                user.save()
            user.profile.role = role
            user.profile.save()

    def _create_master_data(self):
        bu_auto, _ = BusinessUnit.objects.get_or_create(name="Automotive", code="AUTO")
        bu_electronics, _ = BusinessUnit.objects.get_or_create(
            name="Electronics", code="ELEC"
        )

        Site.objects.get_or_create(name="Pune Plant", code="PUNE", business_unit=bu_auto)
        Site.objects.get_or_create(name="Chennai Plant", code="CHEN", business_unit=bu_auto)
        Site.objects.get_or_create(
            name="Bangalore Hub", code="BLR", business_unit=bu_electronics
        )

        ReportingPeriod.objects.get_or_create(
            year=2026,
            month=6,
            defaults={
                "start_date": date(2026, 6, 1),
                "end_date": date(2026, 6, 30),
                "cutoff_date": date(2026, 6, 29),
                "is_locked": False,
            },
        )
        ReportingPeriod.objects.get_or_create(
            year=2026,
            month=5,
            defaults={
                "start_date": date(2026, 5, 1),
                "end_date": date(2026, 5, 31),
                "cutoff_date": date(2026, 5, 29),
                "is_locked": True,
            },
        )
