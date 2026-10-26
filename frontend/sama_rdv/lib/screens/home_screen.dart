import 'package:flutter/material.dart';

import '../services/api_service.dart';

// ============================================================

// ÉCRAN D'ACCUEIL

// ============================================================

class HomeScreen extends StatefulWidget {

  const HomeScreen({super.key});

  @override

  State<HomeScreen> createState() => _HomeScreenState();

}

class _HomeScreenState extends State<HomeScreen> {

  List<dynamic> doctors = [];

  bool loading = true;

  bool logged = false;

  String? error;

  String search = '';

  @override

  void initState() {

    super.initState();

    load();

    check();

  }

  Future<void> check() async {

    final token = await ApiService.token;

    if (!mounted) return;

    setState(() {

      logged = token != null;

    });

  }

  Future<void> load() async {

    if (mounted) {

      setState(() {

        loading = true;

        error = null;

      });

    }

    try {

      final result = await ApiService.doctors(search: search);

      if (!mounted) return;

      setState(() {

        doctors = result;

      });

    } catch (e) {

      if (!mounted) return;

      setState(() {

        error = e.toString();

      });

    } finally {

      if (mounted) {

        setState(() {

          loading = false;

        });

      }

    }

  }

  Future<void> auth() async {

    await Navigator.push(

      context,

      MaterialPageRoute(

        builder: (_) => const AuthScreen(),

      ),

    );

    await check();

  }

  Future<void> _booking(dynamic doctor) async {

    if (!logged) {

      await auth();

      if (!logged) return;

    }

    if (!mounted) return;

    await Navigator.push(

      context,

      MaterialPageRoute(

        builder: (_) => BookingScreen(doctor: doctor),

      ),

    );

    await load();

  }

  @override

  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        title: Row(
          children: [
            Image.asset('assets/images/samardv_logo.png', width: 38, height: 38, fit: BoxFit.contain),
            const SizedBox(width: 8),
            const Text('SamaRDV'),
          ],
        ),

