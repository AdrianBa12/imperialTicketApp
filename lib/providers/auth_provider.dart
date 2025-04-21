import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'package:imperialticketapp/models/update_user_result.dart';
import 'package:imperialticketapp/models/upload_result.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/strapi_user_model.dart';
import '../services/secure_service.dart';

class AuthProvider with ChangeNotifier {
  final SecureStorage _secureStorage = SecureStorage();
  final String _baseUrl = 'https://automatic-festival-37ec7cc8d8.strapiapp.com';

  StrapiUserModel? _userModel;
  String? _authToken;
  String? _token;

  bool _isLoading = false;
  String? _error;
  String? _profileImageUrl;

  String? get profileImageUrl => _profileImageUrl;
  StrapiUserModel? get userModel => _userModel;
  String? get authToken => _authToken;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _authToken != null;

  AuthProvider() {
    loadToken();
    _loadUser();
  }

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('jwt_token');
    debugPrint("Token cargado en AuthProvider: $_token");
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token!);
    _token = token;
    notifyListeners();
  }

  Map<String, String> get authHeaders {
    if (_token == null) return {};
    return {'Authorization': 'Bearer $_token'};
  }

  Future<void> _loadUser() async {
    _setLoading(true);
    try {
      _authToken = await _secureStorage.getToken();
      if (_authToken != null) {
        _userModel = await _getUserData();

        _profileImageUrl = await _secureStorage.getProfileImageUrl();
        if (_profileImageUrl != null) {
          _userModel = _userModel?.copyWith(photoURL: _profileImageUrl);
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      _clearSession();
    } finally {
      _setLoading(false);
    }
  }

  Future<UploadResult> _uploadProfileImage(File imageFile) async {
    try {
      if (!await imageFile.exists()) {
        return UploadResult(
          success: false,
          errorMessage: 'El archivo de imagen no es accesible',
        );
      }

      final imageSize = await imageFile.length();
      if (imageSize > 5 * 1024 * 1024) {
        return UploadResult(
          success: false,
          errorMessage: 'La imagen es demasiado grande (máx 5MB)',
        );
      }

      final uri = Uri.parse('$_baseUrl/api/upload');
      final request =
          http.MultipartRequest('POST', uri)
            ..headers['Authorization'] = 'Bearer $_authToken'
            ..files.add(
              await http.MultipartFile.fromPath(
                'files',
                imageFile.path,
                filename:
                    'profile_${_userModel?.id}_${DateTime.now().millisecondsSinceEpoch}.jpg',
              ),
            );

      final response = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout:
            () =>
                throw TimeoutException(
                  'La subida de imagen está tardando demasiado',
                ),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final errorData = await response.stream.bytesToString();
        debugPrint(
          'Error al subir imagen: ${response.statusCode} - $errorData',
        );
        return UploadResult(
          success: false,
          errorMessage: 'Error al procesar la imagen',
        );
      }

      final responseData = await response.stream.bytesToString();
      final uploadedData = json.decode(responseData)[0];

      debugPrint('Imagen subida: ${uploadedData['url']}');

      return UploadResult(
        success: true,
        imageUrl: uploadedData['url'],
        mediaId: uploadedData['id'].toString(),
      );
    } on TimeoutException {
      return UploadResult(
        success: false,
        errorMessage: 'El servidor tardó demasiado en responder',
      );
    } catch (e) {
      debugPrint('Error en _uploadProfileImage: $e');
      return UploadResult(
        success: false,
        errorMessage: 'Error al subir la imagen',
      );
    }
  }

  Future<UpdateUserResult> _updateUserData(
    Map<String, dynamic> updateData,
  ) async {
    try {
      final response = await http
          .put(
            Uri.parse('$_baseUrl/api/users/${_userModel?.id}'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_authToken',
            },
            body: json.encode(updateData),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        debugPrint(
          'Error al actualizar usuario: ${response.statusCode} - ${errorData['error']?['message']}',
        );

        return UpdateUserResult(
          success: false,
          errorMessage:
              errorData['error']?['message'] ?? 'Error al guardar cambios',
        );
      }

      final updatedUser = json.decode(response.body);
      return UpdateUserResult(
        success: true,
        updatedUser: StrapiUserModel.fromJson(updatedUser),
      );
    } on TimeoutException {
      return UpdateUserResult(
        success: false,
        errorMessage: 'El servidor tardó demasiado en responder',
      );
    } catch (e) {
      debugPrint('Error en _updateUserData: $e');
      return UpdateUserResult(
        success: false,
        errorMessage: 'Error al actualizar el perfil',
      );
    }
  }

  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/local'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'identifier': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        await _secureStorage.saveToken(responseData['jwt']);
        _authToken = responseData['jwt'];
        // _userModel = StrapiUserModel.fromJson(responseData['user']);

        debugPrint('API Response: ${response.body}');
        final userData = responseData['user'];
        final photoUrl =
            userData['photoURL'] ??
            userData['photo']?.toString() ??
            userData['avatar']?.toString();

        debugPrint('Extracted photoURL: $photoUrl');

        _userModel = StrapiUserModel.fromJson(userData);
        if (_userModel?.photoURL == null) {
          _userModel = _userModel?.copyWith(
            photoURL: await _secureStorage.getProfileImageUrl(),
          );
        }
        _profileImageUrl = _userModel?.photoURL;
        notifyListeners();

        return true;
      } else {
        final errorData = json.decode(response.body);
        _setError(errorData['error']['message'] ?? 'Error al iniciar sesión');
        return false;
      }
    } catch (e) {
      _setError('Error de conexión: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    await _secureStorage.deleteToken();
    await _secureStorage.deleteProfileImageUrl();
    _clearSession();
  }

  Future<bool> register({
    required String email,
    required String password,
    required String username,
    required String fullName,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await http
          .post(
            Uri.parse(
              'https://automatic-festival-37ec7cc8d8.strapiapp.com/api/users',
            ),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'username': username,
              'email': email,
              'password': password,
              'fullName': fullName,
              'role': '3',
            }),
          )
          .timeout(const Duration(seconds: 15));
      debugPrint('Raw API Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        if (responseData['jwt'] == null) {
          return await _loginAfterRegister(email, password);
        }

        _authToken = responseData['jwt'];
        _userModel = StrapiUserModel.fromJson(responseData['user']);
        notifyListeners();

        return true;
      } else {
        _handleErrorResponse(response);
        return false;
      }
    } on TimeoutException {
      _setError('El servidor no respondió a tiempo');
      return false;
    } on SocketException {
      _setError('Problema de conexión. Verifica tu internet');
      return false;
    } catch (e, stackTrace) {
      debugPrint('Registration Error: $e\n$stackTrace');
      _setError('Error durante el registro: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> _loginAfterRegister(String email, String password) async {
    try {
      final loginResponse = await http.post(
        Uri.parse(
          'https://automatic-festival-37ec7cc8d8.strapiapp.com/api/users',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'identifier': email, 'password': password}),
      );

      if (loginResponse.statusCode == 200) {
        final loginData = json.decode(loginResponse.body);
        _authToken = loginData['jwt'];
        _userModel = StrapiUserModel.fromJson(loginData['user']);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error en login post-registro: $e');
      return false;
    }
  }

  void _handleErrorResponse(http.Response response) {
    try {
      final errorData = json.decode(response.body);

      if (errorData['error'] != null) {
        final error = errorData['error'];
        _setError(
          error is Map
              ? error['message'] ?? error.toString()
              : error.toString(),
        );
        return;
      }

      _setError(
        errorData['message'] ?? 'Error en el registro (${response.statusCode})',
      );
    } catch (e) {
      _setError(
        'Error procesando la respuesta del servidor (${response.statusCode})',
      );
    }
  }

  String _parseDioError(dynamic error) {
    if (error is String) return error;
    if (error is http.Response) {
      return 'Error del servidor (${error.statusCode})';
    }
    return error.toString().replaceAll('Exception: ', '');
  }

  Future<bool> sendPasswordReset(String email) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final errorData = json.decode(response.body);
        _setError(
          errorData['error']['message'] ??
              'Error al enviar el correo de recuperación',
        );
        return false;
      }
    } catch (e) {
      _setError('Error de conexión: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProfile({
    required String? fullName,
    required File? profileImage,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      String? newImageUrl;

      if (profileImage != null) {
        final uploadResponse = await http.MultipartRequest(
            'POST',
            Uri.parse('$_baseUrl/api/upload'),
          )
          ..files.add(
            await http.MultipartFile.fromPath('files', profileImage.path),
          );

        final response = await uploadResponse.send();
        final responseData = await response.stream.bytesToString();

        if (response.statusCode == 200) {
          final uploadedData = json.decode(responseData);
          newImageUrl = '$_baseUrl${uploadedData[0]['url']}';
          await _secureStorage.saveProfileImageUrl(newImageUrl);
        }
      }

      final updateResponse = await http.put(
        Uri.parse('$_baseUrl/api/users/${_userModel?.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: json.encode({
          'fullName': fullName,
          if (newImageUrl != null) 'photoURL': newImageUrl,
        }),
      );

      if (updateResponse.statusCode == 200) {
        final updatedUser = json.decode(updateResponse.body);
        _userModel = StrapiUserModel.fromJson(updatedUser);
        notifyListeners();
        return true;
      }
    } catch (e) {
      _setError('Error: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
    return false;
  }

  Future<StrapiUserModel?> _getUserData() async {
    if (_authToken == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/users/me'),
        headers: {'Authorization': 'Bearer $_authToken'},
      );

      if (response.statusCode == 200) {
        return StrapiUserModel.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      return null;
    }
  }

  void _clearSession() {
    _authToken = null;
    _userModel = null;
    _profileImageUrl = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void setError(String error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _parseUploadedImageUrl(dynamic uploadedData) {
    if (uploadedData is Map) {
      return uploadedData['url']?.toString() ??
          uploadedData['data']?['attributes']?['url']?.toString() ??
          '';
    }
    return uploadedData.toString();
  }

  String _parseErrorMessage(dynamic errorData) {
    try {
      if (errorData is Map) {
        return errorData['error']?['message'] ??
            errorData['message'] ??
            errorData['error']?.toString() ??
            'Error desconocido en el registro';
      }
      return errorData.toString();
    } catch (e) {
      return 'Error procesando la respuesta del servidor';
    }
  }
}
