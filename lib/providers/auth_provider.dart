import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../services/secure_service.dart';
import 'package:firebase_storage/firebase_storage.dart';


class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final SecureStorage _secureStorage = SecureStorage();

  User? _firebaseUser;
  UserModel? _userModel;
  String? _authToken;
  bool _isLoading = false;
  String? _error;


  User? get firebaseUser => _firebaseUser;
  UserModel? get userModel => _userModel;


  String? get authToken => _authToken;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _firebaseUser != null;
  bool get hasValidToken => _authToken != null && !_isTokenExpired(_authToken!);

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      _firebaseUser = user;
      if (user != null) {
        await _updateUserData(user.uid);
      } else {
        await _clearSession();
      }
      notifyListeners();
    });
  }
  Future<void> _updateUserData(String uid) async {
    try {
      _authToken = await _firebaseUser!.getIdToken();
      _userModel = await _authService.getUserData();
      if (_authToken != null) {
        await _secureStorage.saveToken(_authToken!);
      }
    } catch (e) {
      debugPrint('Error updating user data: $e');
      await _clearSession();
    }
  }

  Future<void> _clearSession() async {
    _authToken = null;
    _userModel = null;
    await _secureStorage.deleteToken();
    notifyListeners();
  }







  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    try {
      await _authService.signInWithEmailAndPassword(email, password);
      return true;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return false;
    } catch (e) {
      _setError('Error inesperado: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }


  Future<void> signOut() async {
    await _authService.signOut();
    await _clearSession();
  }


  Future<String?> get freshToken async {
    if (_firebaseUser == null) return null;
    _authToken = await _firebaseUser!.getIdToken(true);
    return _authToken;
  }



  Future<bool> register(String email, String password, String displayName, String? phoneNumber) async {
    _setLoading(true);
    try {
      await _authService.registerWithEmailAndPassword(
          email, password, displayName, phoneNumber
      );
      return true;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return false;
    } catch (e) {
      _setError('Error al registrar: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }



  Future<String?> get validToken async {
    if (_firebaseUser == null) return null;
    if (_authToken != null && !_isTokenExpired(_authToken!)) {
      return _authToken;
    }
    return await _firebaseUser!.getIdToken(true);
  }

  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      final payload = json.decode(utf8.decode(base64Url.decode(parts[1])));
      final exp = payload['exp'] as int;
      return exp <= DateTime.now().millisecondsSinceEpoch ~/ 1000;
    } catch (e) {
      return true;
    }
  }




  Future<bool> sendPasswordReset(String email) async {
    _setLoading(true);
    _error = null;

    try {
      await _authService.sendPasswordResetEmail(email);
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return false;
    } catch (e) {
      _setError('Se produjo un error inesperado. Inténtalo de nuevo.');
      return false;
    }
  }

  Future<bool> updateProfile({
    String? displayName,
    String? phoneNumber,
    File? profileImage, // Changed to File?
  }) async {
    _setLoading(true);
    _error = null;

    try {
      String? photoUrl;
      if (profileImage != null) {
        // Upload the image to Firebase Storage
        final user = FirebaseAuth.instance.currentUser; // Get current user
        if (user != null) {
          final ref = FirebaseStorage.instance
              .ref()
              .child('users/${user.uid}/profile.jpg'); // Storage path
          await ref.putFile(profileImage);
          photoUrl = await ref.getDownloadURL();
        }
      }

      await _authService.updateUserProfile(
        displayName: displayName,
        phoneNumber: phoneNumber,
        photoURL: photoUrl, // Pass the download URL
      );

      // Refresh user data
      _userModel = await _authService.getUserData();

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('No se pudo actualizar el perfil. Inténtalo de nuevo.');
      return false;
    }
  }

  void _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        _setError('Ninguna usuario encontrada con este correo electrónico.');
        break;
      case 'wrong-password':
        _setError('Contraseña incorrecta. Inténtalo de nuevo.');
        break;
      case 'email-already-in-use':
        _setError('El correo electrónico ya está en uso. Utilice otro.');
        break;
      case 'weak-password':
        _setError('La contraseña es demasiado débil. Utilice una más segura.');
        break;
      case 'invalid-email':
        _setError('Dirección de correo electrónico no válida.');
        break;
      default:
        _setError('Error de autenticación: ${e.message}');
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}