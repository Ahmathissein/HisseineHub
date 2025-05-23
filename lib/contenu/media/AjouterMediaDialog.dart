import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> showAjouterMediaDialog(BuildContext context) async {
  String titre = '';
  String type = 'Livre';
  String avis = '';
  String statut = '';
  int note = 3;

  final types = ['Livre', 'Film', 'Série'];

  List<String> getStatuts(String selectedType) {
    switch (selectedType.toLowerCase()) {
      case 'film':
      case 'série':
        return ['À voir', 'En cours de visionnage', 'Vu'];
      case 'livre':
      default:
        return ['À lire', 'Lecture en cours', 'Lu'];
    }
  }

  String selectedStatut = getStatuts(type)[0];

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        minChildSize: 0.6,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return StatefulBuilder(
            builder: (context, setState) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFFFCFAFF),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Ajouter un média",
                          style: GoogleFonts.quicksand(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          )),
                      const SizedBox(height: 24),

                      TextField(
                        decoration: _inputDecoration("Titre", hint: "Entrez le titre"),
                        style: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
                        onChanged: (val) => titre = val,
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        value: type,
                        decoration: _inputDecoration("Type"),
                        style: GoogleFonts.quicksand(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        dropdownColor: Colors.white,
                        items: types
                            .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(
                            t,
                            style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                        ))
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            type = val!;
                            selectedStatut = getStatuts(type)[0];
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        value: selectedStatut,
                        decoration: _inputDecoration("Statut"),
                        style: GoogleFonts.quicksand(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        dropdownColor: Colors.white,
                        items: getStatuts(type)
                            .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(
                            s,
                            style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                        ))
                            .toList(),
                        onChanged: (val) => setState(() => selectedStatut = val!),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        maxLines: 4,
                        decoration: _inputDecoration("Description / Avis", hint: "Votre avis ou une description"),
                        style: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
                        onChanged: (val) => avis = val,
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<int>(
                        value: note,
                        decoration: _inputDecoration("Note"),
                        style: GoogleFonts.quicksand(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        dropdownColor: Colors.white,
                        items: List.generate(
                          6,
                              (i) => DropdownMenuItem(
                            value: i,
                            child: Text('$i ${i == 1 ? "étoile" : "étoiles"}',
                                style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, color: Colors.black)),
                          ),
                        ),
                        onChanged: (val) => setState(() => note = val!),
                      ),

                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text("Annuler", style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFA78BFA),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              textStyle: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
                            ),
                            child: const Text("Enregistrer"),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    },
  );
}

InputDecoration _inputDecoration(String label, {String? hint}) {
  return InputDecoration(
    labelText: label,
    hintText: hint ?? '',
    labelStyle: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
    hintStyle: GoogleFonts.quicksand(fontWeight: FontWeight.normal, color: Colors.grey),
    filled: true,
    fillColor: const Color(0xFFF4F4FA),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFDDD6FE), width: 1.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFA78BFA), width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}
