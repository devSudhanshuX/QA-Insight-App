from django.apps import AppConfig


class QdashboardConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'qdashboard'

    def ready(self):
        import qdashboard.signals  # noqa: F401