        actions: [

          IconButton(

            tooltip: logged ? 'Déconnexion' : 'Connexion',

            icon: Icon(logged ? Icons.logout : Icons.login),

            onPressed: () async {

              if (logged) {

                await ApiService.logout();

                if (!mounted) return;

                setState(() {

                  logged = false;

                });

              } else {

                await auth();

              }

            },

          ),

          IconButton(

            tooltip: 'Mon profil',

            icon: const Icon(Icons.account_circle_outlined),

            onPressed: () async {

              if (!logged) {

                await auth();

                if (!logged) return;

              }

              if (!mounted) return;

              await Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientProfileScreen()));

            },

          ),

          IconButton(

            tooltip: 'Mes rendez-vous',

            icon: const Icon(Icons.calendar_month),

            onPressed: () async {

              if (!logged) {

                await auth();

                if (!logged) return;

              }

              if (!mounted) return;

              await Navigator.push(

                context,

                MaterialPageRoute(

                  builder: (_) => const AppointmentsScreen(),

                ),

              );

            },

          ),

        ],

      ),

      body: RefreshIndicator(

        onRefresh: load,

        child: ListView(

          padding: const EdgeInsets.all(16),

          children: [

            Container(

              padding: const EdgeInsets.all(22),

              decoration: BoxDecoration(

                gradient: const LinearGradient(

                  colors: [Color(0xFFEAF4FF), Color(0xFFDCEEFF)],

                  begin: Alignment.topLeft,

                  end: Alignment.bottomRight,

                ),

                borderRadius: BorderRadius.circular(26),

                border: Border.all(color: const Color(0xFFD3E8FC)),

              ),

              child: Row(

                children: [

                  Expanded(

                    child: Column(

                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [

                        Container(

                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),

                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),

                          child: const Text('VOTRE SANTÉ, SIMPLIFIÉE',

                            style: TextStyle(color: Color(0xFF1769AA), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: .7)),

                        ),

                        const SizedBox(height: 14),

                        const Text(

                          'Prenez soin de vous, en quelques clics.',

                          style: TextStyle(fontSize: 23, height: 1.18, fontWeight: FontWeight.w800, color: Color(0xFF124E80)),

                        ),

                        const SizedBox(height: 10),

                        const Text(

                          'Trouvez un médecin et réservez votre rendez-vous simplement.',

                          style: TextStyle(fontSize: 13, height: 1.45, color: Color(0xFF365C7D)),

                        ),

                        const SizedBox(height: 16),

                        FilledButton.icon(

                          onPressed: () => FocusScope.of(context).unfocus(),

                          icon: const Icon(Icons.search, size: 18),

                          label: const Text('Trouver un médecin'),

                        ),

                      ],

                    ),

                  ),

                  const SizedBox(width: 6),

                  Image.asset('assets/images/samardv_logo.png', width: 88, height: 112, fit: BoxFit.contain),

                ],

              ),

            ),

            const SizedBox(height: 16),

            TextField(

              decoration: const InputDecoration(

                prefixIcon: Icon(Icons.search, color: Color(0xFF1769AA)),

                hintText: 'Rechercher un médecin, une spécialité...',

                suffixIcon: Icon(Icons.tune, color: Color(0xFF1769AA)),

              ),

              onChanged: (value) {

                search = value;

              },

              onSubmitted: (_) => load(),

            ),

            const SizedBox(height: 18),

            const Text(

              'Professionnels de santé',

              style: TextStyle(

                fontSize: 20,

                fontWeight: FontWeight.bold,

              ),

            ),

            const SizedBox(height: 8),

            if (loading)

              const Center(

                child: Padding(

                  padding: EdgeInsets.all(20),

                  child: CircularProgressIndicator(),

                ),

              ),

            if (error != null)

              Padding(

                padding: const EdgeInsets.symmetric(vertical: 12),

                child: Text(

                  'Erreur : $error\n'

                  'Vérifiez que le serveur Django est démarré.',

                  style: const TextStyle(color: Colors.red),

                ),

              ),

            if (!loading && error == null && doctors.isEmpty)

              const Padding(

                padding: EdgeInsets.all(20),

                child: Center(

                  child: Text('Aucun professionnel trouvé.'),

                ),

              ),

            ...doctors.map((doctor) {

              final photo = doctor['photo_url']?.toString() ?? '';

              return Card(

                clipBehavior: Clip.antiAlias,

                margin: const EdgeInsets.only(bottom: 13),

                child: InkWell(

                  onTap: () => _booking(doctor),

                  child: Padding(

                    padding: const EdgeInsets.all(13),

                    child: Row(

                      children: [

                        ClipRRect(

                          borderRadius: BorderRadius.circular(16),

                          child: SizedBox(

                            width: 82,

                            height: 92,

                            child: photo.isNotEmpty

                                ? Image.network(photo, fit: BoxFit.cover,

                                    errorBuilder: (_, __, ___) => _doctorPlaceholder())

                                : _doctorPlaceholder(),

                          ),

                        ),

                        const SizedBox(width: 14),

                        Expanded(

                          child: Column(

                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [

                              Text(doctor['full_name']?.toString() ?? 'Médecin',

                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF18364F))),

                              const SizedBox(height: 5),

                              Text(doctor['specialty']?.toString() ?? 'Spécialité non précisée',

                                style: const TextStyle(color: Color(0xFF1769AA), fontWeight: FontWeight.w600)),

                              const SizedBox(height: 7),

                              Row(

                                children: [

                                  const Icon(Icons.location_on_outlined, size: 15, color: Color(0xFF6B8194)),

                                  const SizedBox(width: 3),

                                  Expanded(child: Text(doctor['hospital_name']?.toString() ?? 'Établissement non précisé',

                                    maxLines: 2, overflow: TextOverflow.ellipsis,

                                    style: const TextStyle(fontSize: 12, color: Color(0xFF6B8194)))),

                                ],

                              ),

                              const SizedBox(height: 10),

                              const Text('Voir le profil  ›',

                                style: TextStyle(color: Color(0xFF1769AA), fontWeight: FontWeight.w800, fontSize: 12)),

                            ],

                          ),

                        ),

                      ],

                    ),

                  ),

                ),

              );

            }),

          ],

        ),

      ),

    );

  }

  Widget _doctorPlaceholder() {

    return Container(

      color: const Color(0xFFDCEEFF),

      alignment: Alignment.center,

      child: const Icon(Icons.medical_services_rounded, size: 36, color: Color(0xFF1769AA)),

    );

  }

}

