import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert'; // en haut du fichier
import '../../widgets/AppLayout.dart';
import 'DetailJournalScreen.dart';
import 'creerNote.dart';
import 'package:intl/intl.dart';


class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  String? tagFiltreActuel;

  Future<List<Map<String, dynamic>>> _fetchJournaux({bool favorisSeulement = false}) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return [];

    // Construction de la requête de base
    PostgrestFilterBuilder query = Supabase.instance.client
        .from('journaux')
        .select('id, titre, contenu, date_creation, date_modification, favori, version, is_shared, journal_tags(tag_id, tags(nom))')
        .eq('user_id', user.id);

    // Ajout du filtre favori si demandé
    if (favorisSeulement) {
      query = query.eq('favori', true);
    }

    final response = await query.order('date_creation', ascending: false);

    if (response is! List) return [];

    final allNotes = response.cast<Map<String, dynamic>>();

    // Filtrage manuel par tag (côté client)
    if (tagFiltreActuel != null) {
      return allNotes.where((note) {
        final tags = (note['journal_tags'] as List)
            .map((jt) => jt['tags']['nom'] as String)
            .toList();
        return tags.contains(tagFiltreActuel);
      }).toList();
    }

    return allNotes;
  }

  String _getPreview(dynamic deltaContent) {
    print("🔍 Contenu brut reçu depuis la BDD :");
    print(deltaContent);

    try {
      final ops = deltaContent as List<dynamic>;
      print("✅ Contenu interprété comme List d'ops. Longueur : ${ops.length}");

      final buffer = StringBuffer();

      for (final op in ops) {
        print("🔸 Opération : $op");

        if (op is Map && op.containsKey('insert')) {
          final insert = op['insert'];
          print("➡️ Texte inséré : $insert (type: ${insert.runtimeType})");

          if (insert is String) {
            buffer.write(insert);
            print("📝 Buffer actuel : ${buffer.toString()}");
          }
        } else {
          print("❌ Ignoré : opération invalide ou sans 'insert'");
        }

        if (buffer.length > 120) {
          print("📏 Limite atteinte (120 caractères). Sortie anticipée.");
          break;
        }
      }

      final text = buffer.toString().trim().replaceAll('\n', ' ');
      final preview = text.length > 120 ? text.substring(0, 120) : text;

      print("✅ Aperçu final : $preview");
      return preview;
    } catch (e) {
      print("❌ Erreur lors du traitement : $e");
      return "[Contenu non lisible]";
    }
  }

  int selectedTab = 0; // 0 = toutes, 1 = favoris, 2 = tags

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      selectedItemLabel: "Journal",
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre + bouton
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Journal personnel",
                          style: GoogleFonts.quicksand(
                              fontWeight: FontWeight.bold, fontSize: 25, color: Colors.black)),
                      const SizedBox(height: 4),
                      Text("Notez vos pensées, idées et réflexions",
                          style: GoogleFonts.quicksand(
                              fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF838FA2))),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CreerNoteScreen()));
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("Nouvelle note"),
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

            // Recherche + filtre
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Rechercher dans le journal...",
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
                      hintStyle: GoogleFonts.quicksand(
                          fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF838FA2)),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.calendar_today, size: 16, color: Color(0xFF475569)),
                  label: Text("Filtrer par date",
                      style: GoogleFonts.quicksand(
                          fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF475569))),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Onglets
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(5)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTab("Toutes les notes", 0),
                  _buildTab("Favoris", 1),
                  _buildTab("Tags", 2),
                ],
              ),
            ),

            const SizedBox(height: 2),

