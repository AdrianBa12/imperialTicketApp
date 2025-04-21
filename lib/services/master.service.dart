import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MasterService {
  static const String _apiURL = 'https://automatic-festival-37ec7cc8d8.strapiapp.com/api/';
  static const String _authURL = 'https://automatic-festival-37ec7cc8d8.strapiapp.com/api/auth/';
  static const String _apiPeruToken = '25222079ce57429371cf6d908d8b283966aad65f8e64caf50c2fff09a5727ce6';
  static const String _apiPeruUrl = 'https://apiperu.dev/api/dni/';

  
  static Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    debugPrint('Token: $token');
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    
  }

  Future<List<dynamic>> getProvincias() async {
  final response = await http.get(
    Uri.parse('https://automatic-festival-37ec7cc8d8.strapiapp.com/api/provincias?populate=*'),
  );

  if (response.statusCode == 200) {
    final Map<String, dynamic> data = json.decode(response.body);
    return data['data'];
  } else {
    throw Exception('Error al cargar provincias: ${response.statusCode}');
  }
}

  Future<dynamic> searchBus(int from, int to, String travelDate) async {
    final params = {
      'filters[terminalSalidaId][provinciaId][id][\$eq]': from.toString(),
      'filters[terminalLlegadaId][provinciaId][id][\$eq]': to.toString(),
      'filters[fechaDeSalida][\$gte]': DateTime.parse(travelDate).toIso8601String(),
      'filters[fechaDeSalida][\$lt]': DateTime.parse(travelDate).add(const Duration(days: 1)).toIso8601String(),
      'populate[0]': 'terminalSalidaId.provinciaId',
      'populate[1]': 'terminalLlegadaId.provinciaId',
      'populate[2]': 'bus',
      'populate[3]': 'conductor',
      'populate[4]': 'terminalSalidaId',
      'populate[5]': 'terminalLlegadaId',
    };

    final uri = Uri.parse('${_apiURL}horario-de-autobuses').replace(queryParameters: params);
    final response = await http.get(uri);
    return _handleResponse(response);
  }

  Future<dynamic> getScheduleById(String documentId) async {
    final response = await http.get(
      Uri.parse('${_apiURL}horario-de-autobuses/$documentId?populate=*'),
    );
    return _handleResponse(response);
  }

  Future<List<dynamic>> getAllBusBookings(int id) async {
    final response = await http.get(
      Uri.parse('${_apiURL}GetAllBusBookings?vendorId=$id'),
    );
    return _handleResponse(response);
  }

  Future<List<dynamic>> getBookedSeats(int id) async {
    final response = await http.get(
      Uri.parse('${_apiURL}getBookedSeats?scheduleId=$id'),
    );
    return _handleResponse(response);
  }

  Future<dynamic> onRegisterUser(Map<String, dynamic> obj) async {
    final userData = {
      'username': obj['userName'],
      'email': obj['emailId'],
      'fullName': obj['fullName'],
      'password': obj['password'],
      'role': '3',
    };

    final response = await http.post(
      Uri.parse('${_apiURL}users'),
      body: jsonEncode(userData),
      headers: {'Content-Type': 'application/json'},
    );
    return _handleResponse(response);
  }

  Future<dynamic> onBooking(Map<String, dynamic> obj) async {
    final response = await http.post(
      Uri.parse('${_apiURL}PostBusBooking'),
      body: jsonEncode(obj),
      headers: await _getAuthHeaders(),
    );
    return _handleResponse(response);
  }

  Future<dynamic> onRegisterVendor(Map<String, dynamic> obj) async {
    final response = await http.post(
      Uri.parse('${_apiURL}CreateVendor'),
      body: jsonEncode(obj),
      headers: await _getAuthHeaders(),
    );
    return _handleResponse(response);
  }

  Future<dynamic> onLogin(Map<String, dynamic> obj) async {
    final response = await http.post(
      Uri.parse('${_authURL}local'),
      body: jsonEncode({
        'identifier': obj['userName'],
        'password': obj['password'],
      }),
      headers: {'Content-Type': 'application/json'},
    );
    debugPrint('Respuesta completa: ${response.body}');
    debugPrint('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();

      final token = data['jwt']; 
      debugPrint('Token recibido: $token');

      await prefs.setString('jwt_token', token);
      final savedToken = prefs.getString('jwt_token');
      debugPrint('Token guardado: $savedToken');
      debugPrint('Token guardado en SharedPreferences: ${data['jwt']}');
    
    }
    return _handleResponse(response);
    
  }

  Future<dynamic> createSchedule(Map<String, dynamic> obj) async {
    final response = await http.post(
      Uri.parse('${_apiURL}PostBusSchedule'),
      body: jsonEncode(obj),
      headers: await _getAuthHeaders(),
    );
    return _handleResponse(response);
  }

  Future<dynamic> buscarPorDNI(String dni) async {
    final response = await http.get(
      Uri.parse('$_apiPeruUrl$dni'),
      headers: {'Authorization': 'Bearer $_apiPeruToken'},
    );
    return _handleResponse(response);
  }

  Future<dynamic> crearReserva(Map<String, dynamic> datosReserva) async {
    final response = await http.post(
      Uri.parse('${_apiURL}reservas'),
      body: jsonEncode({
        'data': {
          ...datosReserva,
          'usuario': datosReserva['usuario'],
        }
      }),
      headers: await _getAuthHeaders(),
    );
    return _handleResponse(response);
  }

  Future<dynamic> actualizarMapaAsientos(String documentId, List<dynamic> mapaAsientos) async {
    final response = await http.put(
      Uri.parse('${_apiURL}horario-de-autobuses/$documentId'),
      body: jsonEncode({
        'data': {
          'mapaDeAsientos': mapaAsientos,
        }
      }),
      headers: await _getAuthHeaders(),
    );
    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error: ${response.statusCode} - ${response.body}');
    }
  }
}