import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../authentification/signup.dart';


class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();

}

class _CustomAppBarState extends State<CustomAppBar> {
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      setState(() {}); // Force le rebuild pour refléter l'état connecté/déconnecté
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 2,
      title: Text(
        'LifeTrack',
        style: GoogleFonts.quicksand(
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
            fontSize: 20,
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications, color: Colors.black),
          onPressed: () {}, // Tu peux gérer les notifs plus tard
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: PopupMenuButton<String>(
            icon: const Icon(Icons.person, color: Colors.black),
            onSelected: (value) async {
              if (value == 'logout') {
                await supabase.auth.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              } else if (value == 'signup') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SignUpScreen()),
                );
              } else if (value == 'login') {
                Navigator.pushNamed(context, '/login');
              }

              // Tu peux aussi gérer 'profil', 'settings', etc.
            },

            itemBuilder: (context) {
              if (user != null) {
                return [
                  const PopupMenuItem(
                    value: 'header',
                    enabled: false,
                    child: Text('Mon compte', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const PopupMenuItem(value: 'profil', child: Text('Profil')),
                  const PopupMenuItem(value: 'settings', child: Text('Paramètres')),
                  const PopupMenuItem(value: 'theme', child: Text('Thème')),
                  const PopupMenuDivider(),
                  const PopupMenuItem(value: 'logout', child: Text('Déconnexion')),
                ];
              } else {
                return [
                  const PopupMenuItem(value: 'signup', child: Text("S'inscrire")),
                  const PopupMenuItem(value: 'login', child: Text("Se connecter")),
                ];
              }
            },
          ),
        ),
      ],
    );
  }
}