// 🔁 DÉBUT DU BLOC À REMPLACER
            if (selectedTab == 2) ...[
              TagsSection(
                onTagSelected: (tag) {
                  setState(() {
                    tagFiltreActuel = tag;
                  });
                },
              ),
              const SizedBox(height: 12),
              if (tagFiltreActuel == null)
                Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: Center(
                    child: Text(
                      "Sélectionnez un tag pour afficher les journaux associés.",
                      style: GoogleFonts.quicksand(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                )
              else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Text(
                        "📎 Journaux liés au tag : ",
                        style: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(
                          tagFiltreActuel!,
                          style: GoogleFonts.quicksand(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor: const Color(0xFF8B5CF6), // violet
                        deleteIconColor: Colors.white,
                        onDeleted: () {
                          setState(() {
                            tagFiltreActuel = null;
                          });
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                    ],
                  ),
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final screenWidth = constraints.maxWidth;
                    final crossAxisCount = screenWidth > 1200
                        ? 3
                        : screenWidth > 800
                        ? 2
                        : 1;

                    return FutureBuilder<List<Map<String, dynamic>>>(
                      future: _fetchJournaux(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 32),
                            child: Center(
                              child: Text(
                                "Aucune note trouvée pour ce tag.",
                                style: GoogleFonts.quicksand(fontSize: 16, color: Colors.grey),
                              ),
                            ),
                          );
                        }

                        final journaux = snapshot.data!;

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: journaux.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            mainAxisExtent: 220,
                          ),
                          itemBuilder: (context, index) {
                            final journal = journaux[index];
                            final tags = (journal['journal_tags'] as List)
                                .map((jt) => jt['tags']['nom'] as String)
                                .toList();

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DetailJournalScreen(journal: journal),
                                  ),
                                );
                              },
                              child: NoteCard(
                                id: journal['id'],
                                title: journal['titre'] ?? '',
                                date: journal['date_creation'] ?? '',
                                content: _getPreview(journal['contenu']),
                                tags: tags,
                                isFavorite: journal['favori'] == true,
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ],
            ]
