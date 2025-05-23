import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/Projet.dart';

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/Projet.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'NouveauProjetDialog.dart';

Color _getCouleurPriorite(String priorite) {
  switch (priorite.toLowerCase()) {
    case 'haute':
      return Colors.red;
    case 'moyenne':
      return const Color(0xFFEAB308);
    case 'basse':
    default:
      return const Color(0xFFA78BFA);
  }
}

Color _getCouleurStatut(String statut) {
  switch (statut) {
    case 'Terminés':
      return Colors.green;
    case 'En cours':
      return const Color(0xFFEAB308);
    case 'À faire':
    default:
      return const Color(0xFFA78BFA);
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


Future<void> showProjectDetailDialog(BuildContext context, Projet projet) async {
  final isMobile = MediaQuery.of(context).size.width < 600;

  await showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.2),
    builder: (BuildContext context) {
      return StatefulBuilder(builder: (context, setState) {
        final total = projet.taches.length;
        final done = projet.taches.where((t) => t.fait).length;
        final progress = total == 0 ? 0.0 : done / total;
        final statut = total == 0
            ? 'À faire'
            : (done == total ? 'Terminés' : (done == 0 ? 'À faire' : 'En cours'));

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Center(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 40),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              constraints: const BoxConstraints(maxWidth: 500),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(projet.nom,
                              style: GoogleFonts.quicksand(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              )),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Priorité + statut
                    Row(
                      children: [
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
                        const SizedBox(width: 12),
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
                                fontSize: 12,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),
                    Text(projet.description,
                        style: GoogleFonts.quicksand(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.bold,
                        )),
                    const SizedBox(height: 12),

// 🟡 Dates
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: Colors.deepPurple),
                        const SizedBox(width: 6),
                        Text(
                          "Du ${projet.dateDebut?.day}/${projet.dateDebut?.month}/${projet.dateDebut?.year} "
                              "au ${projet.dateFin?.day}/${projet.dateFin?.month}/${projet.dateFin?.year}",
                          style: GoogleFonts.quicksand(
                            fontSize: 13,
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),


                    const SizedBox(height: 16),

                    // Progrès
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Progrès",
                            style: GoogleFonts.quicksand(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                        Text("${(progress * 100).toStringAsFixed(0)}%",
                            style: GoogleFonts.quicksand(
                                fontWeight: FontWeight.bold, fontSize: 13)),
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

                    const SizedBox(height: 20),

                    Text("Tâches ($total)",
                        style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),

                    const SizedBox(height: 8),

                    ...projet.taches.map((tache) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        onTap: () {
                          setState(() => tache.fait = !tache.fait);
                        },
                        leading: Icon(
                          tache.fait
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: tache.fait ? Colors.green : Colors.grey,
                          size: 20,
                        ),
                        title: Text(
                          tache.nom,
                          style: GoogleFonts.quicksand(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            decoration: tache.fait
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                    )),

                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // 🔴 Bouton Supprimer
                        ElevatedButton(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text("Confirmation"),
                                content: const Text("Voulez-vous supprimer ce projet définitivement ?"),
                                actions: [
                                    ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFA78BFA),
                                      foregroundColor: Colors.white,
                                      textStyle: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                                    ),
                                      child: const Text("Annuler"),
                                      onPressed: () => Navigator.pop(ctx, false),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      textStyle: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                                    ),
                                    child: const Text("Supprimer"),
                                    onPressed: () => Navigator.pop(ctx, true),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              try {
                                await Supabase.instance.client
                                    .from('projets')
                                    .delete()
                                    .eq('id', projet.id);
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Projet supprimé."), backgroundColor: Colors.red),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Erreur : $e"), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            textStyle: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                          ),
                          child: const Text("Supprimer"),
                        ),

                        const SizedBox(width: 8),

                        // 🟣 Bouton Modifier
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context); // Ferme d’abord la boîte de dialogue
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CreerProjetScreen(projetExistant: projet),
                              ),
                            );
                          },

                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFA78BFA),
                            foregroundColor: Colors.white,
                            textStyle: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                          ),
                          child: const Text("Modifier"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      });
    },
  );
}