// ============================================================

// PROFIL PATIENT : photo facultative via URL

// ============================================================

class PatientProfileScreen extends StatefulWidget {

  const PatientProfileScreen({super.key});

  @override

  State<PatientProfileScreen> createState() => _PatientProfileScreenState();

}

class _PatientProfileScreenState extends State<PatientProfileScreen> {

  final photoController = TextEditingController();

  bool loading = true;

  bool saving = false;

  String? error;

  Map<String, dynamic> profile = {};

  @override

  void initState() {

    super.initState();

    loadProfile();

  }

  Future<void> loadProfile() async {

    try {

      final result = await ApiService.profile();

      if (!mounted) return;

      setState(() {

        profile = result;

        photoController.text = result['photo_url']?.toString() ?? '';

        loading = false;

      });

    } catch (e) {

      if (!mounted) return;

      setState(() { error = e.toString(); loading = false; });

    }

  }

  Future<void> savePhoto() async {

    setState(() { saving = true; error = null; });

    try {

      await ApiService.updateProfilePhoto(photoController.text.trim());

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo de profil mise à jour.')));

    } catch (e) {

      if (!mounted) return;

      setState(() => error = e.toString());

    } finally {

      if (mounted) setState(() => saving = false);

    }

  }

  @override

  void dispose() {

    photoController.dispose();

    super.dispose();

  }

  @override

  Widget build(BuildContext context) {

    final photo = photoController.text.trim();

    final fullName = '${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}'.trim();

    return Scaffold(

      appBar: AppBar(title: const Text('Mon profil')),

      body: loading

          ? const Center(child: CircularProgressIndicator())

          : ListView(

              padding: const EdgeInsets.all(22),

              children: [

                Center(

                  child: CircleAvatar(

                    radius: 54,

                    backgroundColor: const Color(0xFFDCEEFF),

                    backgroundImage: photo.startsWith('http') ? NetworkImage(photo) : null,

                    child: !photo.startsWith('http') ? const Icon(Icons.person_rounded, size: 52, color: Color(0xFF1769AA)) : null,

                  ),

                ),

                const SizedBox(height: 16),

                Center(child: Text(fullName.isEmpty ? (profile['username'] ?? 'Patient').toString() : fullName,

                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),

                const SizedBox(height: 6),

                Center(child: Text(profile['email']?.toString() ?? '', style: const TextStyle(color: Colors.blueGrey))),

                const SizedBox(height: 28),

                const Text('Photo de profil', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),

                const SizedBox(height: 8),

                const Text('Collez le lien d’une image accessible en ligne. Vous pouvez laisser ce champ vide pour utiliser l’avatar par défaut.',

                  style: TextStyle(color: Colors.blueGrey, height: 1.4)),

                const SizedBox(height: 14),

                TextField(

                  controller: photoController,

                  keyboardType: TextInputType.url,

                  decoration: const InputDecoration(labelText: 'Lien de la photo (URL)', prefixIcon: Icon(Icons.image_outlined)),

                  onChanged: (_) => setState(() {}),

                ),

                if (error != null) ...[

                  const SizedBox(height: 12),

                  Text(error!, style: const TextStyle(color: Colors.red)),

                ],

                const SizedBox(height: 18),

                FilledButton.icon(

                  onPressed: saving ? null : savePhoto,

                  icon: const Icon(Icons.save_outlined),

                  label: Text(saving ? 'Enregistrement...' : 'Enregistrer la photo'),

                ),

              ],

            ),

    );

  }

}

// ============================================================

// CONNEXION ET INSCRIPTION

// ============================================================

class AuthScreen extends StatefulWidget {