// 🔁 FIN DU BLOC À REMPLACER
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 800 ? 2 : 1;
                  return FutureBuilder<List<Map<String, dynamic>>>(
                    future: _fetchJournaux(favorisSeulement: selectedTab == 1),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 32),
                          child: Center(
                            child: Text("Aucune note pour l’instant.",
                                style: GoogleFonts.quicksand(fontSize: 16, color: Colors.grey)),
                          ),
                        );
                      }

                      final journaux = snapshot.data!;
                      final screenWidth = constraints.maxWidth;
                      final crossAxisCount = screenWidth > 1200
                          ? 3
                          : screenWidth > 800
                          ? 2
                          : 1;

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: journaux.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          mainAxisExtent: 220,
                        ),
                        itemBuilder: (context, index) {
                          final journal = journaux[index];
                          final tags = (journal['journal_tags'] as List)
                              .map((jt) => jt['tags']['nom'] as String)
                              .toList();

                          return GestureDetector(
                            onTap: () {
                              final tags = (journal['journal_tags'] as List)
                                  .map((jt) => jt['tags']['nom'] as String)
                                  .toList();

                              final formattedJournal = {
                                'id': journal['id'],
                                'titre': journal['titre'],
                                'contenu': journal['contenu'],
                                'dateCreation': journal['date_creation'],
                                'dateModification': journal['date_modification'],
                                'version': journal['version'],
                                'isShared': journal['is_shared'],
                                'favori': journal['favori'],
                                'tags': tags,
                              };

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DetailJournalScreen(journal: formattedJournal),
                                ),
                              );
                            },

                            child: NoteCard(
                              id: journal['id'],
                              title: journal['titre'] ?? '',
                              date: journal['date_creation'] ?? '',
                              content: _getPreview(journal['contenu']),
                              tags: tags,
                              isFavorite: journal['favori'] == true,
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              )


          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = selectedTab == index;
    return Padding(
      padding: const EdgeInsets.only(right: 5),
      child: TextButton(
          onPressed: () {
            setState(() {
              selectedTab = index;
              tagFiltreActuel = null; // ✅ Réinitialiser le filtre tag quand on change d’onglet
            });
          },
        child: Text(label),
        style: TextButton.styleFrom(
          backgroundColor: isSelected ? Colors.white : const Color(0xFFF1F5F9),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
          textStyle: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class NoteCard extends StatefulWidget {
  final String title;
  final String date;
  final String content;
  final List<String> tags;
  final bool isFavorite;
  final String id; // <-- on a besoin de l'id pour modifier Supabase

  const NoteCard({
    super.key,
    required this.title,
    required this.date,
    required this.content,
    required this.tags,
    required this.isFavorite,
    required this.id,
  });

  @override
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard> {
  late bool isFavorite;

  @override
  void initState() {
    super.initState();
    isFavorite = widget.isFavorite;
  }

  Future<void> toggleFavorite() async {
    final newValue = !isFavorite;
    setState(() {
      isFavorite = newValue;
    });

    try {
      await Supabase.instance.client
          .from('journaux')
          .update({'favori': newValue})
          .eq('id', widget.id);
    } catch (e) {
      print("❌ Erreur Supabase : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity, // compatible avec Grid
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: const Border(left: BorderSide(color: Color(0xFF8B5CF6), width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Titre + favori
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.quicksand(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              IconButton(
                onPressed: toggleFavorite,
                icon: Icon(
                  Icons.star,
                  color: isFavorite ? Colors.deepPurple : Colors.black,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _formatterDateFr(widget.date),
            style: GoogleFonts.quicksand(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              widget.content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.quicksand(fontSize: 13, color: Colors.black87),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 24,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: widget.tags.map((tag) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      tag,
                      style: GoogleFonts.quicksand(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatterDateFr(String dateStr) {
    try {
      final parsed = DateTime.parse(dateStr);
      return DateFormat("EEEE 'le' d MMMM yyyy 'à' HH'h'mm", 'fr_FR').format(parsed);
    } catch (e) {
      return dateStr;
    }
  }
}

class TagsSection extends StatefulWidget {
  final void Function(String)? onTagSelected; // ✅ nouveau paramètre
  const TagsSection({super.key, this.onTagSelected});

  @override
  State<TagsSection> createState() => _TagsSectionState();
}


class _TagsSectionState extends State<TagsSection> {
  List<String> tags = [];
  final TextEditingController _tagController = TextEditingController();
  bool showInput = false;
  bool modificationActive = false;
  String? tagAModifier;
  bool suppressionActive = false;
  Set<String> tagsSelectionnes = {};


  @override
  void initState() {
    super.initState();
    _fetchTags();
  }

  Future<void> _fetchTags() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final res = await Supabase.instance.client.from('tags').select('nom').eq('user_id', userId);
    if (res is List) {
      setState(() {
        tags = res.map((e) => e['nom'].toString()).toList();
      });
    }
  }

  Future<void> _addTag(String tagName) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Utilisateur non connecté")),
      );
      return;
    }

    final nom = tagName.trim().toLowerCase();
    if (nom.isEmpty) return;

    // Évite les doublons si le tag existe déjà localement
    if (tags.contains(nom)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ce tag existe déjà.")),
      );
      return;
    }

    try {
      final uuid = const Uuid();
      final tagId = uuid.v4();

      await Supabase.instance.client
          .from('tags')
          .insert({
        'id': tagId,
        'nom': nom,
        'user_id': user.id,
      })
          .select(); // requis pour déclencher l'insertion

      _tagController.clear();
      setState(() => showInput = false);
      await _fetchTags(); // recharge la liste
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tag ajouté avec succès")),
      );
    } catch (e) {
      if (e is PostgrestException) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur Supabase : ${e.message}")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur inattendue : $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.local_offer_rounded, size: 20, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Text("Tags",
                    style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.deepPurple),
                  tooltip: "Modifier un tag",
                  onPressed: () {
                    setState(() {
                      modificationActive = !modificationActive;
                      suppressionActive = false;
                      tagAModifier = null;
                      showInput = false;
                      _tagController.clear();
                    });
                  },
                ),
                IconButton(
                  icon: Icon(suppressionActive ? Icons.cancel : Icons.delete, color: Colors.deepPurple),
                  tooltip: suppressionActive ? "Annuler suppression" : "Supprimer des tags",
                  onPressed: () {
                    setState(() {
                      suppressionActive = !suppressionActive;
                      modificationActive = false;
                      tagAModifier = null;
                      showInput = false;
                      _tagController.clear();
                      tagsSelectionnes.clear();
                    });
                  },
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 12),
        if (modificationActive || suppressionActive)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              modificationActive
                  ? "👉 Cliquez sur un tag à modifier"
                  : "🗑️ Sélectionnez les tags à supprimer",
              style: GoogleFonts.quicksand(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: modificationActive ? Colors.deepPurple : Colors.red[800],
              ),
            ),
          ),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...tags.map((tag) => GestureDetector(
              onTap: () {
                if (suppressionActive) {
                  setState(() {
                    if (tagsSelectionnes.contains(tag)) {
                      tagsSelectionnes.remove(tag);
                    } else {
                      tagsSelectionnes.add(tag);
                    }
                  });
                } else if (modificationActive) {
                  setState(() {
                    tagAModifier = tag;
                    showInput = true;
                    _tagController.text = tag;
                  });
                } else if (widget.onTagSelected != null) {
                  widget.onTagSelected!(tag); // ✅ Appelle le callback avec le tag sélectionné
                }
              },

              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: tagsSelectionnes.contains(tag)
                      ? Colors.red[100]
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tag,
                  style: GoogleFonts.quicksand(
                      fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ),
            )),
            if (!suppressionActive && !modificationActive)
              GestureDetector(
              onTap: () => setState(() => showInput = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.add, size: 16, color: Colors.deepPurple),
                    const SizedBox(width: 4),
                    Text("Ajouter", style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
                  ]),
                ),
              ),
            if (suppressionActive && tagsSelectionnes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.delete_forever),
                      label: const Text("Supprimer la sélection"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Confirmation"),
                            content: const Text("Voulez-vous vraiment supprimer les tags sélectionnés ?"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text("Annuler"),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text("Supprimer"),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          final userId = Supabase.instance.client.auth.currentUser?.id;
                          for (final tag in tagsSelectionnes) {
                            await Supabase.instance.client
                                .from('tags')
                                .delete()
                                .eq('user_id', userId as String)
                                .eq('nom', tag);
                          }
                          setState(() {
                            tagsSelectionnes.clear();
                            suppressionActive = false;
                          });
                          await _fetchTags();
                        }
                      },
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          suppressionActive = false;
                          tagsSelectionnes.clear();
                        });
                      },
                      child: const Text("Annuler"),
                    ),
                  ],
                ),
              ),

          ],
        ),
        if (showInput)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    decoration: InputDecoration(
                      hintText: "Nom du tag",
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    final nom = _tagController.text.trim().toLowerCase();
                    if (nom.isEmpty) return;

                    if (tagAModifier != null) {
                      // Modification
                      final userId = Supabase.instance.client.auth.currentUser?.id;
                      await Supabase.instance.client
                          .from('tags')
                          .update({'nom': nom})
                          .eq('user_id', userId as String)
                          .eq('nom', tagAModifier!);

                      setState(() {
                        tagAModifier = null;
                        showInput = false;
                        modificationActive = false; // ✅ Masquer message après modification
                        _tagController.clear();
                      });
                      _fetchTags();
                    } else {
                      // Ajout
                      _addTag(nom);
                    }
                  },
                  child: Text(tagAModifier != null ? "Modifier" : "Ajouter"),
                ),
                if (tagAModifier != null)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        tagAModifier = null;
                        _tagController.clear();
                        showInput = false;
                        modificationActive = false;
                      });
                    },
                    child: const Text("Annuler"),
                  ),
              ],
            ),
          ),

      ],
    );
  }
}


