import 'package:flutter/foundation.dart';

class StrapiUserModel {
  final int id;
  final String documentId;
  final String username;
  final String email;
  final String provider;
  final bool confirmed;
  final bool blocked;
  final String? fullName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime publishedAt;
  final List<dynamic> reservas;
  final String? photoURL;

  StrapiUserModel({
    required this.id,
    required this.documentId,
    required this.username,
    required this.email,
    required this.provider,
    required this.confirmed,
    required this.blocked,
    required this.createdAt,
    required this.updatedAt,
    required this.publishedAt,
    required this.reservas,
    this.photoURL,
    this.fullName,
  });

  factory StrapiUserModel.fromJson(Map<String, dynamic> json) {
    
    String? photoURL;
  if (json['photoURL'] != null) {
    if (json['photoURL'] is Map) {
      photoURL = json['photoURL']['url']?.toString();
    } else {
      photoURL = json['photoURL'].toString();
      if (!photoURL.startsWith('http')) {
        photoURL = 'https://automatic-festival-37ec7cc8d8.strapiapp.com$photoURL';
      }
    }
  }
    return StrapiUserModel(
      id: json['id'] as int? ?? 0,
      documentId: json['documentId'],
      username: json['username']as String? ?? '',
      email: json['email']as String? ?? '',
      provider: json['provider']as String? ?? 'local',
      confirmed: json['confirmed']as bool? ?? false,
      blocked: json['blocked']as bool? ?? false,
      fullName: json['fullName']as String? ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      publishedAt: json['publishedAt'] != null ? DateTime.parse(json['publishedAt']) : DateTime.now(),
      reservas: json['reservas'] ?? [],
      photoURL: _parsePhotoUrl(json['photoURL']),
    );
  }
  static String? _parsePhotoUrl(dynamic photoData) {
  if (photoData == null) return null;
  
  const baseUrl = 'https://automatic-festival-37ec7cc8d8.strapiapp.com';
  
  try {
    if (photoData is String) {
      if (photoData.startsWith('http')) return photoData;
      return photoData.startsWith('/') 
          ? baseUrl + photoData 
          : '$baseUrl/$photoData';
    }
    
    if (photoData is Map<String, dynamic>) {
      final url = photoData['url'] ?? photoData['data']?['attributes']?['url'];
      if (url != null && url is String) {
        return url.startsWith('http')
            ? url
            : '$baseUrl${url.startsWith('/') ? url : '/$url'}';
      }
    }
  } catch (e) {
    debugPrint('Error parsing photoURL: $e');
  }
  
  return null;
}

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'documentId': documentId,
      'username': username,
      'email': email,
      'provider': provider,
      'confirmed': confirmed,
      'blocked': blocked,
      'fullName': fullName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'publishedAt': publishedAt.toIso8601String(),
      'reservas': reservas,
      'photoURL': photoURL,
    };
  }

  StrapiUserModel copyWith({
    int? id,
    String? documentId,
    String? username,
    String? email,
    String? provider,
    bool? confirmed,
    bool? blocked,
    String? fullName,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? publishedAt,
    List<dynamic>? reservas,
    String? photoURL,
  }) {
    return StrapiUserModel(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      username: username ?? this.username,
      email: email ?? this.email,
      provider: provider ?? this.provider,
      confirmed: confirmed ?? this.confirmed,
      blocked: blocked ?? this.blocked,
      fullName: fullName ?? this.fullName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      publishedAt: publishedAt ?? this.publishedAt,
      reservas: reservas ?? this.reservas,
      photoURL: photoURL ?? this.photoURL,
    );
  }
}