  const AuthScreen({super.key});

  @override

  State<AuthScreen> createState() => _AuthScreenState();

}

class _AuthScreenState extends State<AuthScreen> {

  final usernameController = TextEditingController();

  final passwordController = TextEditingController();

  final firstNameController = TextEditingController();

  final lastNameController = TextEditingController();

  final emailController = TextEditingController();

  bool registerMode = false;

  bool busy = false;

  String? error;

  Future<void> submit() async {

    setState(() {

      busy = true;

      error = null;

    });

    try {

      if (registerMode) {

        await ApiService.register(

          usernameController.text.trim(),

          firstNameController.text.trim(),

          lastNameController.text.trim(),

          emailController.text.trim(),

          passwordController.text,

        );

      }

      await ApiService.login(

        usernameController.text.trim(),

        passwordController.text,

      );

      if (!mounted) return;

      Navigator.pop(context);

    } catch (e) {

      if (!mounted) return;

      setState(() {

        error = e.toString();

      });

    } finally {

      if (mounted) {

        setState(() {

          busy = false;

        });

      }

    }

  }

  @override

  void dispose() {

    usernameController.dispose();

    passwordController.dispose();

    firstNameController.dispose();

    lastNameController.dispose();

    emailController.dispose();

    super.dispose();

  }

  @override

  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        title: Text(registerMode ? 'Inscription' : 'Connexion'),

      ),

      body: ListView(

        padding: const EdgeInsets.all(20),

        children: [

          const Icon(

            Icons.health_and_safety,

            size: 60,

            color: Color(0xFF1769AA),

          ),

          const SizedBox(height: 20),

          if (registerMode)

            TextField(

              controller: firstNameController,

              decoration: const InputDecoration(

                labelText: 'Prénom',

                border: OutlineInputBorder(),

              ),

            ),

          if (registerMode) const SizedBox(height: 12),

          if (registerMode)

            TextField(

              controller: lastNameController,

              decoration: const InputDecoration(

                labelText: 'Nom',

                border: OutlineInputBorder(),

              ),

            ),

          if (registerMode) const SizedBox(height: 12),

          if (registerMode)

            TextField(

              controller: emailController,

              keyboardType: TextInputType.emailAddress,

              decoration: const InputDecoration(

                labelText: 'E-mail',

                border: OutlineInputBorder(),

              ),

            ),

          if (registerMode) const SizedBox(height: 12),

          TextField(

            controller: usernameController,

            decoration: const InputDecoration(

              labelText: 'Nom d’utilisateur',

              border: OutlineInputBorder(),

            ),

          ),

          const SizedBox(height: 12),

          TextField(

            controller: passwordController,

            obscureText: true,

            decoration: const InputDecoration(

              labelText: 'Mot de passe (8 caractères minimum)',

              border: OutlineInputBorder(),

            ),

          ),

          if (error != null) ...[

            const SizedBox(height: 12),

            Text(

              error!,

              style: const TextStyle(color: Colors.red),

            ),

          ],

          const SizedBox(height: 20),

          FilledButton(

            onPressed: busy ? null : submit,

            child: Text(

              busy

                  ? 'Patientez...'

                  : registerMode

                      ? 'Créer mon compte'

                      : 'Se connecter',

            ),

          ),

          TextButton(

            onPressed: busy

                ? null

                : () {

                    setState(() {

                      registerMode = !registerMode;

                      error = null;

                    });

                  },

            child: Text(

              registerMode

                  ? 'J’ai déjà un compte'

                  : 'Créer un compte',

            ),

          ),

        ],

      ),

    );

  }

}

