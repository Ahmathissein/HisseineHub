class Evenement {
  final String id;
  final String userId;
  final String titre;
  final String description;
  final String categorie;
  final String lieu;
  final DateTime date;
  final String heureDebut;
  final String heureFin;

  Evenement({
    required this.id,
    required this.userId,
    required this.titre,
    required this.description,
    required this.categorie,
    required this.lieu,
    required this.date,
    required this.heureDebut,
    required this.heureFin,
  });

  factory Evenement.fromMap(Map<String, dynamic> map) {
    return Evenement(
      id: map['id'],
      userId: map['user_id'],
      titre: map['titre'],
      description: map['description'],
      categorie: map['categorie'],
      lieu: map['lieu'],
      date: DateTime.parse(map['date']), // ✅ convertit bien la string en DateTime
      heureDebut: map['heure_debut'],
      heureFin: map['heure_fin'],
    );
  }


  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'titre': titre,
      'description': description,
      'categorie': categorie,
      'lieu': lieu,
      'date': date.toIso8601String().split('T')[0],
      'heure_debut': heureDebut,
      'heure_fin': heureFin,
    };
  }
}
