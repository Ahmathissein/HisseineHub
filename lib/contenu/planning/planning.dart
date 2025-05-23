import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../main.dart';
import '../../models/evenements.dart';
import '../../widgets/AppLayout.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';


class PlanningScreen extends StatefulWidget {
  const PlanningScreen({super.key});

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

Future<bool> enregistrerEvenement(Evenement event) async {
  try {
    await Supabase.instance.client.from('evenements').insert(event.toMap());
    debugPrint("✅ Événement enregistré !");
    return true;
  } catch (e) {
    debugPrint("❌ Erreur d’enregistrement : $e");
    return false;
  }
}





class _PlanningScreenState extends State<PlanningScreen> {
  int selectedTabIndex = 0; // 👈 maintenant géré par le State

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  List<Evenement> _evenementsDuJour = [];


  DateTime selectedDate = DateTime.now();
  TimeOfDay startTime = TimeOfDay.now();
  TimeOfDay endTime = TimeOfDay(
    hour: (TimeOfDay.now().hour + 1) % 24,
    minute: TimeOfDay.now().minute,
  );
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  final TextEditingController _titreController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _lieuController = TextEditingController();
  String _categorieSelectionnee = "Travail";

  Map<int, List<Evenement>> _evenementsSemaine = {}; // 0 = Lundi, ..., 6 = Dimanche

  Future<void> _chargerEvenementsSemaine() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final now = DateTime.now();
    final lundi = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    final dimanche = lundi.add(const Duration(days: 6));

    final response = await Supabase.instance.client
        .from('evenements')
        .select()
        .eq('user_id', userId)
        .gte('date', lundi.toIso8601String()) // ✅ PAS de format court
        .lte('date', dimanche.toIso8601String()); // ✅ pareil ici

    final data = (response as List)
        .map((e) => Evenement.fromMap(e))
        .toList();

    final Map<int, List<Evenement>> grouped = {};
    for (var e in data) {
      final int weekdayIndex = e.date.weekday - 1;
      grouped.putIfAbsent(weekdayIndex, () => []).add(e);
    }

    setState(() {
      _evenementsSemaine = grouped;
    });
  }

  Future<void> _chargerEvenementsPour(DateTime jour) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    final response = await Supabase.instance.client
        .from('evenements')
        .select()
        .eq('user_id', userId as Object)
        .eq('date', DateTime(jour.year, jour.month, jour.day));

