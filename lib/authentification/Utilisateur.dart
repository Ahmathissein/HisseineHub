class Utilisateur {
  final String id;
  final String email;
  final String? nom;
  final String? prenom;
  final String? photoUrl;

  Utilisateur({
    required this.id,
    required this.email,
    this.nom,
    this.prenom,
    this.photoUrl,
  });

  // Factory pour convertir depuis une ligne Supabase
  factory Utilisateur.fromMap(Map<String, dynamic> data) {
    return Utilisateur(
      id: data['id'],
      email: data['email'],
      nom: data['nom'],
      prenom: data['prenom'],
      photoUrl: data['photo_url'],
    );
  }

  // Pour convertir vers une Map lors d’un insert/update
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'nom': nom,
      'prenom': prenom,
      'photo_url': photoUrl,
    };
  }
}
