import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/quill_delta.dart' as quill;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'dart:typed_data';
import '../Journal_image/fetch_blob.dart'; // ou ton chemin correct


class CreerNoteScreen extends StatefulWidget {
  final Map<String, dynamic>? journalExistant;

  const CreerNoteScreen({super.key, this.journalExistant});

  @override
  State<CreerNoteScreen> createState() => _CreerNoteScreenState();
}


class _CreerNoteScreenState extends State<CreerNoteScreen> {
  final titleController = TextEditingController();
  final customTagsController = TextEditingController();
  late final quill.QuillController quillController;

  List<String> tagsDisponibles = [];
  List<String> tagsSelectionnes = [];
  List<String> customTags = [];
  String currentTagDraft = "";
  bool afficherChampAutre = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initialiserFormulaire(); // on fait un appel manuel
  }

  Future<void> _initialiserFormulaire() async {
    if (widget.journalExistant != null) {
      final journal = widget.journalExistant!;
      titleController.text = journal['titre'] ?? '';

      final contenu = journal['contenu'] ?? [];
      quillController = quill.QuillController(
        document: quill.Document.fromJson(contenu),
        selection: const TextSelection.collapsed(offset: 0),
      );

      final tags = (journal['tags'] ?? []) as List<dynamic>;
      tagsSelectionnes = tags.map((e) => e.toString()).toList();
    } else {
      quillController = quill.QuillController.basic();
    }

    await _loadTags();
  }


  Future<void> _loadTags() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) return;

    try {
      final response = await supabase
          .from('tags')
          .select('nom')
          .eq('user_id', userId);

      if (mounted) {
        setState(() {
          tagsDisponibles = (response as List)
              .map((e) => e['nom'].toString())
              .toList()
              .cast<String>();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur de chargement des tags: $e")),
        );
      }
    }
  }

  Future<void> _enregistrerNote() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      _showError("Utilisateur non connecté.");
      setState(() => _isLoading = false);
      return;
    }

    final titre = titleController.text.trim();
    final allTags = [...tagsSelectionnes, ...customTags];

    // 🔴 Validation stricte
    if (titre.length < 3) {
      _showError("Le titre est trop court (minimum 3 caractères).");
      setState(() => _isLoading = false);
      return;
    }
    if (titre.length > 100) {
      _showError("Le titre est trop long (maximum 100 caractères).");
      setState(() => _isLoading = false);
      return;
    }

    // Vérifie que le contenu n'est pas vide
    final plainText = quillController.document.toPlainText().trim();
    if (plainText.isEmpty) {
      _showError("Le contenu de la note ne peut pas être vide.");
      setState(() => _isLoading = false);
      return;
    }


    if (currentTagDraft.isNotEmpty) {
      _showError(
          "Validez ou supprimez le tag en cours de saisie avant d’enregistrer.");
      setState(() => _isLoading = false);
      return;
    }

    if (allTags.isEmpty) {
      _showError("Vous devez sélectionner ou ajouter au moins un tag.");
      setState(() => _isLoading = false);
      return;
    }

    for (final tag in customTags) {
      if (tag
          .trim()
          .isEmpty || tag.length < 2) {
        _showError("Un tag personnalisé est vide ou trop court.");
        setState(() => _isLoading = false);
        return;
      }
    }

    try {
      // 🔁 Traiter les images du contenu
      final processedDelta = await _processDocumentImages(
          quillController.document);
      quillController.document = quill.Document.fromDelta(processedDelta);


      // 💾 Ajouter en BDD les nouveaux tags restants uniquement
      for (final tag in customTags) {
        if (!tagsDisponibles.contains(tag)) {
          await supabase.from('tags').insert({
            'id': const Uuid().v4(),
            'nom': tag,
            'user_id': user.id,
          });
        }
      }

      if (widget.journalExistant != null) {
        // 🔁 Cas : mise à jour
        final journalId = widget.journalExistant!['id'];

        await supabase.rpc('update_journal_with_tags', params: {
          'p_id': journalId,
          'p_titre': titre,
          'p_contenu': processedDelta.toJson(),
          'p_tags': allTags,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Note mise à jour avec succès"),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        // ✅ Cas : création
        await supabase.rpc('create_journal_with_tags', params: {
          'p_titre': titre,
          'p_contenu': processedDelta.toJson(),
          'p_user_id': user.id,
          'p_tags': allTags,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Note enregistrée avec succès"),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      _showError("Erreur lors de l’enregistrement : $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<quill.Delta> _processDocumentImages(quill.Document doc) async {
    final delta = doc.toDelta();
    final processedDelta = quill.Delta.fromJson(delta.toJson());
    final supabase = Supabase.instance.client;

    for (final op in processedDelta.toList()) {
      if (op.isInsert && op.data is Map &&
          (op.data as Map).containsKey('image')) {
        final dataMap = op.data as Map<String, dynamic>;
        final imageData = dataMap['image'];
        if (imageData is String && (
            imageData.startsWith('data:image') ||
                imageData.startsWith('/data/') ||
                imageData.startsWith('blob:')
        )) {
          try {
            final imageUrl = await _uploadImageToSupabase(imageData);
            dataMap['image'] = imageUrl;
          } catch (e) {
            debugPrint("Erreur upload image: $e");
          }
        }
      }
    }


    return processedDelta;
  }

  Future<String> _uploadImageToSupabase(String imageData) async {
    final supabase = Supabase.instance.client;
    final fileName = '${const Uuid().v4()}.png';

    late Uint8List byteData;

    if (imageData.startsWith('data:image')) {
      byteData = base64.decode(imageData.split(',').last);
    }

    else if (imageData.startsWith('/data/')) {
      final file = File(imageData);
      byteData = await file.readAsBytes();
    }

    else if (kIsWeb && imageData.startsWith('blob:')) {
      byteData = await fetchBlobAsBytes(imageData);
    }


    else {
      throw Exception("Format d'image non pris en charge : $imageData");
    }

    await supabase.storage
        .from('journal-images')
        .uploadBinary(fileName, byteData,
        fileOptions: const FileOptions(contentType: 'image/png'));

    return supabase.storage
        .from('journal-images')
        .getPublicUrl(fileName);
  }


  void _handleTagInput(String value) {
    final parts = value.split(',');

    if (parts.length > 1) {
      final newTags = parts.sublist(0, parts.length - 1);
      for (var tag in newTags) {
        tag = tag.trim();
        if (tag.isNotEmpty && !customTags.contains(tag)) {
          setState(() => customTags.add(tag));
        }
      }

      // ✅ Efface le champ dès qu’une virgule est tapée
      customTagsController.clear();
      setState(() => currentTagDraft = "");
    } else {
      setState(() => currentTagDraft = value.trim());
    }
  }

  void _handleTagSubmission(String value) {
    final tag = value.trim();
    if (tag.isNotEmpty && !customTags.contains(tag)) {
      setState(() {
        customTags.add(tag);
        currentTagDraft = "";
      });
    }
    customTagsController.clear();
  }

  @override
  void dispose() {
    quillController.dispose();
    titleController.dispose();
    customTagsController.dispose();
    super.dispose();
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
          widget.journalExistant != null ? "Modifier la note" : "Nouvelle note",
          style: GoogleFonts.quicksand(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.black,
          ),
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
            _buildSectionTitle("Titre"),
            const SizedBox(height: 6),
            _buildInput(titleController, "Titre de la note"),

            const SizedBox(height: 16),
            _buildSectionTitle("Contenu"),
            _buildQuillEditor(),

            const SizedBox(height: 16),
            _buildSectionTitle("Tags"),
            const SizedBox(height: 6),
            _buildTagChips(),

            if (afficherChampAutre) ...[
              const SizedBox(height: 12),
              _buildSectionTitle("Autres tags (séparés par des virgules)"),
              const SizedBox(height: 6),
              _buildCustomTagInput(),
            ],

            const SizedBox(height: 24),
            _buildActionButtons(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
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

  Widget _buildInput(TextEditingController controller, String hint,
      {bool expands = false}) {
    return TextField(
      controller: controller,
      maxLines: expands ? null : 1,
      expands: expands,
      textAlignVertical: TextAlignVertical.top,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.quicksand(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: const Color(0xFF838FA2),
        ),
        alignLabelWithHint: true,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
    );
  }

  Widget _buildQuillEditor() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(6),
        color: Colors.white,
      ),
      child: Column(
        children: [
          // ✅ Barre d'outils Quill simple et moderne
          quill.QuillSimpleToolbar(
            controller: quillController,
            config: quill.QuillSimpleToolbarConfig(
              embedButtons: FlutterQuillEmbeds.toolbarButtons()
                  .where((b) => !b.toString().toLowerCase().contains('video'))
                  .toList(),
            ),
          ),

          const Divider(height: 1),

          // ✅ Éditeur Quill avec build sécurisé
          Container(
            constraints: const BoxConstraints(minHeight: 150, maxHeight: 300),
            padding: const EdgeInsets.all(10),
            child: quill.QuillEditor.basic(
              controller: quillController,
              config: quill.QuillEditorConfig(
                embedBuilders: FlutterQuillEmbeds.editorBuilders()
                    .where((b) => !b.toString().toLowerCase().contains('video'))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagChips() {
    return Wrap(
      spacing: 8,
      children: [
        // Afficher les tags Supabase
        ...tagsDisponibles.map((tag) {
          final estSelectionne = tagsSelectionnes.contains(tag);
          return ChoiceChip(
            label: Text(
                tag, style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
            selected: estSelectionne,
            selectedColor: const Color(0xFFA78BFA),
            backgroundColor: const Color(0xFFF1F5F9),
            labelStyle: TextStyle(
                color: estSelectionne ? Colors.white : Colors.black),
            onSelected: (selected) {
              setState(() {
                if (selected) {
                  tagsSelectionnes.add(tag);
                } else {
                  tagsSelectionnes.remove(tag);
                }
              });
            },
          );
        }),

        // ✅ Ajouter manuellement le bouton "autre"
        ChoiceChip(
          label: Text("autre", style: GoogleFonts.quicksand(
              fontWeight: FontWeight.bold)),
          selected: afficherChampAutre,
          selectedColor: const Color(0xFFA78BFA),
          backgroundColor: const Color(0xFFF1F5F9),
          labelStyle: TextStyle(
              color: afficherChampAutre ? Colors.white : Colors.black),
          onSelected: (selected) {
            setState(() {
              afficherChampAutre = selected;
              if (!selected) customTags
                  .clear(); // facultatif : réinitialise les tags personnalisés si on désélectionne
            });
          },
        ),
      ],
    );
  }

  Widget _buildCustomTagInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: customTagsController,
          onChanged: _handleTagInput,
          onSubmitted: _handleTagSubmission,
          decoration: InputDecoration(
            hintText: "ex: famille, perso, mémoire",
            hintStyle: GoogleFonts.quicksand(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: const Color(0xFF838FA2),
            ),
            alignLabelWithHint: true,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ...customTags.map((tag) =>
                Chip(
                  label: Text(tag, style: GoogleFonts.quicksand(
                      fontWeight: FontWeight.bold)),
                  backgroundColor: const Color(0xFFF1F5F9),
                  deleteIcon: const Icon(Icons.close),
                  onDeleted: () => setState(() => customTags.remove(tag)),
                )),
            if (currentTagDraft.isNotEmpty)
              Chip(
                label: Text(currentTagDraft,
                    style: GoogleFonts.quicksand(
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic)),
                backgroundColor: const Color(0xFFEDE9FE),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
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
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6)),
          ),
          child: Text("Annuler",
              style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _isLoading ? null : _enregistrerNote,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFA78BFA),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            textStyle: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6)),
          ),
          child: _isLoading
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
              : const Text("Enregistrer"),
        ),
      ],
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
    );
  }
}