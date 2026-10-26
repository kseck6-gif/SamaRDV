from django.contrib.auth.models import User
from django.utils import timezone
from rest_framework import serializers
from .models import Hospital, Doctor, Appointment, DoctorAvailability, PatientProfile


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=8)
    first_name = serializers.CharField(required=True)
    last_name = serializers.CharField(required=True)

    class Meta:
        model = User
        fields = ["id", "username", "first_name", "last_name", "email", "password"]

    def create(self, validated_data):
        password = validated_data.pop("password")
        user = User.objects.create_user(password=password, **validated_data)
        PatientProfile.objects.get_or_create(user=user)
        return user


class HospitalSerializer(serializers.ModelSerializer):
    class Meta:
        model = Hospital
        fields = ["id", "name", "address", "phone"]


class DoctorSerializer(serializers.ModelSerializer):
    hospital_name = serializers.CharField(source="hospital.name", read_only=True)
    hospital_address = serializers.CharField(source="hospital.address", read_only=True)
    additional_hospitals = HospitalSerializer(many=True, read_only=True)

    class Meta:
        model = Doctor
        fields = ["id", "full_name", "specialty", "hospital", "hospital_name",
                  "hospital_address", "additional_hospitals", "description", "photo_url"]


class DoctorAvailabilitySerializer(serializers.ModelSerializer):
    weekday_label = serializers.CharField(source="get_weekday_display", read_only=True)

    class Meta:
        model = DoctorAvailability
        fields = ["id", "doctor", "weekday", "weekday_label", "start_time", "end_time", "slot_minutes", "is_active"]


class PatientProfileSerializer(serializers.ModelSerializer):
    username = serializers.CharField(source="user.username", read_only=True)
    first_name = serializers.CharField(source="user.first_name", read_only=True)
    last_name = serializers.CharField(source="user.last_name", read_only=True)
    email = serializers.EmailField(source="user.email", read_only=True)

    class Meta:
        model = PatientProfile
        fields = ["username", "first_name", "last_name", "email", "photo_url"]


class AppointmentSerializer(serializers.ModelSerializer):
    doctor_name = serializers.CharField(source="doctor.full_name", read_only=True)
    specialty = serializers.CharField(source="doctor.specialty", read_only=True)
    hospital_name = serializers.SerializerMethodField()

    class Meta:
        model = Appointment
        fields = ["id", "doctor", "doctor_name", "specialty", "hospital", "hospital_name",
                  "appointment_date", "appointment_time", "reason", "status", "created_at"]
        read_only_fields = ["id", "status", "created_at"]

    def get_hospital_name(self, obj):
        hospital = obj.hospital or obj.doctor.hospital
        return hospital.name if hospital else ""

    def validate(self, attrs):
        date_value = attrs.get("appointment_date", getattr(self.instance, "appointment_date", None))
        time_value = attrs.get("appointment_time", getattr(self.instance, "appointment_time", None))
        doctor = attrs.get("doctor", getattr(self.instance, "doctor", None))
        hospital = attrs.get("hospital") or (doctor.hospital if doctor else None)

        if date_value and date_value < timezone.localdate():
            raise serializers.ValidationError("La date du rendez-vous ne peut pas être passée.")
        if not doctor or not doctor.is_active:
            raise serializers.ValidationError("Ce médecin n'est pas disponible.")
        allowed_hospitals = {doctor.hospital_id, *doctor.additional_hospitals.values_list("id", flat=True)}
        if hospital and hospital.id not in allowed_hospitals:
            raise serializers.ValidationError("Ce médecin ne consulte pas dans cet hôpital.")

        if date_value and time_value:
            from datetime import datetime, timedelta
            from .models import DoctorAvailability, DoctorAbsence
            existing = Appointment.objects.filter(
                doctor=doctor, appointment_date=date_value, status="booked"
            ).exclude(pk=self.instance.pk if self.instance else None)
            # Le créneau dure 30 minutes par défaut; si un horaire hebdomadaire existe, il définit la durée.
            weekday = date_value.weekday()
            schedule = DoctorAvailability.objects.filter(doctor=doctor, weekday=weekday, is_active=True)
            duration = schedule.first().slot_minutes if schedule.exists() else 30
            start = datetime.combine(date_value, time_value)
            end = start + timedelta(minutes=duration)
            for booked in existing:
                booked_start = datetime.combine(booked.appointment_date, booked.appointment_time)
                booked_duration = duration
                if booked_start < end and booked_start + timedelta(minutes=booked_duration) > start:
                    raise serializers.ValidationError("Ce médecin a déjà un rendez-vous à cette heure ou sur une partie de ce créneau.")

            absences = DoctorAbsence.objects.filter(
                doctor=doctor, start_datetime__lt=timezone.make_aware(end), end_datetime__gt=timezone.make_aware(start)
            )
            if absences.exists():
                raise serializers.ValidationError("Le médecin est indisponible sur ce créneau.")

            # Pour les médecins ayant défini un calendrier, n'accepter que les créneaux planifiés.
            if schedule.exists():
                fits = False
                for item in schedule:
                    sched_start = datetime.combine(date_value, item.start_time)
                    sched_end = datetime.combine(date_value, item.end_time)
                    if start >= sched_start and end <= sched_end and (start - sched_start).total_seconds() % (item.slot_minutes * 60) == 0:
                        fits = True
                        break
                if not fits:
                    raise serializers.ValidationError("Cette heure n'est pas dans les disponibilités du médecin.")
        attrs["hospital"] = hospital
        return attrs

    def create(self, validated_data):
        return Appointment.objects.create(patient=self.context["request"].user, **validated_data)
