class TacheProjet {
  final String nom;
  bool fait;

  TacheProjet({
    required this.nom,
    this.fait = false,
  });

  factory TacheProjet.fromJson(Map<String, dynamic> json) {
    return TacheProjet(
      nom: json['nom'],
      fait: json['fait'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'fait': fait,
    };
  }
}


class Projet {
  final String id;
  final String nom;
  final String description;
  final String priorite;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final DateTime? creeLe;
  final List<TacheProjet> taches;

  Projet({
    required this.id,
    required this.nom,
    required this.description,
    required this.priorite,
    this.dateDebut,
    this.dateFin,
    this.creeLe,
    this.taches = const [],
  });

  factory Projet.fromJson(Map<String, dynamic> json) {
    return Projet(
      id: json['id'],
      nom: json['nom'],
      description: json['description'] ?? '',
      priorite: json['priorite'] ?? 'moyenne',
      dateDebut: json['date_debut'] != null ? DateTime.parse(json['date_debut']) : null,
      dateFin: json['date_fin'] != null ? DateTime.parse(json['date_fin']) : null,
      creeLe: json['cree_le'] != null ? DateTime.parse(json['cree_le']) : null,
      taches: (json['taches_projet'] as List<dynamic>?)
          ?.map((e) => TacheProjet.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'description': description,
      'priorite': priorite,
      'date_debut': dateDebut?.toIso8601String(),
      'date_fin': dateFin?.toIso8601String(),
      'cree_le': creeLe?.toIso8601String(),
      'taches': taches.map((t) => t.toJson()).toList(),
    };
  }
}
