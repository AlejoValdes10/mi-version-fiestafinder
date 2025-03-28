import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:io' show Platform;

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: Platform.isAndroid
        ? null  // En Android, Firebase usa automáticamente la configuración de Google Sign-In
        : "815596252512-d4rstkhknss7emokcaq82krtqbcq2ag0.apps.googleusercontent.com", // 👈 Reemplázalo con tu ID de cliente web
    scopes: ['email'],
  );

  // 🔐 Iniciar sesión con Google
  static Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // El usuario canceló el inicio de sesión

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        // Guardar usuario en Firestore si es la primera vez que inicia sesión
        DocumentSnapshot doc =
            await _firestore.collection('usuarios').doc(user.uid).get();
        if (!doc.exists) {
          await _firestore.collection('usuarios').doc(user.uid).set({
            'nombre': user.displayName ?? 'Usuario sin nombre',
            'correo': user.email,
          });
        }
      }

      return user;
    } catch (e) {
      print("Error en Google Sign-In: $e");
      return null;
    }
  }

  // 🔐 Registrar usuario con correo y contraseña
  static Future<User?> registerUser(
      String name, String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
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

    User? user = userCredential.user;

    if (user != null) {
      // 🔐 Verificar si existe el documento
      DocumentSnapshot doc =
          await _firestore.collection('usuarios').doc(user.uid).get();

      if (!doc.exists) {
        await _firestore.collection('usuarios').doc(user.uid).set({
          'nombre': 'Usuario',
          'correo': user.email ?? '',
        });
        print("📄 Documento creado para el usuario");
      } else {
        print("✅ Documento ya existía");
      }
    }

    return user;
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
      // ignore: avoid_print
      print("Error al obtener datos del usuario: $e");
    }
    return null;
  }

  // 🚪 Cerrar sesión
  static Future<void> logout() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }
}
