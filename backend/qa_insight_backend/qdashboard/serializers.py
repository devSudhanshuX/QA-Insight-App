from datetime import date
from uuid import uuid4

from django.contrib.auth import authenticate
from django.contrib.auth.models import User
from rest_framework import serializers
from rest_framework.authtoken.models import Token

from qdashboard.models import (
    BusinessUnit,
    MonthlySubmission,
    ReportingPeriod,
    Site,
    SubmissionStatus,
    UserProfile,
)


class LoginSerializer(serializers.Serializer):
    username = serializers.CharField()
    password = serializers.CharField()

    def validate(self, attrs):
        user = authenticate(username=attrs["username"], password=attrs["password"])
        if not user:
            raise serializers.ValidationError("Invalid username or password.")
        attrs["user"] = user
        return attrs


class UserProfileSerializer(serializers.ModelSerializer):
    full_name = serializers.CharField(source="user.get_full_name", read_only=True)
    username = serializers.CharField(source="user.username", read_only=True)
    email = serializers.EmailField(source="user.email", read_only=True)

    class Meta:
        model = UserProfile
        fields = ["id", "username", "full_name", "email", "role"]


class UserMasterSerializer(serializers.ModelSerializer):
    role = serializers.ChoiceField(choices=UserProfile._meta.get_field("role").choices, write_only=True)
    role_name = serializers.CharField(source="profile.get_role_display", read_only=True)

    class Meta:
        model = User
        fields = ["id", "username", "first_name", "last_name", "email", "password", "role", "role_name"]
        extra_kwargs = {"password": {"write_only": True}}

    def create(self, validated_data):
        role = validated_data.pop("role")
        password = validated_data.pop("password")
        user = User.objects.create_user(password=password, **validated_data)
        user.profile.role = role
        user.profile.save()
        return user

    def update(self, instance, validated_data):
        role = validated_data.pop("role", None)
        password = validated_data.pop("password", None)
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        if password:
            instance.set_password(password)
        instance.save()
        if role and hasattr(instance, "profile"):
            instance.profile.role = role
            instance.profile.save()
        return instance


class AuthResponseSerializer(serializers.Serializer):
    token = serializers.CharField()
    user_id = serializers.IntegerField()
    username = serializers.CharField()
    role = serializers.CharField()
    role_name = serializers.CharField()

    @staticmethod
    def from_user(user: User):
        profile, _ = UserProfile.objects.get_or_create(user=user)
        token, _ = Token.objects.get_or_create(user=user)
        return {
            "token": token.key,
            "user_id": user.id,
            "username": user.username,
            "role": profile.role,
            "role_name": profile.get_role_display(),
        }


class BusinessUnitSerializer(serializers.ModelSerializer):
    class Meta:
        model = BusinessUnit
        fields = ["id", "name", "code", "is_active"]


class SiteSerializer(serializers.ModelSerializer):
    business_unit_name = serializers.CharField(source="business_unit.name", read_only=True)

    class Meta:
        model = Site
        fields = ["id", "name", "code", "business_unit", "business_unit_name", "is_active"]


class ReportingPeriodSerializer(serializers.ModelSerializer):
    label = serializers.SerializerMethodField()

    class Meta:
        model = ReportingPeriod
        fields = [
            "id",
            "year",
            "month",
            "start_date",
            "end_date",
            "cutoff_date",
            "is_locked",
            "label",
        ]

    def get_label(self, obj):
        return f"{obj.month:02d}/{obj.year}"


class MonthlySubmissionSerializer(serializers.ModelSerializer):
    site_name = serializers.CharField(source="site.name", read_only=True)
    business_unit_name = serializers.CharField(source="business_unit.name", read_only=True)
    reporting_period_label = serializers.SerializerMethodField()
    submitted_by_name = serializers.CharField(source="submitted_by.get_full_name", read_only=True)
    reviewed_by_name = serializers.CharField(source="reviewed_by.get_full_name", read_only=True)
    defect_rate = serializers.FloatField(read_only=True)

    class Meta:
        model = MonthlySubmission
        fields = [
            "id",
            "site",
            "site_name",
            "business_unit",
            "business_unit_name",
            "reporting_period",
            "reporting_period_label",
            "submitted_by",
            "submitted_by_name",
            "total_checks",
            "defects_found",
            "audit_score",
            "defect_rate",
            "observations",
            "acknowledgment_id",
            "status",
            "review_remarks",
            "reviewed_by",
            "reviewed_by_name",
            "submitted_at",
            "reviewed_at",
        ]
        read_only_fields = [
            "submitted_by",
            "acknowledgment_id",
            "status",
            "reviewed_by",
            "submitted_at",
            "reviewed_at",
        ]

    def validate(self, attrs):
        reporting_period = attrs.get("reporting_period")
        site = attrs.get("site")
        business_unit = attrs.get("business_unit")

        if site and business_unit and site.business_unit_id != business_unit.id:
            raise serializers.ValidationError("Selected site does not belong to this business unit.")

        if reporting_period:
            today = date.today()
            if reporting_period.is_locked:
                raise serializers.ValidationError("This reporting period is locked.")
            if today > reporting_period.cutoff_date:
                raise serializers.ValidationError("Submission cut-off date has passed.")

        return attrs

    def get_reporting_period_label(self, obj):
        return str(obj.reporting_period)

    def create(self, validated_data):
        validated_data["submitted_by"] = self.context["request"].user
        validated_data["acknowledgment_id"] = f"ACK-{uuid4().hex[:10].upper()}"
        return super().create(validated_data)


class ReviewActionSerializer(serializers.Serializer):
    action = serializers.ChoiceField(
        choices=[
            SubmissionStatus.APPROVED,
            SubmissionStatus.REJECTED,
            SubmissionStatus.SEND_BACK,
            SubmissionStatus.REVIEWED,
        ]
    )
    remarks = serializers.CharField(allow_blank=False)
