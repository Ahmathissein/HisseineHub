import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/navbar.dart';
import '../widgets/sidebar.dart';

class PlanningScreen extends StatefulWidget {
  const PlanningScreen({super.key});

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> {
  bool isSidebarExpanded = false;
  String? selectedItemLabel = "Planning";

  void toggleSidebar() {
    setState(() {
      isSidebarExpanded = !isSidebarExpanded;
    });
  }

  void onItemSelected(String label) {
    setState(() {
      selectedItemLabel = label;
      // Optionnel : ajouter une navigation conditionnelle ici si nécessaire
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: Stack(
        children: [
          // 👇 Contenu principal de Planning
          Positioned.fill(
            left: 70,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "📅 Planning",
                      style: GoogleFonts.quicksand(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text("Bienvenue dans votre agenda personnalisé.\nIci s'afficheront vos événements, rappels et tâches à venir."),
                    // Ajouter ici votre calendrier ou vue planning
                  ],
                ),
              ),
            ),
          ),

          // 👇 Sidebar (superposée)
          Positioned(
            top: 0,
            left: 0,
            bottom: 0,
            child: Material(
              elevation: 8,
              color: Colors.transparent,
              child: SideBar(
                isExpanded: isSidebarExpanded,
                onToggle: toggleSidebar,
                selectedLabel: selectedItemLabel,
                onItemSelected: onItemSelected,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
