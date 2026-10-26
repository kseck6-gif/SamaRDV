# SamaRDV
MVP académique de prise de rendez-vous médicaux : Django REST Framework + JWT + SQLite, et application Flutter.
Palette : bleu médical #1769AA, blanc #FFFFFF, bleu clair #DCEEFF.

## Backend (PowerShell)
Depuis le dossier SamaRDV :
```powershell
cd backend
Remove-Item -Recurse -Force .venv -ErrorAction SilentlyContinue
py -3.12 -m venv .venv
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
pip install -r requirements.txt
python manage.py migrate
python manage.py seed_demo
python manage.py runserver
```
Si l'activation est bloquée : `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass`, puis réactivez l'environnement.

Compte de démonstration :
- nom d'utilisateur : adama
- mot de passe : Password123!

API : http://127.0.0.1:8000/api/ — Admin : http://127.0.0.1:8000/admin/

## Flutter (dans un deuxième terminal)
```powershell
cd frontend\sama_rdv
flutter create .
flutter pub get
flutter run
```
Pour Android Emulator, l'API est configurée sur http://10.0.2.2:8000/api.
Pour Flutter Web/Windows, changez `baseUrl` dans `lib/config/api_config.dart` vers `http://127.0.0.1:8000/api`.

Fonctions : inscription/connexion JWT, recherche de médecins, réservation et annulation, liste des rendez-vous.
Les médecins/hôpitaux de démonstration sont fictifs. Ce MVP ne doit pas être utilisé pour des données médicales réelles sans audit de sécurité et de confidentialité.
