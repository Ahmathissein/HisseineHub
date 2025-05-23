import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/Projet.dart';

class CreerProjetScreen extends StatefulWidget {
  final Projet? projetExistant;

  const CreerProjetScreen({super.key, this.projetExistant});


  @override
  State<CreerProjetScreen> createState() => _CreerProjetScreenState();
}

class _CreerProjetScreenState extends State<CreerProjetScreen> {
  DateTime? dateDebut;
  DateTime? dateFin;
  final titreController = TextEditingController();
  final descriptionController = TextEditingController();
  final nouvelleTacheController = TextEditingController();
  List<String> taches = [];
  String priorite = 'Moyenne';
  bool _isLoading = false;
  bool estModification = false;


  final List<String> priorites = ['Haute', 'Moyenne', 'Basse'];

  @override
  void dispose() {
    titreController.dispose();
    descriptionController.dispose();
    nouvelleTacheController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    estModification = widget.projetExistant != null;

    if (estModification) {
      final projet = widget.projetExistant!;
      titreController.text = projet.nom;
      descriptionController.text = projet.description;
      priorite = projet.priorite[0].toUpperCase() + projet.priorite.substring(1).toLowerCase();
      taches = projet.taches.map((t) => t.nom).toList();
      dateDebut = projet.dateDebut;
      dateFin = projet.dateFin;
      if (!priorites.contains(priorite)) {
        debugPrint("⚠️ Priorité invalide détectée : $priorite");
      }

      // Tu peux ignorer les dates si elles ne sont pas utilisées dans Projet
    }
  }



  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.red[700],
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _enregistrerProjet() async {
    if (_isLoading) return;

    final titre = titreController.text.trim();
    final description = descriptionController.text.trim();
    final user = Supabase.instance.client.auth.currentUser;

    if (titre.isEmpty || titre.length < 3) {
      _showError("Le titre du projet est trop court.");
      return;
    }
    if (titre.length > 100) {
      _showError("Le titre est trop long (max 100 caractères).");
      return;
    }
    if (description.isEmpty || titre.length < 3) {
      _showError("La description du projet est trop courte.");
      return;
    }
    if (dateDebut == null || dateFin == null) {
      _showError("Veuillez sélectionner les deux dates.");
      return;
    }
    if (dateFin!.isBefore(dateDebut!)) {
      _showError("La date de fin ne peut pas être antérieure à la date de début.");
      return;
    }
    if (user == null) {
      _showError("Utilisateur non connecté.");
      return;
    }
    if (taches.any((t) => t.trim().isEmpty)) {
      _showError("Une tâche est vide.");
      return;
    }
    if (taches.isEmpty) {
      _showError("Ajoutez au moins une tâche au projet.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.rpc('create_projet_avec_taches', params: {
        'p_nom': titre,
        'p_description': description,
        'p_priorite': priorite.toLowerCase(),
        'p_user_id': user.id,
        'p_taches': taches.map((t) => {'nom': t, 'fait': false}).toList(),
        'p_date_debut': dateDebut!.toIso8601String(),
        'p_date_fin': dateFin!.toIso8601String(),
      });


      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Projet enregistré avec succès"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      _showError("Erreur lors de l'enregistrement : $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _modifierProjet() async {
    if (_isLoading || widget.projetExistant == null) return;

    final projet = widget.projetExistant!;
    final titre = titreController.text.trim();
    final description = descriptionController.text.trim();

    if (titre.isEmpty || titre.length < 3) {
      _showError("Le titre du projet est trop court.");
      return;
    }

    if (taches.any((t) => t.trim().isEmpty)) {
      _showError("Une tâche est vide.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client
          .from('projets')
          .update({
        'nom': titre,
        'description': description,
        'priorite': priorite.toLowerCase(),
      })
          .eq('id', projet.id);

      // ⚠️ Remplace toutes les anciennes tâches (si logique côté Supabase ok)
      await Supabase.instance.client
          .from('taches_projet')
          .delete()
          .eq('projet_id', projet.id);

      for (final nom in taches) {
        await Supabase.instance.client.from('taches_projet').insert({
          'projet_id': projet.id,
          'nom': nom,
          'fait': false,
        });
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Projet modifié avec succès"), backgroundColor: Colors.green),
      );
    } catch (e) {
      _showError("Erreur lors de la modification : $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.quicksand(
        fontWeight: FontWeight.bold,
        fontSize: 20,
        color: Colors.black,
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String hint, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      textAlignVertical: TextAlignVertical.top,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.quicksand(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF838FA2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      ),
    );
  }

  Widget _choisirDate(BuildContext context, bool isDebut) {
    final date = isDebut ? dateDebut : dateFin;
    final label = isDebut ? "Choisir la date de début" : "Choisir la date de fin";

    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? now,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          setState(() {
            if (isDebut) {
              dateDebut = picked;
              if (dateFin != null && dateFin!.isBefore(dateDebut!)) {
                dateFin = null;
              }
            } else {
              dateFin = picked;
            }
          });
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.calendar_today, color: Colors.deepPurple),
          hintText: label,
          hintStyle: GoogleFonts.quicksand(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF838FA2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
        child: Text(
          date != null ? "${date.day}/${date.month}/${date.year}" : "",
          style: GoogleFonts.quicksand(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: date != null ? Colors.black : const Color(0xFF838FA2),
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          estModification ? "Modifier le projet" : "Nouveau projet",
          style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.black),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.black),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("Titre du projet"),
            const SizedBox(height: 6),
            _buildInput(titreController, "Nom du projet"),

            const SizedBox(height: 16),
            _buildSectionTitle("Description"),
            const SizedBox(height: 6),
            _buildInput(descriptionController, "Description du projet", maxLines: 4),

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle("Date de début"),
                      const SizedBox(height: 6),
                      _choisirDate(context, true),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle("Date de fin"),
                      const SizedBox(height: 6),
                      _choisirDate(context, false),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSectionTitle("Priorité"),
            const SizedBox(height: 16),


            DropdownButtonFormField<String>(
              value: priorite,
              items: priorites.map((p) => DropdownMenuItem(value: p, child: Text(p, style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)))).toList(),
              onChanged: (val) => setState(() => priorite = val!),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              ),
            ),

            const SizedBox(height: 16),
            _buildSectionTitle("Tâches"),
            const SizedBox(height: 6),
            ...taches.map((tache) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(tache, style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
              trailing: IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: () => setState(() => taches.remove(tache)),
              ),
            )),

            TextField(
              controller: nouvelleTacheController,
              onSubmitted: (_) {
                final tache = nouvelleTacheController.text.trim();
                if (tache.isNotEmpty) {
                  setState(() {
                    taches.add(tache);
                    nouvelleTacheController.clear();
                  });
                }
              },
              decoration: InputDecoration(
                hintText: "Ajouter une tâche",
                hintStyle: GoogleFonts.quicksand(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF838FA2)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add, color: Colors.deepPurple),
                  onPressed: () {
                    final tache = nouvelleTacheController.text.trim();
                    if (tache.isNotEmpty) {
                      setState(() {
                        taches.add(tache);
                        nouvelleTacheController.clear();
                      });
                    }
                  },
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              ),
            ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    textStyle: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
                    side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: const Text("Annuler"),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : estModification
                      ? _modifierProjet
                      : _enregistrerProjet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA78BFA),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    textStyle: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(estModification ? "Enregistrer les modifications" : "Enregistrer"),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

}
