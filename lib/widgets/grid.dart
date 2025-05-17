import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ModuleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final VoidCallback onTap;

  const ModuleCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.deepPurple),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const Spacer(),
          OutlinedButton(
            onPressed: onTap,
            child: const Text("Accéder"),
          )
        ],
      ),
    );
  }
}

class ModulesScreen extends StatelessWidget {
  const ModulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Widget> modules = [
      ModuleCard(
        icon: LucideIcons.calendar,
        title: "Planning / Agenda",
        subtitle: "Organisez votre emploi du temps",
        description: "Calendrier mensuel / hebdo, rappels personnalisés, vue \"à faire aujourd'hui\"",
        onTap: () {},
      ),
      ModuleCard(
        icon: LucideIcons.bookOpen,
        title: "Journal personnel / Notes",
        subtitle: "Notez vos pensées et réflexions",
        description: "Notes datées avec tags, ajout de médias, recherche par mot-clé",
        onTap: () {},
      ),
      ModuleCard(
        icon: LucideIcons.briefcase,
        title: "Projets personnels",
        subtitle: "Gérez vos projets et tâches",
        description: "Création de projets, tâches, priorités, état d'avancement",
        onTap: () {},
      ),
      ModuleCard(
        icon: LucideIcons.creditCard,
        title: "Suivi budget",
        subtitle: "Analysez vos finances personnelles",
        description: "Dépenses classées, revenus, solde automatique, graphiques",
        onTap: () {},
      ),
      ModuleCard(
        icon: LucideIcons.heart,
        title: "Santé & forme",
        subtitle: "Suivez votre bien-être",
        description: "Suivi du poids, activités sportives, sommeil et alimentation",
        onTap: () {},
      ),
    ];

    final isMobile = MediaQuery.of(context).size.width < 600;

    return GridView.count(
      crossAxisCount: isMobile ? 1 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.3,
      children: modules,
    );
  }
}