from django.conf import settings
from django.db import models


class Hospital(models.Model):
    name = models.CharField(max_length=160)
    address = models.CharField(max_length=255)
    phone = models.CharField(max_length=30, blank=True)

    def __str__(self):
        return self.name


class Doctor(models.Model):
    full_name = models.CharField(max_length=160)
    specialty = models.CharField(max_length=120)
    # Hospital principal conservé pour compatibilité avec les données existantes.
    hospital = models.ForeignKey(Hospital, on_delete=models.PROTECT, related_name="doctors")
    # Un médecin peut également consulter dans d'autres établissements.
    additional_hospitals = models.ManyToManyField(Hospital, blank=True, related_name="visiting_doctors")
    account = models.OneToOneField(settings.AUTH_USER_MODEL, null=True, blank=True, on_delete=models.SET_NULL, related_name="doctor_profile")
    description = models.TextField(blank=True)
    photo_url = models.URLField(blank=True)
    is_active = models.BooleanField(default=True)

    def __str__(self):
        return f"{self.full_name} — {self.specialty}"


class PatientProfile(models.Model):
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="patient_profile")
    photo_url = models.URLField(blank=True)

    def __str__(self):
        return f"Profil de {self.user.get_username()}"


class DoctorAvailability(models.Model):
    WEEKDAYS = [
        (0, "Lundi"), (1, "Mardi"), (2, "Mercredi"), (3, "Jeudi"),
        (4, "Vendredi"), (5, "Samedi"), (6, "Dimanche"),
    ]
    doctor = models.ForeignKey(Doctor, on_delete=models.CASCADE, related_name="availabilities")
    weekday = models.PositiveSmallIntegerField(choices=WEEKDAYS, help_text="0 = lundi, 6 = dimanche")
    start_time = models.TimeField()
    end_time = models.TimeField()
    slot_minutes = models.PositiveSmallIntegerField(default=30)
    is_active = models.BooleanField(default=True)

    class Meta:
        ordering = ["weekday", "start_time"]
        constraints = [
            models.CheckConstraint(condition=models.Q(end_time__gt=models.F("start_time")), name="availability_end_after_start"),
            models.CheckConstraint(condition=models.Q(slot_minutes__gte=10, slot_minutes__lte=240), name="availability_slot_minutes_range"),
        ]

    def __str__(self):
        return f"{self.doctor} — {self.get_weekday_display()} {self.start_time}-{self.end_time}"


class DoctorAbsence(models.Model):
    doctor = models.ForeignKey(Doctor, on_delete=models.CASCADE, related_name="absences")
    start_datetime = models.DateTimeField()
    end_datetime = models.DateTimeField()
    reason = models.CharField(max_length=200, blank=True)

    class Meta:
        ordering = ["start_datetime"]
        constraints = [
            models.CheckConstraint(condition=models.Q(end_datetime__gt=models.F("start_datetime")), name="absence_end_after_start"),
        ]

    def __str__(self):
        return f"Absence {self.doctor} ({self.start_datetime:%d/%m/%Y})"


class Appointment(models.Model):
    STATUS = [("booked", "Réservé"), ("cancelled", "Annulé"), ("completed", "Terminé")]
    patient = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="appointments")
    doctor = models.ForeignKey(Doctor, on_delete=models.PROTECT, related_name="appointments")
    hospital = models.ForeignKey(Hospital, on_delete=models.PROTECT, related_name="appointments", null=True, blank=True)
    appointment_date = models.DateField()
    appointment_time = models.TimeField()
    reason = models.CharField(max_length=250, blank=True)
    status = models.CharField(max_length=20, choices=STATUS, default="booked")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["appointment_date", "appointment_time"]
        constraints = [
            models.UniqueConstraint(
                fields=["doctor", "appointment_date", "appointment_time"],
                condition=models.Q(status="booked"),
                name="unique_booked_doctor_slot",
            ),
        ]

    def __str__(self):
        return f"{self.patient} / {self.doctor} / {self.appointment_date}"
