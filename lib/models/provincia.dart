import 'package:flutter/foundation.dart';

class Provincia {
  final int id;
  final String documentId;
  final String? nombreProvincia;
  final String code;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime publishedAt;

  Provincia({
    required this.id,
    required this.documentId,
    this.nombreProvincia,
    required this.code,
    required this.createdAt,
    required this.updatedAt,
    required this.publishedAt,
  });

  factory Provincia.fromJson(Map<String, dynamic> json) {
    debugPrint("Provincia json: $json");
    return Provincia(
      id: json['id'] as int,
      documentId: json['documentId'] as String,
      nombreProvincia: json['nombreProvincia'] as String?,
      code: json['code'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      publishedAt: DateTime.parse(json['publishedAt'] as String),
    );
  }
}

  



