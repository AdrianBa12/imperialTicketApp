import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:imperialticketapp/services/secure_service.dart';
import '../models/strapi_user_model.dart';

class AuthService {
  final SecureStorage _secureStorage = SecureStorage();
  String? _authToken;
  static const String baseUrl = 'https://automatic-festival-37ec7cc8d8.strapiapp.com';

  Future<StrapiUserModel> getUserData() async {
    _authToken = await _secureStorage.getToken();
    final response = await http.get(
      Uri.parse('https://automatic-festival-37ec7cc8d8.strapiapp.com/api/users/me?populate=*'),
      headers: {
        'Authorization': 'Bearer $_authToken',
      },
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return StrapiUserModel.fromJson(jsonData);
    } else {
      throw Exception('Error al obtener los datos del usuario: ${response.body}');
    }
  }

  Future<void> updateUserProfile({String? fullName, String? photoURL}) async {
    _authToken = await _secureStorage.getToken();
    final response = await http.put(
      Uri.parse('https://automatic-festival-37ec7cc8d8.strapiapp.com/api/users/me'),
      headers: {
        'Authorization': 'Bearer $_authToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'fullName': fullName, 
        'photoURL': photoURL,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al actualizar el perfil: ${response.body}');
    }
  }

  Future<StrapiUserModel> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
    required String fullName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'username': username,
          'email': email,
          'password': password,
          'fullName': fullName,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return StrapiUserModel.fromJson({
          ...responseData['user'],
          'documentId': responseData['user']['id'].toString(),
          'publishedAt': responseData['user']['createdAt'], // Usar createdAt si publishedAt no existe
          'reservas': [],
          'photoURL': null, // Valor por defecto
        });
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error']['message'] ?? 'Error en el registro');
      }
    } catch (e) {
      throw Exception('Error al registrar: ${e.toString()}');
    }
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    final response = await http.post(
      Uri.parse('https://automatic-festival-37ec7cc8d8.strapiapp.com/api/auth/local'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'identifier': email, 
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      _authToken = jsonData['jwt'];
      await _secureStorage.saveToken(_authToken!);
    } else {
      throw Exception('Error al iniciar sesión: ${response.body}');
    }
  }

  Future<void> signOut() async {
    await _secureStorage.deleteToken();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    final response = await http.post(
      Uri.parse('https://automatic-festival-37ec7cc8d8.strapiapp.com/api/auth/forgot-password'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al enviar el correo de restablecimiento: ${response.body}');
    }
  }

  signIn(String email, String password) {}
}
