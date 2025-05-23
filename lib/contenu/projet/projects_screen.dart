import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/Projet.dart';
import 'NouveauProjetDialog.dart';
import 'ProjectDetailDialog.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  bool afficherTaches = false; // à ajouter dans Projet ou gérer via un Set dans ProjectsScreen
  String selectedStatus = 'Tous';
  final List<String> statuts = ['Tous', 'À faire', 'En cours', 'Terminés'];
  Set<String> projetsOuverts = {};

  List<Projet> projets = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProjets();
  }

  Future<void> _fetchProjets() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) return;

    try {
      final response = await supabase
          .from('projets')
          .select('*, taches_projet(*)')
          .eq('user_id', user.id);

      setState(() {
        projets = (response as List<dynamic>)
            .map((row) => Projet.fromJson(row as Map<String, dynamic>))
            .toList();
        isLoading = false;
      });

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur de chargement : $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _updateTache(Projet projet, TacheProjet tache, bool nouveauStatut) async {
    final supabase = Supabase.instance.client;

    try {
      // 🔁 Mise à jour Supabase
      await supabase
          .from('taches_projet')
          .update({'fait': nouveauStatut})
          .eq('projet_id', projet.id)
          .eq('nom', tache.nom);

      // ✅ Mise à jour locale pour que l’UI reflète la modification
      setState(() {
        tache.fait = nouveauStatut;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur lors de la mise à jour : $e'),
        backgroundColor: Colors.red,
      ));
    }
  }


  String _calculerStatut(Projet projet) {
    if (projet.taches.isEmpty) return 'À faire';
    final done = projet.taches.where((t) => t.fait).length;
    if (done == 0) return 'À faire';
    if (done == projet.taches.length) return 'Terminés';
    return 'En cours';
  }

  Widget _buildSection(List<Projet> projetsSection) {
    if (projetsSection.isEmpty) return const SizedBox.shrink();

    return Column(
      children: projetsSection.map((projet) {
        final progress = projet.taches.isEmpty
            ? 0.0
            : projet.taches.where((t) => t.fait).length / projet.taches.length;
        final statut = _calculerStatut(projet);
        return _buildProjectCard(projet, statut, progress);
      }).toList(),
    );
  }
  Color _getCouleurPriorite(String priorite) {
    switch (priorite.toLowerCase()) {
      case 'haute':
        return Colors.red;
      case 'moyenne':
        return const Color(0xFFEAB308); // jaune
      case 'basse':
      default:
        return const Color(0xFFA78BFA); // violet
    }
  }

  Color _getCouleurStatut(String statut) {
    switch (statut) {
      case 'Terminés':
        return Colors.green;
      case 'En cours':
        return const Color(0xFFEAB308); // jaune
      case 'À faire':
      default:
        return const Color(0xFFA78BFA); // violet
    }
  }

  IconData _getIconStatut(String statut) {
    switch (statut) {
      case 'Terminés':
        return Icons.check_circle_outline;
      case 'En cours':
        return Icons.trending_up_outlined;
      case 'À faire':
      default:
        return Icons.access_time_outlined;
    }
  }



  @override
  Widget build(BuildContext context) {

    final projetsFiltres = selectedStatus == 'Tous'
        ? projets
        : projets.where((p) => _calculerStatut(p) == selectedStatus).toList();

    // 🟦 Liste des projets
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F3FF),
        elevation: 0,
        title: const Text(
          "Projets personnels",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      body: Builder(
          builder: (context) {
            final isMobile = MediaQuery.of(context).size.width < 600;
            return Padding(
                padding: EdgeInsets.all(isMobile ? 10 : 16), // ✅ moins de marge sur mobile
              child: Column(
              children: [
            // 🟪 Sous-titre + bouton "Nouveau projet"
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "Gérez vos projets et tâches personnelles avec des statuts et des priorités.",
                    style: GoogleFonts.quicksand(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: const Color(0xFF838FA2),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CreerProjetScreen()),
                    ).then((_) {
                      // Appelle ici setState ou une méthode pour recharger les projets
                    });
                  },

                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("Nouveau projet"),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFA78BFA),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 🟨 Filtres
            Row(
              children: statuts.map((status) {
                final isSelected = selectedStatus == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        selectedStatus = status;
                      });
                    },
                    child: Text(status),
                    style: TextButton.styleFrom(
                      backgroundColor: isSelected ? Colors.white : const Color(0xFFF1F5F9),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),


            Expanded(
                child: isLoading
                ? const Center(child: CircularProgressIndicator())
                    : projetsFiltres.isEmpty
                ? Center(child: Text("Aucun projet", style: GoogleFonts.quicksand(color: Colors.grey)))
                    : ListView(
                children: selectedStatus == 'Tous'
                ? [
                _buildSection(projets.where((p) => _calculerStatut(p) == 'À faire').toList()),
                _buildSection(projets.where((p) => _calculerStatut(p) == 'En cours').toList()),
                _buildSection(projets.where((p) => _calculerStatut(p) == 'Terminés').toList()),
                ]
                    : [_buildSection(projetsFiltres)],
                )


                ),


            ],
        ),
      );
  }
      ),
    );
  }

  Widget _buildProjectCard(Projet projet, String statut, double progress) {
    final estOuvert = projetsOuverts.contains(projet.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔴 Priorité et statut
// 🔴 Priorité et statut
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 🎯 Priorité
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getCouleurPriorite(projet.priorite),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "Priorité ${projet.priorite}",
                  style: GoogleFonts.quicksand(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),

              // 📌 Statut
              Row(
                children: [
                  Icon(
                    _getIconStatut(statut),
                    size: 16,
                    color: _getCouleurStatut(statut),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    statut,
                    style: GoogleFonts.quicksand(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 🔹 Titre & Description
          Text(projet.nom, style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 6),
          Text(
            projet.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.quicksand(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF475569),
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 16),

          // 🟪 Progrès
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Progrès", style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, fontSize: 13)),
              Text("${(progress * 100).toStringAsFixed(0)}%", style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(0xFFF1F5F9),
              color: const Color(0xFFA78BFA),
            ),
          ),

          // 👇 Boutons & Liste des tâches
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    if (estOuvert) {
                      projetsOuverts.remove(projet.id);
                    } else {
                      projetsOuverts.add(projet.id);
                    }
                  });
                },
                child: Text(
                  estOuvert ? "Masquer les tâches" : "Voir les tâches",
                  style: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
                ),
              ),
              OutlinedButton(
                onPressed: () {
                  showProjectDetailDialog(context, projet);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
                ),
                child: const Text("Détails"),
              ),
            ],
          ),

          if (estOuvert) const SizedBox(height: 10),
          if (estOuvert)
            ...projet.taches.map(
                  (tache) => ListTile(
                onTap: () => _updateTache(projet, tache, !tache.fait),
                    dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: tache.fait ? Colors.deepPurple : Colors.grey,
                      width: 2,
                    ),
                    color: tache.fait ? Colors.deepPurple : Colors.white,
                  ),
                  child: tache.fait
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
                title: Text(
                  tache.nom,
                  style: GoogleFonts.quicksand(
                    fontWeight: FontWeight.bold,
                    color: tache.fait ? Colors.grey : Colors.black,
                    decoration: tache.fait ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
