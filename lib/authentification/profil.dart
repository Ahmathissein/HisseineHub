import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final supabase = Supabase.instance.client;
  final nomController = TextEditingController();
  final prenomController = TextEditingController();
  final emailController = TextEditingController();
  final bioController = TextEditingController();
  int selectedTabIndex = 0;
  String? photoUrl;

  @override
  void initState() {
    super.initState();
    _chargerInfos();
  }

  Future<void> _chargerInfos() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      final data = await supabase.from('utilisateurs').select().eq('id', user.id).maybeSingle();
      setState(() {
        photoUrl = data?['photo_profil'];
        nomController.text = data?['nom'] ?? '';
        prenomController.text = data?['prenom'] ?? '';
        emailController.text = data?['email'] ?? '';
        bioController.text = data?['bio'] ?? '';
      });
    }
  }

  Future<void> _selectAndUploadImage() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      Uint8List? bytes;
      String? fileExt;

      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile == null) {
        debugPrint("Aucun fichier sélectionné.");
        return;
      }

      bytes = await pickedFile.readAsBytes();
      fileExt = pickedFile.path.split('.').last;

      final filePath = '$userId/avatar.$fileExt';
      final storage = supabase.storage.from('avatars');
      await storage.uploadBinary(filePath, bytes, fileOptions: const FileOptions(upsert: true));

      final publicUrl = storage.getPublicUrl(filePath);
      await supabase.from('utilisateurs').update({'photo_profil': publicUrl}).eq('id', userId);

      setState(() => photoUrl = publicUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Photo de profil mise à jour.")),
        );
      }
    } catch (e, stack) {
      debugPrint("Erreur lors de l'upload de la photo : $e");
      debugPrint("Stack: $stack");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur : $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 960;
    return Scaffold(
      backgroundColor: const Color(0xFFf1f0fb),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: const Color(0xFFf1f0fb),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Mon profil",
              style: GoogleFonts.quicksand(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              onPressed: () => Navigator.pushReplacementNamed(context, '/'), // 🔁 change '/accueil' si besoin
              child: Text(
                "Retour au tableau de bord",
                style: GoogleFonts.quicksand(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
          child: IntrinsicHeight(
            child: Flex(
              direction: isSmallScreen ? Axis.vertical : Axis.horizontal,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: isSmallScreen ? double.infinity : 300,
                  child: _buildProfilHeader(),
                ),
                SizedBox(width: isSmallScreen ? 0 : 24, height: isSmallScreen ? 24 : 0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9), // ✅ fond global clair
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween, // ✅ distributeur d’espace
                          children: [
                            Expanded(child: _buildTab("Profil", 0)),
                            Expanded(child: _buildTab("Sécurité", 1)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          return FadeTransition(opacity: animation, child: child);
                        },
                        child: selectedTabIndex == 0
                            ? InfosPersonnellesCard(
                          key: const ValueKey('infos'),
                          nomController: nomController,
                          prenomController: prenomController,
                          emailController: emailController,
                          bioController: bioController,
                          onSave: () async {
                            await supabase.from('utilisateurs').update({
                              'nom': nomController.text,
                              'prenom': prenomController.text,
                              'bio': bioController.text,
                            }).eq('id', supabase.auth.currentUser?.id as Object);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Modifications enregistrées")),
                              );
                            }
                          },
                        )
                            : const SecurityCard(key: ValueKey('securite')),
                      ),

                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String label, int index, {bool isLeft = false, bool isRight = false}) {
    final isActive = selectedTabIndex == index;

    return GestureDetector(
      onTap: () => setState(() => selectedTabIndex = index),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
            borderRadius: BorderRadius.only(
              topLeft: isLeft ? const Radius.circular(8) : Radius.zero,
              bottomLeft: isLeft ? const Radius.circular(8) : Radius.zero,
              topRight: isRight ? const Radius.circular(8) : Radius.zero,
              bottomRight: isRight ? const Radius.circular(8) : Radius.zero,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.quicksand(
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: const Color(0xFF3A3A3A),
              ),
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildProfilHeader() {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _selectAndUploadImage,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: photoUrl != null
                      ? NetworkImage(photoUrl!)
                      : const AssetImage('assets/default_avatar.png') as ImageProvider,
                ),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: const Icon(Icons.edit, size: 16),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            nomController.text.isNotEmpty ? nomController.text : "Nom manquant",
            style: GoogleFonts.quicksand(
                fontSize: 20,
                fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            emailController.text.isNotEmpty ? emailController.text : "Email manquant",
            style: GoogleFonts.quicksand(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF838FA2),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            bioController.text.isNotEmpty ? bioController.text : "Aucune bio renseignée",
            textAlign: TextAlign.center,
            style: GoogleFonts.quicksand(fontSize: 14, fontWeight: FontWeight.w600,               color: Color(0xFF838FA2),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              await supabase.auth.signOut();
              if (mounted) Navigator.pushReplacementNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
              side: const BorderSide(color: Colors.grey),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text("Se déconnecter", style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}


class InfosPersonnellesCard extends StatelessWidget {
  final TextEditingController nomController;
  final TextEditingController prenomController;
  final TextEditingController emailController;
  final TextEditingController bioController;
  final VoidCallback onSave;

  const InfosPersonnellesCard({
    super.key,
    required this.nomController,
    required this.prenomController,
    required this.emailController,
    required this.bioController,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Informations personnelles",
            style: GoogleFonts.quicksand(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            "Mettez à jour vos informations personnelles",
            style: GoogleFonts.quicksand(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF838FA2),
            ),
          ),

          const SizedBox(height: 24),

          // Champ NOM
          Text(
            "Nom",
            style: GoogleFonts.quicksand(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3A3A3A),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: nomController,
            style: GoogleFonts.quicksand(
              fontSize: 15,
              fontWeight: FontWeight.bold, // ✅ texte affiché en gras
                color: Color(0xFF838FA2),
            ),
            decoration: InputDecoration(
              // 🔁 Texte de suggestion (placeholder)
              hintText: "Entrez votre nom", // 👉 Modifiable ici
              hintStyle: GoogleFonts.quicksand(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey, // 👉 Couleur du placeholder
              ),
              filled: true,
              fillColor: const Color(0xFFFCFAFF),
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
            ),
          ),

          const SizedBox(height: 16),

          // Champ PRENOM
          Text(
            "Prénom",
            style: GoogleFonts.quicksand(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3A3A3A),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: prenomController,
            style: GoogleFonts.quicksand(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF838FA2),
            ),
            decoration: InputDecoration(
              hintText: "Entrez votre prénom",
              hintStyle: GoogleFonts.quicksand(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
              filled: true,
              fillColor: const Color(0xFFFCFAFF),
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
            ),
          ),
          const SizedBox(height: 16),

          // Champ EMAIL
          Text(
            "Email",
            style: GoogleFonts.quicksand(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3A3A3A),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: emailController,
            style: GoogleFonts.quicksand(
              fontSize: 15,
              fontWeight: FontWeight.bold, // ✅ texte affiché en gras
              color: Color(0xFF838FA2),
            ),
            readOnly: true,
            decoration: InputDecoration(
              hintText: "Votre adresse email",
              hintStyle: GoogleFonts.quicksand(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
              filled: true,
              fillColor: const Color(0xFFFCFAFF),
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
            ),
          ),

          const SizedBox(height: 16),

          // Champ BIO
          Text(
            "Bio",
            style: GoogleFonts.quicksand(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3A3A3A),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: bioController,
            style: GoogleFonts.quicksand(
              fontSize: 15,
              fontWeight: FontWeight.bold, // ✅ texte affiché en gras
              color: Color(0xFF838FA2),
            ),
            decoration: InputDecoration(
              hintText: "Parlez un peu de vous...", // 👉 Modifiable ici
              hintStyle: GoogleFonts.quicksand(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.grey,
              ),
              filled: true,
              fillColor: const Color(0xFFFCFAFF),
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
            ),
          ),

          const SizedBox(height: 24),

          // Bouton de sauvegarde
          ElevatedButton(
            onPressed: onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFA78BFA),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              "Sauvegarder les modifications",
              style: GoogleFonts.quicksand(
              fontWeight: FontWeight.w600, // ✅ texte en gras
              fontSize: 16,
               ),
            ),
          ),
        ],
      ),
    );
  }
}

class SecurityCard extends StatelessWidget {
  const SecurityCard({super.key});

  @override
  Widget build(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Sécurité",
            style: GoogleFonts.quicksand(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            "Changez votre mot de passe",
            style: GoogleFonts.quicksand(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF838FA2),
            ),
          ),
          const SizedBox(height: 24),

          // 🔐 Mot de passe actuel
          Text(
            "Mot de passe actuel",
            style: GoogleFonts.quicksand(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF3A3A3A)),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: currentPasswordController,
            obscureText: true,
            style: GoogleFonts.quicksand(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF838FA2)),
            decoration: InputDecoration(
              hintText: "Entrez votre mot de passe actuel",
              hintStyle: GoogleFonts.quicksand(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF838FA2), // ✅ couleur personnalisée
              ),
              filled: true,
              fillColor: const Color(0xFFFCFAFF),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFDDD6F3), width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFA78BFA), width: 2),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 🔐 Nouveau mot de passe
          Text(
            "Nouveau mot de passe",
            style: GoogleFonts.quicksand(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF3A3A3A)),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: newPasswordController,
            obscureText: true,
            style: GoogleFonts.quicksand(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF838FA2)),
            decoration: InputDecoration(
              hintText: "Entrez un nouveau mot de passe",
              hintStyle: GoogleFonts.quicksand(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF838FA2), // ✅ couleur personnalisée
              ),
              filled: true,
              fillColor: const Color(0xFFFCFAFF),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFDDD6F3), width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFA78BFA), width: 2),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 🔐 Confirmation
          Text(
            "Confirmer le nouveau mot de passe",
            style: GoogleFonts.quicksand(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF3A3A3A)),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: confirmPasswordController,
            obscureText: true,
            style: GoogleFonts.quicksand(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF838FA2)),
            decoration: InputDecoration(
              hintText: "Répétez le mot de passe",
              hintStyle: GoogleFonts.quicksand(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF838FA2)),
              filled: true,
              fillColor: const Color(0xFFFCFAFF),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFDDD6F3), width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFA78BFA), width: 2),
              ),
            ),
          ),

          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: () async {
              final newPass = newPasswordController.text.trim();
              final confirmPass = confirmPasswordController.text.trim();
              if (newPass != confirmPass) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Les mots de passe ne correspondent pas")),
                );
                return;
              }

              try {
                await Supabase.instance.client.auth.updateUser(UserAttributes(password: newPass));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Mot de passe mis à jour !")),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Erreur : $e")),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFA78BFA),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
                "Changer le mot de passe",
                style: GoogleFonts.quicksand(
                fontWeight: FontWeight.w600, // ✅ texte en gras
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
