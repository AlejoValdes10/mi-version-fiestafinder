import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  // Función para guardar un usuario en Firestore 🔥
  static Future<void> guardarUsuario(
    String nombre,
    String correo,
    String numIdentificacion,
    String tipoIdentificacion,
  ) async {
    try {
      DocumentReference docRef = await FirebaseFirestore.instance
          .collection('usuarios')
          .add({
            'nombre': nombre,
            'correo': correo,
            'num_identificación': numIdentificacion,
            'tipo_identificación': tipoIdentificacion,
          });

      print("Usuario agregado con ID: ${docRef.id}");
    } catch (e) {
      print("Error al agregar usuario: $e");
    }
  }
}
