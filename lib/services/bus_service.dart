import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:imperialticketapp/models/horario_de_autobus.dart';
import 'api_services.dart';

class BusService {
  static Future<List<HorarioAutobus>> searchByProvinces({
  required int originProvinceId,
  required int destinationProvinceId,
  required DateTime date,
}) async {
  try {
    final startOfDay = DateTime(date.year, date.month, date.day).toUtc();
    final endOfDay = startOfDay.add(Duration(days: 1)).subtract(Duration(milliseconds: 1));
    final formattedStart = startOfDay.toIso8601String();
    final formattedEnd = endOfDay.toIso8601String();

    final uri = Uri.parse('${ApiService.baseUrl}/horario-de-autobuses').replace(queryParameters: {
      'filters[terminalSalida][provinciaId][id][\$eq]': originProvinceId.toString(),
      'filters[terminalLlegada][provinciaId][id][\$eq]': destinationProvinceId.toString(),
      'filters[fechaDeSalida][\$between][0]': formattedStart,
      'filters[fechaDeSalida][\$between][1]': formattedEnd,
      'populate[terminalSalida][populate]': 'provinciaId',
      'populate[terminalLlegada][populate]': 'provinciaId',
      'populate[bus]': '*',
      'populate[conductor]': '*',
      'populate': 'mapaDeAsientos',
    });

    final response = await http.get(uri, headers: ApiService.headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['data'] == null) return [];

      return (data['data'] as List)
          .map((json) => HorarioAutobus.fromJson(json))
          .toList();
    } else {
      throw Exception('Error al buscar horarios: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('Error en searchByProvinces: $e');
    throw Exception('Error de conexión: $e');
  }
}

}