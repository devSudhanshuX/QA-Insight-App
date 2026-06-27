from rest_framework.permissions import BasePermission, SAFE_METHODS

from qdashboard.models import UserProfile, UserRole


def _get_role(user):
    if not user or not user.is_authenticated:
        return None
    profile, _ = UserProfile.objects.get_or_create(user=user)
    return profile.role


class IsAdminOrReadOnly(BasePermission):
    def has_permission(self, request, view):
        if request.method in SAFE_METHODS:
            return True
        return _get_role(request.user) == UserRole.ADMIN


class CanManageSubmissions(BasePermission):
    def has_permission(self, request, view):
        role = _get_role(request.user)
        if request.method in SAFE_METHODS:
            return role in {
                UserRole.ASSEMBLY,
                UserRole.QA,
                UserRole.MANAGEMENT,
                UserRole.ADMIN,
            }
        return role in {UserRole.ASSEMBLY, UserRole.ADMIN}


class CanReviewSubmissions(BasePermission):
    def has_permission(self, request, view):
        role = _get_role(request.user)
        return role in {UserRole.QA, UserRole.ADMIN}
