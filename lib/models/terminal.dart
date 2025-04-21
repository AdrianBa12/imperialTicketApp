import 'package:imperialticketapp/models/provincia.dart';

class Terminal {
  final int id;
  final String documentId;
  final String nombreTerminal;
  final String direccion;
  final Provincia provinciaId;

  Terminal({
    required this.id,
    required this.documentId,
    required this.nombreTerminal,
    required this.direccion,
    required this.provinciaId,
  });

   factory Terminal.fromJson(Map<String, dynamic> json) {
    final attributes = json['attributes'];
    return Terminal(
      id: json['id'],
      nombreTerminal: attributes['nombreTerminal'] ?? '',
      direccion: attributes['direccion'] ?? '',
      provinciaId: Provincia.fromJson(json['provinciaId']),
      documentId: json['id'].toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'documentId': documentId,
      'nombreTerminal': nombreTerminal,
      'direccion': direccion,
      
    };
  }
}


