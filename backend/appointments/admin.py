from django.contrib import admin
from .models import Hospital, Doctor, Appointment, PatientProfile, DoctorAvailability, DoctorAbsence


@admin.register(Hospital)
class HospitalAdmin(admin.ModelAdmin):
    search_fields = ("name", "address")
    list_display = ("name", "address", "phone")


@admin.register(Doctor)
class DoctorAdmin(admin.ModelAdmin):
    list_display = ("full_name", "specialty", "hospital", "is_active")
    list_filter = ("specialty", "hospital", "is_active")
    search_fields = ("full_name", "specialty")
    filter_horizontal = ("additional_hospitals",)


@admin.register(Appointment)
class AppointmentAdmin(admin.ModelAdmin):
    list_display = ("doctor", "patient", "hospital", "appointment_date", "appointment_time", "status")
    list_filter = ("status", "hospital", "appointment_date")
    search_fields = ("doctor__full_name", "patient__username")


@admin.register(DoctorAvailability)
class DoctorAvailabilityAdmin(admin.ModelAdmin):
    list_display = ("doctor", "weekday", "start_time", "end_time", "slot_minutes", "is_active")
    list_filter = ("weekday", "is_active", "doctor")


@admin.register(DoctorAbsence)
class DoctorAbsenceAdmin(admin.ModelAdmin):
    list_display = ("doctor", "start_datetime", "end_datetime", "reason")


@admin.register(PatientProfile)
class PatientProfileAdmin(admin.ModelAdmin):
    list_display = ("user", "photo_url")
    search_fields = ("user__username", "user__first_name", "user__last_name")
