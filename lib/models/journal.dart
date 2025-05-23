class Journal {
  final String id;
  final String titre;
  final Map<String, dynamic> contenu; // Delta JSON
  final DateTime dateCreation;
  final DateTime dateModification;
  final String userId;
  final String? resume;
  final bool favori;
  final bool archived;
  final int version;
  final bool isShared;

  Journal({
    required this.id,
    required this.titre,
    required this.contenu,
    required this.dateCreation,
    required this.dateModification,
    required this.userId,
    this.resume,
    this.favori = false,
    this.archived = false,
    this.version = 1,
    this.isShared = false,
  });

  factory Journal.fromMap(Map<String, dynamic> map) {
    return Journal(
      id: map['id'],
      titre: map['titre'],
      contenu: Map<String, dynamic>.from(map['contenu']),
      dateCreation: DateTime.parse(map['date_creation']),
      dateModification: DateTime.parse(map['date_modification']),
      userId: map['user_id'],
      resume: map['resume'],
      favori: map['favori'] ?? false,
      archived: map['archived'] ?? false,
      version: map['version'] ?? 1,
      isShared: map['is_shared'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titre': titre,
      'contenu': contenu,
      'date_creation': dateCreation.toIso8601String(),
      'date_modification': dateModification.toIso8601String(),
      'user_id': userId,
      'resume': resume,
      'favori': favori,
      'archived': archived,
      'version': version,
      'is_shared': isShared,
    };
  }
}
