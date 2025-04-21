class Bus {
  final int id;
  final String documentId;
  final String placa;
  final int totalAsientos;

  Bus({
    required this.id,
    required this.documentId,
    required this.placa,
    required this.totalAsientos,
  });

  factory Bus.fromJson(Map<String, dynamic> json) {
    return Bus(
      id: json['id'],
      documentId: json['documentId'],
      placa: json['attributes']['placa'],
      totalAsientos: json['attributes']['totalAsientos'],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'documentId': documentId,
      'placa': placa,
      'totalAsientos': totalAsientos,
    };
  }
}

  