    if (mounted) {
      setState(() {
        _evenementsDuJour = (response as List).map((e) => Evenement.fromMap(e)).toList();
      });
    }
  }

  List<Evenement> _evenementsAVenir = [];
  Future<void> _chargerEvenementsAVenir() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final now = DateTime.now();

    final response = await Supabase.instance.client
        .from('evenements')
        .select()
        .eq('user_id', userId)
        .gte('date', DateFormat('yyyy-MM-dd').format(now));

    final events = (response as List)
        .map((e) => Evenement.fromMap(e))
        .where((e) {
      final dateHeure = DateTime(
        e.date.year,
        e.date.month,
        e.date.day,
      );
      return dateHeure.isAfter(now) || dateHeure.isAtSameMomentAs(now);
    })
        .toList();

    // Trier par date puis heure
    events.sort((a, b) {
      final dateA = DateTime(a.date.year, a.date.month, a.date.day);
      final dateB = DateTime(b.date.year, b.date.month, b.date.day);
      final compDate = dateA.compareTo(dateB);
      if (compDate != 0) return compDate;

      // Comparer l'heure si les dates sont égales
      final format = DateFormat.Hm(); // "HH:mm"
      final timeA = format.parse(a.heureDebut);
      final timeB = format.parse(b.heureDebut);
      return timeA.compareTo(timeB);
    });

    setState(() {
      _evenementsAVenir = events.take(5).toList();
    });
  }


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateControllers(); // ✅ maintenant le context est prêt
      _chargerEvenementsPour(_selectedDay);
      _chargerEvenementsSemaine();
      _chargerEvenementsAVenir(); // 👈 Ajouté ici

    });
  }


  void _updateControllers() {
    _dateController.text = DateFormat('EEEE d MMMM y', 'fr_FR').format(selectedDate);
    _startTimeController.text = startTime.format(context);
    _endTimeController.text = endTime.format(context);
  }


  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 1300;


    return AppLayout(
      selectedItemLabel: "Planning",
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // ✅ important
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start, // important pour aligner verticalement le haut
                children: [
                  // Bloc titre à gauche
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Planning",
                            style: GoogleFonts.quicksand(
                              fontWeight: FontWeight.bold,
                              fontSize: 25,
                              color: Colors.black,
                            )),
                        const SizedBox(height: 4),
                        Text("Gérez votre emploi du temps et vos événements",
                            style: GoogleFonts.quicksand(
                              fontWeight: FontWeight.bold, // ✅ à ajouter
                              fontSize: 14,
                              color: const Color(0xFF838FA2),
                            )),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16), // petite marge entre les deux

                  // Bouton à droite
                  TextButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) {
                          final viewInsets = MediaQuery.of(context).viewInsets;
                          return MediaQuery.removeViewInsets(
                            context: context,
                            removeBottom: true,
                            child: Dialog(
                              insetPadding: const EdgeInsets.all(24),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width < 600 ? MediaQuery.of(context).size.width * 0.9 : 500,
                                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                                ),
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(24),
                                  child: IntrinsicHeight(
                                    child: _buildEventDialogContent(context), // 🔁 extrait dans une fonction à part
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );

                    },
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFA78BFA),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text("Nouvel événement"),
                  ),

                ],
              );
            },
          ),

          const SizedBox(height: 18),

          Align(
            alignment: Alignment.centerLeft,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12), // ✅ coins arrondis une seule fois
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9), // ✅ fond général
                  border: Border.all(color: Color(0xFFE2E8F0)), // ✅ bordure externe
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Calendrier
                    Material(
                      color: selectedTabIndex == 0 ? Colors.white : const Color(0xFFF1F5F9),
                      child: InkWell(
                        onTap: () => setState(() => selectedTabIndex = 0),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Text(
                            "Calendrier",
                            style: GoogleFonts.quicksand(
                              fontWeight: FontWeight.bold,
                              color: selectedTabIndex == 0 ? Colors.black : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // À venir
                    Material(
                      color: selectedTabIndex == 1 ? Colors.white : const Color(0xFFF1F5F9),
                      child: InkWell(
                        onTap: () => setState(() => selectedTabIndex = 1),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Text(
                            "À venir",
                            style: GoogleFonts.quicksand(
                              fontWeight: FontWeight.bold,
                              color: selectedTabIndex == 1 ? Colors.black : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),




          const SizedBox(height: 10),

          // ✅ Changer Flex par Wrap pour éviter la hauteur infinie
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 1300;
              final isMedium = constraints.maxWidth >= 960;

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                direction: Axis.horizontal,
                children: selectedTabIndex == 0
                    ? [
                  // 👉 Calendrier
                  SizedBox(
                    width: isWide
                        ? constraints.maxWidth * 0.33 - 8
                        : constraints.maxWidth,
                    child: _buildCalendarCard(),
                  ),

                  // 👉 Vue hebdomadaire
                  SizedBox(
                    width: isWide
                        ? constraints.maxWidth * 0.66 - 8
                        : constraints.maxWidth,
                    child: _buildWeekViewCard(),
                  ),
                ]
                    : [
                  // 👉 Aujourd'hui ou À venir
                  SizedBox(
                    width: constraints.maxWidth,
                    child:
                      _buildComingCard(),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    ),

    );
  }

  Widget _buildCalendarCard() {
    final today = _selectedDay;

    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0), // Bordure gris clair
          width: 1, // Épaisseur de la bordure
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),

          // 🔁 Calendrier intégré
          StatefulBuilder(
            builder: (context, setState) {
              return Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Color(0xFFE2E8F0), width: 1.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(8),
                child: TableCalendar(
                  locale: 'fr_FR',
                  rowHeight: 42,
                  focusedDay: _focusedDay,
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                    _chargerEvenementsPour(selectedDay);
                  },
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: GoogleFonts.quicksand(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    leftChevronIcon: const Icon(Icons.chevron_left),
                    rightChevronIcon: const Icon(Icons.chevron_right),
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: GoogleFonts.quicksand(fontWeight: FontWeight.bold, fontSize: 12),
                    weekendStyle: GoogleFonts.quicksand(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  calendarStyle: CalendarStyle(
                    defaultTextStyle: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
                    weekendTextStyle: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
                    todayTextStyle: GoogleFonts.quicksand(fontWeight: FontWeight.bold, color: Colors.white),
                    selectedTextStyle: GoogleFonts.quicksand(fontWeight: FontWeight.bold, color: Colors.white),
                    selectedDecoration: const BoxDecoration(
                      color: Color(0xFFA78BFA),
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: const BoxDecoration(
                      color: Color(0xFFD1C4E9),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.event_note, size: 18, color: Colors.deepPurple),
              const SizedBox(width: 8),
              Text(
                DateFormat('EEEE d MMMM y', 'fr_FR').format(today),
                style: GoogleFonts.quicksand(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

// ✅ Affichage conditionnel ligne suivante
          if (_evenementsDuJour.isEmpty)
            Text(
              "Aucun événement ce jour",
              style: GoogleFonts.quicksand(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF838FA2),
              ),
            )
          else
            Column(
              children: _evenementsDuJour.map((event) => Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF), // violet très pâle
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFD1C4E9)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.titre,
                      style: GoogleFonts.quicksand(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black, // ✅ noir
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.schedule, size: 16, color: Colors.grey), // ⏱️ icône grise
                        const SizedBox(width: 6),
                        Text(
                          "${event.heureDebut} - ${event.heureFin}",
                          style: GoogleFonts.quicksand(
                            fontSize: 13,
                            color: Colors.black, // ✅ horaire en noir
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.lieu,
                      style: GoogleFonts.quicksand(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.black, // ✅ noir
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildWeekViewCard() {
    final days = ["Lun", "Mar", "Mer", "Jeu", "Ven", "Sam", "Dim"];

    if (_evenementsSemaine.values.every((list) => list.isEmpty)) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          "📭 Aucun événement enregistré cette semaine.",
          style: GoogleFonts.quicksand(fontSize: 14, color: Colors.grey),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0), // Bordure gris clair
          width: 1, // Épaisseur de la bordure
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Vue hebdomadaire",
              style: GoogleFonts.quicksand(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              )),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(7, (index) {
                final events = _evenementsSemaine[index] ?? [];

                return Container(
                  width: 140,
                  height: 300, // 🟢 Limite la hauteur de chaque colonne (scrollable)
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FBFC),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        days[index],
                        style: GoogleFonts.quicksand(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          itemCount: events.length,
                          itemBuilder: (context, i) {
                            final event = events[i];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F3FF),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${event.heureDebut} - ${event.heureFin}",
                                    style: GoogleFonts.quicksand(
                                      fontSize: 12,
                                      color: Colors.black, // ✅ noir
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    event.titre,
                                    style: GoogleFonts.quicksand(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Colors.black, // ✅ noir
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComingCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white, // ✅ Fond blanc pour le conteneur principal
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)), // ✅ Bordure grise
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Événements à venir",
            style: GoogleFonts.quicksand(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          if (_evenementsAVenir.isEmpty)
            Text(
              "Aucun événement à venir",
              style: GoogleFonts.quicksand(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF838FA2),
              ),
            )
          else
            Column(
              children: _evenementsAVenir.map((event) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🔁 Titre + date en ligne
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            event.titre,
                            style: GoogleFonts.quicksand(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3E8FF), // Badge violet clair
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              DateFormat('d MMM', 'fr_FR').format(event.date),
                              style: GoogleFonts.quicksand(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF7E22CE), // Violet foncé
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.description,
                        style: GoogleFonts.quicksand(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.schedule, size: 16, color: Colors.grey),
                              const SizedBox(width: 6),
                              Text(
                                "${event.heureDebut} - ${event.heureFin}",
                                style: GoogleFonts.quicksand(
                                  fontSize: 13,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                          Text(
                            event.lieu,
                            style: GoogleFonts.quicksand(
                              fontSize: 13,
                              color: const Color(0xFF1D4ED8), // 🟦 Bleu foncé
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildToggleBar(Function(int) onChanged, int selectedIndex) {
    return Container(
      margin: const EdgeInsets.only(left: 8, right: 8, bottom: 16),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0), // Bordure gris clair
          width: 1, // Épaisseur de la bordure
        ),
      ),
      child: ToggleButtons(
        isSelected: [0, 1].map((i) => i == selectedIndex).toList(),
        onPressed: onChanged,
        borderRadius: BorderRadius.circular(8),
        selectedColor: Colors.deepPurple,
        color: Colors.black,
        fillColor: Colors.white,
        textStyle: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
        children: const [
          Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text("Calendrier")),
          Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text("À venir")),
        ],
      ),
    );
  }

  Widget _buildEventDialogContent(BuildContext context) {
    final violet = const Color(0xFFA78BFA);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Nouvel événement",
              style: GoogleFonts.quicksand(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Titre
        Text("Titre", style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        TextField(
          controller: _titreController, // ✅ important
          style: GoogleFonts.quicksand(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF838FA2),
          ),
          decoration: _decoration("Titre de l'événement"),
        ),

        const SizedBox(height: 16),
        // Description
        Text("Description", style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        TextField(
          controller: _descriptionController, // ✅ important
          style: GoogleFonts.quicksand(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF838FA2),
          ),
          decoration: _decoration("Description de l'événement"),
        ),

        const SizedBox(height: 16),
        // Date
        Text("Date", style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () async {
            DateTime? picked = await showDatePicker(
              context: context,
              initialDate: selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
              locale: const Locale('fr', 'FR'),
            );
            if (picked != null) {
              setState(() {
                selectedDate = picked;
                _updateControllers();
              });
            }
          },
          child: AbsorbPointer(
            child: TextField(
              controller: _dateController,
              readOnly: true,
              decoration: _decoration("", icon: Icons.calendar_today),
              style: GoogleFonts.quicksand(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF838FA2),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Catégorie
        Text("Catégorie", style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: "Travail",
          style: GoogleFonts.quicksand(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF838FA2),
          ),
          items: ["Travail", "Personnel", "Autre"]
              .map((label) => DropdownMenuItem(
            value: label,
            child: Text(label, style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
          ))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _categorieSelectionnee = value;
              });
            }
          },

          decoration: _decoration(""),
        ),
        const SizedBox(height: 16),
        // Heure de début
        Text("Heure de début", style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () async {
            TimeOfDay? picked = await showTimePicker(
              context: context,
              initialTime: startTime,
            );
            if (picked != null) {
              setState(() {
                startTime = picked;
                _updateControllers();
              });
            }
          },
          child: AbsorbPointer(
            child: TextField(
              controller: _startTimeController,
              readOnly: true,
              decoration: _decoration("", icon: Icons.access_time),
              style: GoogleFonts.quicksand(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF838FA2),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Heure de fin
        Text("Heure de fin", style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () async {
            TimeOfDay? picked = await showTimePicker(
              context: context,
              initialTime: endTime,
            );
            if (picked != null) {
              setState(() {
                endTime = picked;
                _updateControllers();
              });
            }
          },
          child: AbsorbPointer(
            child: TextField(
              controller: _endTimeController,
              readOnly: true,
              decoration: _decoration("", icon: Icons.access_time_outlined),
              style: GoogleFonts.quicksand(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF838FA2),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Lieu
        Text("Lieu", style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        TextField(
          controller: _lieuController, // ✅ important
          style: GoogleFonts.quicksand(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF838FA2),
          ),
          decoration: _decoration("Lieu de l'événement"),
        ),

        const SizedBox(height: 24),
        // Boutons
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Annuler", style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
                onPressed: () async {
                  final userId = Supabase.instance.client.auth.currentUser?.id;

                  if (userId != null) {
                  final nouvelEvenement = Evenement(
                  id: Uuid().v4(),
                  userId: userId,
                  titre: _titreController.text,
                  description: _descriptionController.text,
                  categorie: _categorieSelectionnee,
                  lieu: _lieuController.text,
                  date: selectedDate,
                  heureDebut: startTime.format(context),
                  heureFin: endTime.format(context),
                  );

                  final success = await enregistrerEvenement(nouvelEvenement);
                  if (success) {
                    Navigator.pop(context);
                    await _chargerEvenementsSemaine(); // 🔁 ici
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✅ Événement enregistré avec succès !'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }

                  }
                },
                style: ElevatedButton.styleFrom(
                backgroundColor: violet,
                foregroundColor: Colors.white,
                textStyle: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
              ),
              child: const Text("Enregistrer"),
            ),
          ],
        ),
      ],
    );
  }

}

  InputDecoration _decoration(String hint, {IconData? icon}) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.quicksand(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: Colors.grey,
    ),
    filled: true,
    fillColor: const Color(0xFFFCFAFF),
    prefixIcon: icon != null
        ? Icon(icon, color: Color(0xFFA78BFA), size: 20)
        : null,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFDDD6F3), width: 1.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFA78BFA), width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
  );
