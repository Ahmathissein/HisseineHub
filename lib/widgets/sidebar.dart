import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SidebarItem {
  final IconData icon;
  final String label;

  const SidebarItem({required this.icon, required this.label});
}

class SideBar extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onToggle  ;
  final String? selectedLabel;
  final Function(String) onItemSelected;

  const SideBar({
    super.key,
    required this.isExpanded,
    required this.onToggle,
    required this.selectedLabel,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: isExpanded ? 220 : 70,
      color: const Color(0xFFF7F6FB),
      child: Column(
        crossAxisAlignment: isExpanded ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Align(
              alignment: isExpanded ? Alignment.centerRight : Alignment.center,
              child: IconButton(
                icon: Icon(isExpanded ? Icons.arrow_back : Icons.arrow_forward),
                onPressed: onToggle,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: isExpanded ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                children: [
                  buildSection("NIVEAU 1", [
                    SidebarItem(icon: LucideIcons.calendar, label: "Planning"),
                    SidebarItem(icon: LucideIcons.bookOpen, label: "Journal"),
                    SidebarItem(icon: LucideIcons.briefcase, label: "Projects"),
                    SidebarItem(icon: LucideIcons.creditCard, label: "Finance"),
                    SidebarItem(icon: LucideIcons.heart, label: "Health"),
                  ]),
                  buildSection("NIVEAU 2", [
                    SidebarItem(icon: LucideIcons.camera, label: "Souvenirs"),
                    SidebarItem(icon: LucideIcons.bookOpen, label: "Media"),
                    SidebarItem(icon: LucideIcons.lightbulb, label: "Idées"),
                    SidebarItem(icon: LucideIcons.database, label: "Admin"),
                    SidebarItem(icon: LucideIcons.fileText, label: "Documents"),
                  ]),
                  buildSection("NIVEAU 3", [
                    SidebarItem(icon: LucideIcons.atSign, label: "Connaissances"),
                    SidebarItem(icon: LucideIcons.share2, label: "Routines"),
                    SidebarItem(icon: LucideIcons.star, label: "Gratitude"),
                  ]),
                  buildSection("NIVEAU 4", [
                    SidebarItem(icon: LucideIcons.plane, label: "Voyages"),
                    SidebarItem(icon: LucideIcons.map, label: "Carte"),
                    SidebarItem(icon: LucideIcons.barChart2, label: "Stats"),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSection(String title, List<SidebarItem> items) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isExpanded ? 16.0 : 0, vertical: 8),
      child: Column(
        crossAxisAlignment: isExpanded ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ...items.map((item) => itemTile(item)).toList(),
        ],
      ),
    );
  }

  Widget itemTile(SidebarItem item) {
    final bool isSelected = selectedLabel != null && item.label == selectedLabel;
    const Color selectedBg = Color(0xFFEBE7FD); // fond au clic
    const Color hoverBg = Color(0xFFEFE9FC);    // fond au survol

    return StatefulBuilder(
      builder: (context, setState) {
        bool isHovered = false;

        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: InkWell(
            onTap: () => onItemSelected(item.label),
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? selectedBg
                    : isHovered
                    ? hoverBg
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment:
                isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                children: [
                  Icon(
                    item.icon,
                    size: 22,
                    color: isSelected ? Colors.deepPurple : Colors.black,
                  ),
                  if (isExpanded)
                    Padding(
                      padding: const EdgeInsets.only(left: 12.0),
                      child: Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.deepPurple : Colors.black,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
