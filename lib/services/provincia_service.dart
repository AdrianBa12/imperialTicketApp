import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:imperialticketapp/models/provincia.dart';
import 'api_services.dart';

class ProvinciaService {
  static Future<List<Provincia>> getProvincias() async {
    try {
      final response = await http
          .get(Uri.parse('${ApiService.baseUrl}/provincias'), headers: ApiService.headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data == null || data['data'] == null) return [];

        return (data['data'] as List)
            .map((json) => Provincia.fromJson(json))
            .where((p) => p.id != -1)
            .toList();
      } else {
        throw Exception('Failed to load provinces: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getProvinces: $e');
      return [];
    }
  }
}