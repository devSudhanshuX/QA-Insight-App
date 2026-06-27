from django.contrib import admin
from qdashboard.models import (
    BusinessUnit,
    MonthlySubmission,
    ReportingPeriod,
    Site,
    UserProfile,
)

admin.site.register(UserProfile)
admin.site.register(BusinessUnit)
admin.site.register(Site)
admin.site.register(ReportingPeriod)
admin.site.register(MonthlySubmission)

# Register your models here.
