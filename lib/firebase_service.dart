import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔐 Registrar usuario en Firebase Authentication y guardar en Firestore
  static Future<User?> registerUser(
    String name,
    String email,
    String password,
  ) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password.trim(),
          );

      User? user = userCredential.user;
      if (user != null) {
        await _firestore.collection('usuarios').doc(user.uid).set({
          'nombre': name.trim(),
          'correo': email.trim(),
        });
      }
      return user;
    } catch (e) {
      print("Error al registrar usuario: $e");
      return null;
    }
  }

  // 🔑 Iniciar sesión con correo y contraseña
  static Future<User?> loginUser(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return userCredential.user;
    } catch (e) {
      print("Error al iniciar sesión: $e");
      return null;
    }
  }

  // 🔍 Obtener datos del usuario autenticado
  static Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('usuarios').doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
    } catch (e) {
      print("Error al obtener datos del usuario: $e");
    }
    return null;
  }

  // 🚪 Cerrar sesión
  static Future<void> logout() async {
    await _auth.signOut();
  }
}
