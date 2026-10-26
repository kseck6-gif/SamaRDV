from rest_framework.routers import DefaultRouter
from .views import HospitalViewSet, DoctorViewSet, AppointmentViewSet, DoctorAvailabilityViewSet, PatientProfileView
from django.urls import path

router = DefaultRouter()
router.register("hospitals", HospitalViewSet, basename="hospital")
router.register("doctors", DoctorViewSet, basename="doctor")
router.register("appointments", AppointmentViewSet, basename="appointment")
router.register("availability", DoctorAvailabilityViewSet, basename="availability")

urlpatterns = router.urls + [
    path("profile/", PatientProfileView.as_view(), name="patient-profile"),
]
