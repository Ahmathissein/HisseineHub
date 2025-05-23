import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class HomeModulesScreen extends StatelessWidget {
  const HomeModulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fullModules = [
      _FullModuleCard(
        icon: LucideIcons.calendar,
        title: "Planning / Agenda",
        subtitle: "Vue mensuelle interactive, rappels et synchronisation multi-appareils.",
        bullets: [
          "Vue mensuelle interactive",
          "Rappels et notifications",
          "Synchronisation multi-appareils",
        ],
        onTap: () => Navigator.pushNamed(context, '/planning'),
      ),
      _FullModuleCard(
        icon: LucideIcons.bookOpen,
        title: "Journal personnel",
        subtitle: "Entrées datées avec émotions, insertion de média, recherche par thème.",
        bullets: [
          "Vue mensuelle interactive",
          "Rappels et notifications",
          "Synchronisation multi-appareils",
        ],
        onTap: () => Navigator.pushNamed(context, '/journal'),
      ),
      _FullModuleCard(
        icon: LucideIcons.briefcase,
        title: "Projets personnels",
        subtitle: "Tableau Kanban, échéances, suivi du temps et statistiques.",
        bullets: [
          "Vue mensuelle interactive",
          "Rappels et notifications",
          "Synchronisation multi-appareils",
        ],
        onTap: () => Navigator.pushNamed(context, '/projects'),
      ),
      _FullModuleCard(
        icon: LucideIcons.creditCard,
        title: "Suivi budget",
        subtitle: "Catégorisation automatique, graphiques, budgets personnalisables.",
        bullets: [
          "Vue mensuelle interactive",
          "Rappels et notifications",
          "Synchronisation multi-appareils",
        ],
        onTap: () {},
      ),
      _FullModuleCard(
        icon: LucideIcons.heart,
        title: "Santé & bien-être",
        subtitle: "Suivi activité, méditation, objectifs personnalisés.",
        bullets: [
          "Vue mensuelle interactive",
          "Rappels et notifications",
          "Synchronisation multi-appareils",
        ],
        onTap: () {},
      ),
    ];

    final compactModules = {
      "Modules pratiques": [
        _MiniModuleCard(LucideIcons.camera, "Souvenirs", "Capturez des moments", onTap: () {}),
        _MiniModuleCard(LucideIcons.bookOpen, "Media", "Suivez vos lectures", onTap: () => Navigator.pushNamed(context, '/media')),
        _MiniModuleCard(LucideIcons.lightbulb, "Idées", "Notez vos inspirations", onTap: () {}),
        _MiniModuleCard(LucideIcons.database, "Admin", "Tâches administratives", onTap: () {}),
        _MiniModuleCard(LucideIcons.fileText, "Documents", "Organisez vos fichiers", onTap: () => Navigator.pushNamed(context, '/documents')),
        _MiniModuleCard(LucideIcons.wrench, "Outils", "Vos sites et ressources", onTap: () {}),
        _MiniModuleCard(LucideIcons.sparkles, "Astuces", "Conseils et techniques", onTap: () {}),
      ],
      "Développement personnel": [
        _MiniModuleCard(LucideIcons.graduationCap, "Connaissances", "Centralisez vos savoirs", onTap: () {}),
        _MiniModuleCard(LucideIcons.repeat, "Routines", "Établissez des habitudes", onTap: () {}),
        _MiniModuleCard(LucideIcons.heartHandshake, "Gratitude", "Cultivez la reconnaissance", onTap: () {}),
      ],
      "Enrichissement": [
        _MiniModuleCard(LucideIcons.plane, "Voyages", "Planifiez vos aventures", onTap: () {}),
        _MiniModuleCard(LucideIcons.map, "Carte", "Explorez des lieux", onTap: () {}),
        _MiniModuleCard(LucideIcons.barChart2, "Stats", "Analysez vos données", onTap: () {}),
      ]
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Bienvenue sur LifeTrack",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            "Votre assistant personnel pour une vie organisée et épanouie",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          const SizedBox(height: 24),
          const Text(
            "Modules essentiels",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6)),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: fullModules.map((card) {
                  return SizedBox(
                    width: isWide ? (constraints.maxWidth - 48) / 2 : double.infinity,
                    child: card,
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 24),
          ...compactModules.entries.map((section) => _buildSection(context, section.key, section.value)).toList(),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> modules) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B46C1),
              )),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: modules.map((card) => SizedBox(
              width: isMobile ? double.infinity : 220,
              child: card,
            )).toList(),
          ),
        ],
      ),
    );
  }
}

class _FullModuleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> bullets;
  final VoidCallback onTap;
  final Color color;

  const _FullModuleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.bullets,
    required this.onTap,
    this.color = const Color(0xFF8B5CF6),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 380),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 3)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: bullets.map((text) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 3),
                    child: Icon(Icons.circle, size: 6, color: Colors.blue),
                  ),
                  const SizedBox(width: 6),
                  Expanded(child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                ],
              ),
            )).toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: color.withOpacity(0.2)),
                foregroundColor: color,
              ),
              onPressed: onTap,
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text("Explorer", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniModuleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MiniModuleCard(this.icon, this.title, this.subtitle, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.12),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, size: 24, color: Colors.deepPurple),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
