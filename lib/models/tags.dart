class Tag {
  final String id;
  final String nom;
  final String userId;

  Tag({
    required this.id,
    required this.nom,
    required this.userId,
  });

  factory Tag.fromMap(Map<String, dynamic> map) {
    return Tag(
      id: map['id'],
      nom: map['nom'],
      userId: map['user_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'user_id': userId,
    };
  }
}


class JournalTag {
  final String journalId;
  final String tagId;

  JournalTag({
    required this.journalId,
    required this.tagId,
  });

  factory JournalTag.fromMap(Map<String, dynamic> map) {
    return JournalTag(
      journalId: map['journal_id'],
      tagId: map['tag_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'journal_id': journalId,
      'tag_id': tagId,
    };
  }
}
