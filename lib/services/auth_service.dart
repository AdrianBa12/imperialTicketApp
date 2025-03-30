import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:imperialticketapp/services/secure_service.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  Stream<User?> get authStateChanges => _auth.authStateChanges();


  User? get currentUser => _auth.currentUser;


  Future<String> signInWithEmailAndPassword(String email, String password) async {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );


    final token = await _getJwtTokenFromBackend(userCredential.user!.uid);
    await SecureStorage.storeToken(token);
    return token;
  }

  Future<String?> getFirebaseToken() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return await user.getIdToken();
    }
    return null;
  }
  Future<void> fetchProtectedData() async {
    String? token = await getFirebaseToken();
    if (token == null) {
      print("No se pudo obtener el token de Firebase");
      return;
    }

    var response = await http.get(
      Uri.parse("http://192.168.101.5:5000/api/protected-route"),
      headers: {
        "Authorization": "Bearer $token",  // Enviamos el token en el header
      },
    );

    if (response.statusCode == 200) {
      print("Datos recibidos: ${response.body}");
    } else {
      print("Error: ${response.body}");
    }
  }


  Future<String> _getJwtTokenFromBackend(String uid) async {
    final response = await http.post(
      Uri.parse('http://192.168.101.5:5000/api/generate-token'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'uid': uid}),
    ).timeout(Duration(seconds: 10), onTimeout: () {
      throw Exception('Tiempo de espera agotado al conectar con el servidor.');
    });

    if (response.statusCode == 200) {
      return json.decode(response.body)['token'];
    } else {
      throw Exception('Error al obtener el token JWT');
    }
  }


  Future<UserCredential?> registerWithEmailAndPassword(
      String email, String password, String displayName, String? phoneNumber) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);

      final user = userCredential.user;
      if (user == null) throw Exception("Error al crear usuario.");

      await user.updateDisplayName(displayName);
      await user.sendEmailVerification();

      await _createUserDocument(user, displayName, phoneNumber);

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthError(e));
    }
  }

  Future<void> _createUserDocument(User user, String displayName, String? phoneNumber) async {
    final userModel = UserModel(
      uid: user.uid,
      email: user.email!,
      displayName: displayName,
      phoneNumber: phoneNumber,
      recentSearches: [],
      favoriteRoutes: [],
    );

    await _firestore.collection('users').doc(user.uid).set(userModel.toJson());
  }

  Future<UserModel?> getUserData() async {
    if (currentUser == null) return null;
    try {
      final doc = await _firestore.collection('users').doc(currentUser!.uid).get();
      if (!doc.exists) return null;
      return UserModel.fromJson(doc.data()!);
    } catch (e) {
      debugPrint('Error obteniendo datos de usuario: $e');
      return null;
    }
  }

  Future<void> updateUserProfile({String? displayName, String? phoneNumber, String? photoURL}) async {
    if (currentUser == null) return;

    try {
      final updates = <String, dynamic>{};

      if (displayName != null) {
        await currentUser!.updateDisplayName(displayName);
        updates['displayName'] = displayName;
      }

      if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
      if (photoURL != null) {
        await currentUser!.updatePhotoURL(photoURL);
        updates['photoURL'] = photoURL;
      }

      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(currentUser!.uid).update(updates);
      }

      await _auth.currentUser?.reload();
    } catch (e) {
      debugPrint('Error actualizando perfil: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'El correo electrónico no es válido.';
      case 'user-disabled':
        return 'Este usuario ha sido deshabilitado.';
      case 'user-not-found':
        return 'No se encontró ninguna cuenta con este correo.';
      case 'wrong-password':
        return 'Contraseña incorrecta.';
      case 'email-already-in-use':
        return 'Este correo ya está registrado.';
      case 'weak-password':
        return 'La contraseña es demasiado débil.';
      default:
        return 'Error desconocido. Intenta nuevamente.';
    }
  }
}