// ============================================================

// PRISE DE RENDEZ-VOUS

// ============================================================

class BookingScreen extends StatefulWidget {

  final dynamic doctor;

  const BookingScreen({

    super.key,

    required this.doctor,

  });

  @override

  State<BookingScreen> createState() => _BookingScreenState();

}

class _BookingScreenState extends State<BookingScreen> {

  late DateTime date;

  TimeOfDay time = const TimeOfDay(hour: 9, minute: 0);

  int? selectedHospital;

  final reasonController = TextEditingController();

  String? error;

  bool saving = false;

  @override

  void initState() {

    super.initState();

    date = DateTime.now().add(const Duration(days: 1));
    selectedHospital = int.tryParse(widget.doctor['hospital']?.toString() ?? '');

  }

  String get dateText {

    return '${date.year.toString().padLeft(4, '0')}-'

        '${date.month.toString().padLeft(2, '0')}-'

        '${date.day.toString().padLeft(2, '0')}';

  }

  Future<void> save() async {

    setState(() {

      saving = true;

      error = null;

    });

    try {

      final timeText =

          '${time.hour.toString().padLeft(2, '0')}:'

          '${time.minute.toString().padLeft(2, '0')}:00';

      await ApiService.book(

        widget.doctor['id'],

        dateText,

        timeText,

        reasonController.text.trim(),

        hospital: selectedHospital,

      );

      if (!mounted) return;

      Navigator.pop(context);

    } catch (e) {

      if (!mounted) return;

      setState(() {

        error = e.toString();

      });

    } finally {

      if (mounted) {

        setState(() {

          saving = false;

        });

      }

    }

  }

  @override

  void dispose() {

    reasonController.dispose();

    super.dispose();

  }

  @override

  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        title: const Text('Prendre rendez-vous'),

      ),

      body: ListView(

        padding: const EdgeInsets.all(20),

        children: [

          Text(

            widget.doctor['full_name']?.toString() ?? 'Médecin',

            style: const TextStyle(

              fontSize: 22,

              fontWeight: FontWeight.bold,

            ),

          ),

          const SizedBox(height: 4),

          Text(

            widget.doctor['specialty']?.toString() ?? '',

            style: const TextStyle(

              color: Color(0xFF1769AA),

            ),

          ),

          const SizedBox(height: 16),

          if ((widget.doctor['additional_hospitals'] as List? ?? []).isNotEmpty) ...[

            const Text('Établissement de consultation', style: TextStyle(fontWeight: FontWeight.w700)),

            const SizedBox(height: 8),

            DropdownButtonFormField<int>(

              value: selectedHospital,

              decoration: const InputDecoration(prefixIcon: Icon(Icons.local_hospital_outlined)),

              items: [

                DropdownMenuItem<int>(

                  value: int.tryParse(widget.doctor['hospital']?.toString() ?? ''),

                  child: Text(widget.doctor['hospital_name']?.toString() ?? 'Hôpital principal'),

                ),

                ...((widget.doctor['additional_hospitals'] as List).map((h) =>

                  DropdownMenuItem<int>(

                    value: int.tryParse(h['id'].toString()),

                    child: Text(h['name']?.toString() ?? 'Hôpital'),

                  ))),

              ],

              onChanged: (value) => setState(() => selectedHospital = value),

            ),

            const SizedBox(height: 12),

          ],

          ListTile(

            leading: const Icon(Icons.calendar_month),

            title: const Text('Date'),

            subtitle: Text(dateText),

            onTap: () async {

              final selectedDate = await showDatePicker(

                context: context,

                initialDate: date,

                firstDate: DateTime.now(),

                lastDate: DateTime.now().add(

                  const Duration(days: 365),

                ),

              );

              if (selectedDate != null && mounted) {

                setState(() {

                  date = selectedDate;

                });

              }

            },

          ),

          ListTile(

            leading: const Icon(Icons.access_time),

            title: const Text('Heure'),

            subtitle: Text(time.format(context)),

            onTap: () async {

              final selectedTime = await showTimePicker(

                context: context,

                initialTime: time,

              );

              if (selectedTime != null && mounted) {

                setState(() {

                  time = selectedTime;

                });

              }

            },

          ),

          const SizedBox(height: 12),

          TextField(

            controller: reasonController,

            maxLines: 3,

            decoration: const InputDecoration(

              labelText: 'Motif (facultatif)',

              border: OutlineInputBorder(),

            ),

          ),

          if (error != null) ...[

            const SizedBox(height: 12),

            Text(

              error!,

              style: const TextStyle(color: Colors.red),

            ),

          ],

          const SizedBox(height: 20),

          FilledButton(

            onPressed: saving ? null : save,

            child: Text(

              saving

                  ? 'Enregistrement...'

                  : 'Confirmer le rendez-vous',

            ),

          ),

        ],

      ),

    );

  }

}

