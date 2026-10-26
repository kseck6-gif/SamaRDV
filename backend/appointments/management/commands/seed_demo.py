from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand

from appointments.models import Hospital, Doctor, PatientProfile


class Command(BaseCommand):
    help = "Ajoute des données fictives de démonstration et un compte patient prérempli."

    def handle(self, *args, **options):
        h1, _ = Hospital.objects.get_or_create(
            name="Hôpital de démonstration de Dakar",
            defaults={"address": "Dakar, Sénégal", "phone": "33 800 00 00"},
        )
        h2, _ = Hospital.objects.get_or_create(
            name="Centre médical de démonstration de Thiès",
            defaults={"address": "Thiès, Sénégal", "phone": "33 900 00 00"},
        )

        for name, specialty, hospital in [
            ("Dr Awa Diop", "Cardiologie", h1),
            ("Dr Mamadou Fall", "Pédiatrie", h1),
            ("Dr Fatou Ndiaye", "Médecine générale", h2),
            ("Dr Ibrahima Ba", "Dermatologie", h2),
        ]:
            Doctor.objects.get_or_create(
                full_name=name,
                specialty=specialty,
                hospital=hospital,
                defaults={"description": "Profil fictif pour la démonstration académique."},
            )

        User = get_user_model()
        username = "adama"
        password = "Password123!"
        user, created = User.objects.get_or_create(
            username=username,
            defaults={
                "first_name": "Adama",
                "last_name": "Fall",
                "email": "adama@example.com",
                "is_staff": False,
            },
        )
        user.first_name = "Adama"
        user.last_name = "Fall"
        user.email = "adama@example.com"
        user.is_staff = False
        user.set_password(password)
        user.save(update_fields=["password", "first_name", "last_name", "email", "is_staff"])

        PatientProfile.objects.get_or_create(user=user)

        self.stdout.write(
            self.style.SUCCESS(
                f"Données de démonstration ajoutées. Identifiants de test : username={username}, password={password}"
            )
        )
