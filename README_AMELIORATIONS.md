# SamaRDV — version améliorée (base de travail)

Cette copie ajoute des améliorations progressives sans supprimer les routes d'inscription, connexion, médecins, rendez-vous et annulation existantes.

## Améliorations incluses
- Thème Flutter plus cohérent (bleu médical, cartes arrondies, champs et boutons harmonisés).
- Logo SamaRDV ajouté dans `frontend/sama_rdv/assets/images/samardv_logo.png`.
- Cartes médecins avec affichage de `photo_url` et avatar de remplacement.
- Profil patient avec champ de lien photo facultatif.
- Un médecin peut être associé à plusieurs hôpitaux, en gardant l'hôpital principal existant.
- Le rendez-vous mémorise l'hôpital sélectionné.
- Base du calendrier général : horaires hebdomadaires, durée des créneaux et absences.
- Endpoint de consultation des horaires : `GET /api/availability/?doctor=ID` ou `?weekday=0`.
- Les horaires peuvent être gérés dans Django Admin et par le compte du médecin lié au champ « account ».
- Vérification côté serveur des chevauchements de rendez-vous et des absences; la contrainte unique en base continue de bloquer deux réservations du même médecin à la même date/heure.
- Les anciens médecins sans horaire défini conservent le comportement précédent (créneaux saisis manuellement).

## IMPORTANT — sauvegarde avant installation
1. Fermer l'application Flutter et arrêter le serveur Django.
2. Faire une copie complète de votre dossier actuel `SamaRDV`, notamment `backend/db.sqlite3`.
3. Extraire cette archive dans un nouveau dossier, par exemple `SamaRDV_ameliore`, pour tester sans écraser la version originale.

## Appliquer la migration Django
Dans PowerShell, depuis le dossier backend de cette copie :

```powershell
cd C:\Users\DELL3190\Desktop\soutenance\SamaRDV_ameliore\backend
.\.venv\Scripts\Activate.ps1
python manage.py check
python manage.py migrate
python manage.py runserver
```

Si le dossier de l'environnement `.venv` n'a pas été inclus, recréez-le et installez les dépendances :

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
python manage.py migrate
python manage.py runserver
```

Ne supprimez pas `db.sqlite3` : elle peut contenir vos médecins et rendez-vous. La migration `0002_profiles_calendar_multihospital.py` conserve les modèles existants et associe l'hôpital principal aux rendez-vous historiques.

## Lancer Flutter
Dans un deuxième PowerShell :

```powershell
cd C:\Users\DELL3190\Desktop\soutenance\SamaRDV_ameliore\frontend\sama_rdv
$env:Path += ";C:\src\flutter\bin"
flutter pub get
flutter analyze
flutter run -d chrome
```

## Ajouter les photos
- Médecins : ouvrir `/admin/`, modifier un médecin et renseigner `photo_url` avec un lien direct d'image commençant par `https://`.
- Patients : se connecter dans l'application, ouvrir l'icône de profil et coller un lien d'image accessible en ligne. Laisser vide pour utiliser l'avatar par défaut.
- Pour le moment les photos utilisent des URL; le téléversement direct depuis le téléphone n'est pas encore inclus.

## Configurer un médecin multi-hôpitaux et son calendrier
1. Dans Django Admin, associer les hôpitaux secondaires dans « Additional hospitals ».
2. Pour permettre à un médecin de gérer lui-même son calendrier, associer son compte utilisateur dans le champ « Account » de la fiche médecin. Ce lien doit être fait par un administrateur.
3. Créer ses horaires dans « Doctor availabilities » : jour de la semaine, début, fin et durée (30 minutes par défaut).
4. Ajouter les absences si nécessaire dans « Doctor absences ».
5. Les horaires sont communs au médecin, quel que soit l'hôpital sélectionné. Le choix de l'hôpital est conservé sur le rendez-vous.

## Limites de cette version
C'est une première intégration prudente, pas une refonte totale : le calendrier existe côté Django et les horaires configurés sont vérifiés lors de la réservation, mais l'interface Flutter de gestion visuelle des horaires par le médecin et l'affichage des créneaux disponibles sous forme de calendrier restent à terminer. Le profil photo accepte des liens, pas encore l'envoi de fichiers. Il faut exécuter `manage.py check`, `migrate`, `flutter analyze` et tester l'inscription, la connexion, la réservation et l'annulation sur votre machine avant de remplacer votre copie actuelle.
