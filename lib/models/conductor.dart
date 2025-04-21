class Conductor {
  final int id;
  final String documentId;
  final String nombreCompleto;

  Conductor({
    required this.id,
    required this.documentId,
    required this.nombreCompleto,
  });

  factory Conductor.fromJson(Map<String, dynamic> json) {
    return Conductor(
      id: json['id'],
      documentId: json['documentId'],
      nombreCompleto: json['attributes']['nombreCompleto'],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'documentId': documentId,
      'nombreCompleto': nombreCompleto,
    };
  }
}

