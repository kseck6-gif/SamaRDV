from django.contrib.auth.models import User
from django.db import IntegrityError, transaction
from django.db.models import Q
from rest_framework import generics, permissions, viewsets, status
from rest_framework.decorators import action
from rest_framework.exceptions import PermissionDenied
from rest_framework.response import Response
from .models import Hospital, Doctor, Appointment, DoctorAvailability, PatientProfile
from .serializers import (
    RegisterSerializer, HospitalSerializer, DoctorSerializer, AppointmentSerializer,
    DoctorAvailabilitySerializer, PatientProfileSerializer,
)


class RegisterView(generics.CreateAPIView):
    queryset = User.objects.all()
    serializer_class = RegisterSerializer
    permission_classes = [permissions.AllowAny]


class HospitalViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Hospital.objects.all().order_by("name")
    serializer_class = HospitalSerializer
    permission_classes = [permissions.AllowAny]


class DoctorViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Doctor.objects.filter(is_active=True).select_related("hospital").prefetch_related("additional_hospitals").order_by("full_name")
    serializer_class = DoctorSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        qs = super().get_queryset()
        search = self.request.query_params.get("search", "").strip()
        if search:
            qs = qs.filter(
                Q(full_name__icontains=search) |
                Q(specialty__icontains=search) |
                Q(hospital__name__icontains=search) |
                Q(additional_hospitals__name__icontains=search)
            ).distinct()
        return qs


class DoctorCalendarPermission(permissions.BasePermission):
    def has_permission(self, request, view):
        if request.method in permissions.SAFE_METHODS:
            return True
        return bool(request.user and request.user.is_authenticated and (
            request.user.is_staff or Doctor.objects.filter(account=request.user).exists()
        ))

    def has_object_permission(self, request, view, obj):
        if request.method in permissions.SAFE_METHODS:
            return True
        return bool(request.user.is_staff or obj.doctor.account_id == request.user.id)


class DoctorAvailabilityViewSet(viewsets.ModelViewSet):
    serializer_class = DoctorAvailabilitySerializer
    permission_classes = [DoctorCalendarPermission]
    http_method_names = ["get", "post", "patch", "delete", "head", "options"]

    def get_queryset(self):
        qs = DoctorAvailability.objects.select_related("doctor")
        if self.request.method in permissions.SAFE_METHODS:
            qs = qs.filter(is_active=True)
        doctor_id = self.request.query_params.get("doctor")
        weekday = self.request.query_params.get("weekday")
        if doctor_id:
            qs = qs.filter(doctor_id=doctor_id)
        if weekday is not None:
            qs = qs.filter(weekday=weekday)
        return qs

    def perform_create(self, serializer):
        doctor = serializer.validated_data["doctor"]
        if not self.request.user.is_staff and doctor.account_id != self.request.user.id:
            raise PermissionDenied("Vous ne pouvez gérer que votre propre calendrier.")
        serializer.save()

    def perform_update(self, serializer):
        doctor = serializer.validated_data.get("doctor", serializer.instance.doctor)
        if not self.request.user.is_staff and doctor.account_id != self.request.user.id:
            raise PermissionDenied("Vous ne pouvez gérer que votre propre calendrier.")
        serializer.save()


class PatientProfileView(generics.RetrieveUpdateAPIView):
    serializer_class = PatientProfileSerializer
    permission_classes = [permissions.IsAuthenticated]
    http_method_names = ["get", "patch", "head", "options"]

    def get_object(self):
        profile, _ = PatientProfile.objects.get_or_create(user=self.request.user)
        return profile


class AppointmentViewSet(viewsets.ModelViewSet):
    serializer_class = AppointmentSerializer
    permission_classes = [permissions.IsAuthenticated]
    http_method_names = ["get", "post", "head", "options"]

    def get_queryset(self):
        return Appointment.objects.filter(patient=self.request.user).select_related("doctor", "doctor__hospital", "hospital")

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            with transaction.atomic():
                appointment = serializer.save()
        except IntegrityError:
            return Response(
                {"detail": "Ce créneau vient d'être réservé. Veuillez choisir une autre heure."},
                status=status.HTTP_409_CONFLICT,
            )
        return Response(self.get_serializer(appointment).data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=["post"])
    def cancel(self, request, pk=None):
        item = self.get_object()
        if item.status != "booked":
            return Response({"detail": "Ce rendez-vous n'est plus réservable."}, status=status.HTTP_400_BAD_REQUEST)
        item.status = "cancelled"
        item.save(update_fields=["status"])
        return Response({"detail": "Rendez-vous annulé.", "status": item.status})
