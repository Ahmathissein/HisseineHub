import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'AjouterMediaDialog.dart';

class MediaItem {
  final String type; // livre, film, série
  final String title;
  final String description;
  final int rating;

  MediaItem(this.type, this.title, this.description, this.rating);
}

class MediaScreen extends StatefulWidget {
  const MediaScreen({super.key});

  @override
  State<MediaScreen> createState() => _MediaScreenState();
}

class _MediaScreenState extends State<MediaScreen> {
  String selectedType = "Tous";

  final List<MediaItem> allItems = [
    MediaItem("livre", "Le Petit Prince", "Un conte philosophique intemporel.", 5),
    MediaItem("film", "Inception", "Un thriller de science-fiction captivant.", 1),
    MediaItem("série", "Breaking Bad", "L’ascension d’un professeur devenu baron de la drogue.", 3),
  ];

  List<MediaItem> get filteredItems {
    if (selectedType == "Tous") return allItems;
    return allItems.where((item) => item.type == selectedType.toLowerCase()).toList();
  }

  final types = ["Tous", "livre", "film", "série"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F3FF),
        elevation: 0,
        title: Text(
          "Lectures / Films / Séries",
          style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton.icon(
              onPressed: () {
                showAjouterMediaDialog(context);
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text("Ajouter"),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFA78BFA),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                textStyle: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "Gardez une trace de vos lectures, films et séries préférés.",
                    style: GoogleFonts.quicksand(
                        fontWeight: FontWeight.w500, color: const Color(0xFF838FA2)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: types.map((type) {
                final isSelected = selectedType == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: TextButton(
                    onPressed: () => setState(() => selectedType = type),
                    child: Text(type[0].toUpperCase() + type.substring(1)),
                    style: TextButton.styleFrom(
                      backgroundColor: isSelected ? Colors.white : const Color(0xFFF1F5F9),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      textStyle: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: filteredItems.length,
                itemBuilder: (context, index) {
                  final item = filteredItems[index];
                  return _buildMediaCard(item);
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type.toLowerCase()) {
      case 'livre':
        return const Color(0xFFEAB308); // jaune
      case 'série':
        return Colors.green;
      case 'film':
      default:
        return const Color(0xFFA78BFA); // violet
    }
  }

  Widget _buildMediaCard(MediaItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Chip(
                label: Text(item.type, style: const TextStyle(color: Colors.white)),
                backgroundColor: _typeColor(item.type),
              ),
              Row(
                children: List.generate(
                  item.rating,
                      (index) => Icon(
                    Icons.star,
                    size: 18,
                    color: item.rating >= 4
                        ? Colors.amber
                        : item.rating == 3
                        ? Colors.orange
                        : Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(item.title,
              style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 6),
          Text(
            item.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.quicksand(color: const Color(0xFF475569), fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black,
                  textStyle: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
                ),
                child: const Text("Voir les détails"),
              ),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
                ),
                child: const Text("Modifier"),
              ),
            ],
          )
        ],
      ),
    );
  }
}