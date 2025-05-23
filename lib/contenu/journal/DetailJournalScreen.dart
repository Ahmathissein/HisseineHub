import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'creerNote.dart';
import 'custom_embed_builders.dart';

String toFormattedFr(DateTime date) {
  final formatter = DateFormat("EEEE d MMMM yyyy", "fr_FR");
  return formatter.format(date);
}


class DetailJournalScreen extends StatelessWidget {
  final Map<String, dynamic> journal;

  const DetailJournalScreen({super.key, required this.journal});

  @override
  Widget build(BuildContext context) {
    final titre = journal['titre'] ?? 'Sans titre';
    final contenu = journal['contenu'] ?? [];
    final document = quill.Document.fromJson(contenu);
    final dateCreation = journal['dateCreation'] is String
        ? DateTime.tryParse(journal['dateCreation'])
        : journal['dateCreation'] as DateTime?;

    final dateModification = journal['dateModification'] is String
        ? DateTime.tryParse(journal['dateModification'])
        : journal['dateModification'] as DateTime?;

    final version = journal['version'] ?? 1;
    final isShared = journal['isShared'] == true;
    final tags = (journal['tags'] ?? []) as List<dynamic>;

    return Scaffold(
        backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: Text(titre, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Center(
              child: Text(
                dateCreation != null
                    ? toFormattedFr(dateCreation)
                    : '',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 24),

            // Informations générales
// Informations générales + actions
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (dateCreation != null)
                  _InfoRow(Icons.calendar_today, "Date: ${DateFormat('dd MMM yyyy', 'fr_FR').format(dateCreation)}"),
                if (dateCreation != null)
                  _InfoRow(Icons.access_time, "Créé le ${DateFormat('dd/MM/yyyy à HH:mm').format(dateCreation)}"),
                if (dateModification != null)
                  _InfoRow(Icons.edit_calendar, "Dernière modification: ${DateFormat('dd/MM/yyyy à HH:mm').format(dateModification)}"),
                _InfoRow(Icons.numbers, "Version: $version"),
                if (isShared)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: _ChipInfo(Icons.share, "Partagé", Colors.indigo.shade100),
                  ),

                const SizedBox(height: 16),

                // 🔧 Boutons Modifier et Supprimer
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CreerNoteScreen(journalExistant: journal),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text("Modifier"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text("Confirmation"),
                            content: const Text("Voulez-vous supprimer cette note définitivement ?"),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Annuler")),
                              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Supprimer")),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await Supabase.instance.client
                              .from('journaux')
                              .delete()
                              .eq('id', journal['id']);
                          Navigator.pop(context);
                        }
                      },
                      icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                      label: const Text("Supprimer", style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ].map((widget) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: widget,
              )).toList(),
            ),

            const SizedBox(height: 30),

            // Contenu
            Row(
              children: [
                const Icon(Icons.description, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Text("Contenu", style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),

            Container(
              decoration: const BoxDecoration(), // ou null
              padding: const EdgeInsets.all(20),
              child: AbsorbPointer(
                child: quill.QuillEditor.basic(
                  controller: quill.QuillController(
                    document: document,
                    selection: const TextSelection.collapsed(offset: 0),
                  ),
                  config: quill.QuillEditorConfig(
                    embedBuilders: [
                      CustomStyledImageBuilder(),
                      ...FlutterQuillEmbeds.editorBuilders(),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Tags
            if (tags.isNotEmpty) ...[
              Text("Tags", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: tags.map((tag) {
                  return Chip(
                    label: Text(tag.toString()),
                    backgroundColor: const Color(0xFFEDE9F8),
                    labelStyle: const TextStyle(fontWeight: FontWeight.w500),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _InfoRow(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Colors.grey[700]),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _ChipInfo(IconData icon, String label, Color color) {
    return Chip(
      avatar: Icon(icon, size: 16, color: Colors.indigo),
      label: Text(label),
      backgroundColor: color,
      labelStyle: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
    );
  }
}
