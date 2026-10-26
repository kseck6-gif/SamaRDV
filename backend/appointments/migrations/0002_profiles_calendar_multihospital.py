# Ajouts progressifs : profils, calendrier partagé et médecins multi-hôpitaux.
from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


def populate_appointment_hospital(apps, schema_editor):
    Appointment = apps.get_model("appointments", "Appointment")
    for item in Appointment.objects.filter(hospital__isnull=True).select_related("doctor"):
        item.hospital_id = item.doctor.hospital_id
        item.save(update_fields=["hospital"])


class Migration(migrations.Migration):
    dependencies = [
        ("appointments", "0001_initial"),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.AddField(
            model_name="doctor",
            name="photo_url",
            field=models.URLField(blank=True),
        ),
        migrations.AddField(
            model_name="doctor",
            name="account",
            field=models.OneToOneField(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name="doctor_profile", to=settings.AUTH_USER_MODEL),
        ),
        migrations.AddField(
            model_name="doctor",
            name="additional_hospitals",
            field=models.ManyToManyField(blank=True, related_name="visiting_doctors", to="appointments.hospital"),
        ),
        migrations.AddField(
            model_name="appointment",
            name="hospital",
            field=models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.PROTECT, related_name="appointments", to="appointments.hospital"),
        ),
        migrations.CreateModel(
            name="PatientProfile",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("photo_url", models.URLField(blank=True)),
                ("user", models.OneToOneField(on_delete=django.db.models.deletion.CASCADE, related_name="patient_profile", to=settings.AUTH_USER_MODEL)),
            ],
        ),
        migrations.CreateModel(
            name="DoctorAvailability",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("weekday", models.PositiveSmallIntegerField(choices=[(0, "Lundi"), (1, "Mardi"), (2, "Mercredi"), (3, "Jeudi"), (4, "Vendredi"), (5, "Samedi"), (6, "Dimanche")], help_text="0 = lundi, 6 = dimanche")),
                ("start_time", models.TimeField()),
                ("end_time", models.TimeField()),
                ("slot_minutes", models.PositiveSmallIntegerField(default=30)),
                ("is_active", models.BooleanField(default=True)),
                ("doctor", models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name="availabilities", to="appointments.doctor")),
            ],
            options={"ordering": ["weekday", "start_time"]},
        ),
        migrations.AddConstraint(
            model_name="doctoravailability",
            constraint=models.CheckConstraint(condition=models.Q(("end_time__gt", models.F("start_time"))), name="availability_end_after_start"),
        ),
        migrations.AddConstraint(
            model_name="doctoravailability",
            constraint=models.CheckConstraint(condition=models.Q(("slot_minutes__gte", 10), ("slot_minutes__lte", 240)), name="availability_slot_minutes_range"),
        ),
        migrations.CreateModel(
            name="DoctorAbsence",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("start_datetime", models.DateTimeField()),
                ("end_datetime", models.DateTimeField()),
                ("reason", models.CharField(blank=True, max_length=200)),
                ("doctor", models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name="absences", to="appointments.doctor")),
            ],
            options={"ordering": ["start_datetime"]},
        ),
        migrations.AddConstraint(
            model_name="doctorabsence",
            constraint=models.CheckConstraint(condition=models.Q(("end_datetime__gt", models.F("start_datetime"))), name="absence_end_after_start"),
        ),
        migrations.RunPython(populate_appointment_hospital, migrations.RunPython.noop),
    ]