// ============================================================

// LISTE DES RENDEZ-VOUS

// ============================================================

class AppointmentsScreen extends StatefulWidget {

  const AppointmentsScreen({super.key});

  @override

  State<AppointmentsScreen> createState() =>

      _AppointmentsScreenState();

}

class _AppointmentsScreenState extends State<AppointmentsScreen> {

  late Future<List<dynamic>> future;

  @override

  void initState() {

    super.initState();

    future = ApiService.appointments();

  }

  Future<void> cancelAppointment(dynamic appointment) async {

    try {

      await ApiService.cancel(appointment['id']);

      if (!mounted) return;

      setState(() {

        future = ApiService.appointments();

      });

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(

          content: Text('Rendez-vous annulé.'),

        ),

      );

    } catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(

          content: Text('Impossible d’annuler : $e'),

        ),

      );

    }

  }

  @override

  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        title: const Text('Mes rendez-vous'),

      ),

      body: FutureBuilder<List<dynamic>>(

        future: future,

        builder: (context, snapshot) {

          if (snapshot.connectionState != ConnectionState.done) {

            return const Center(

              child: CircularProgressIndicator(),

            );

          }

          if (snapshot.hasError) {

            return Center(

              child: Padding(

                padding: const EdgeInsets.all(16),

                child: Text('Erreur : ${snapshot.error}'),

              ),

            );

          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {

            return const Center(

              child: Text('Aucun rendez-vous pour le moment.'),

            );

          }

          return ListView.builder(

            padding: const EdgeInsets.all(12),

            itemCount: items.length,

            itemBuilder: (context, index) {

              final appointment = items[index];

              final doctorName =

                  appointment['doctor_name']?.toString() ?? 'Médecin';

              final specialty =

                  appointment['specialty']?.toString() ?? '';

              final appointmentDate =

                  appointment['appointment_date']?.toString() ?? '';

              final appointmentTime =

                  appointment['appointment_time']?.toString() ?? '';

              final status =

                  appointment['status']?.toString() ?? 'inconnu';

              return Card(

                margin: const EdgeInsets.only(bottom: 12),

                child: ListTile(

                  leading: const CircleAvatar(

                    child: Icon(Icons.event),

                  ),

                  title: Text(doctorName),

                  subtitle: Text(

                    '$specialty\n'

                    '$appointmentDate à $appointmentTime\n'

                    'Statut : $status',

                  ),

                  isThreeLine: true,

                  trailing: status == 'booked'

                      ? IconButton(

                          tooltip: 'Annuler le rendez-vous',

                          icon: const Icon(

                            Icons.cancel,

                            color: Colors.red,

                          ),

                          onPressed: () =>

                              cancelAppointment(appointment),

                        )

                      : null,

                ),

              );

            },

          );

        },

      ),

    );

  }

}
