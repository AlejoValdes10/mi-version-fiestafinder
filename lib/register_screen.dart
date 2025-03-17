import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  RegisterScreenState createState() => RegisterScreenState();
}

class RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController documentNumberController =
      TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nitController = TextEditingController();

  String documentType = 'Cédula';
  String personType = 'Usuario';
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isEmailValid(String email) {
    return RegExp(
      r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
    ).hasMatch(email);
  }

  bool _isPasswordValid(String password) {
    return RegExp(r"^(?=.*[A-Z])(?=.*\d).{6,}$").hasMatch(password);
  }

  bool _isNumeric(String str) {
    return RegExp(r'^[0-9]+$').hasMatch(str);
  }

  Future<void> _register() async {
    if (!_isEmailValid(emailController.text)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Correo inválido')));
      return;
    }
    if (!_isPasswordValid(passwordController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Contraseña inválida: Debe tener al menos 6 caracteres, una mayúscula y un número.',
          ),
        ),
      );
      return;
    }
    if (!_isNumeric(documentNumberController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El número de documento debe contener solo números.'),
        ),
      );
      return;
    }
    if (personType == 'Empresario' && !_isNumeric(nitController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El NIT debe contener solo números.')),
      );
      return;
    }

    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      await _firestore
          .collection('usuarios')
          .doc(userCredential.user!.uid)
          .set({
            'nombre': nameController.text.trim(),
            'correo': emailController.text.trim(),
            'tipoDocumento': documentType,
            'numeroDocumento': documentNumberController.text.trim(),
            'tipoPersona': personType,
            if (personType == 'Empresario') 'NIT': nitController.text.trim(),
          });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(userCredential.user!),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al registrarse: $e')));
    }
  }

  Future<void> _registerWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      await _firestore
          .collection('usuarios')
          .doc(userCredential.user!.uid)
          .set({
            'nombre': userCredential.user?.displayName ?? '',
            'correo': userCredential.user?.email ?? '',
          });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(userCredential.user!),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrarse con Google: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(20.0),
          width: 400,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 2),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/ff.png', height: 100),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Nombre'),
              ),
              TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'Correo'),
                keyboardType: TextInputType.emailAddress,
              ),
              DropdownButtonFormField<String>(
                value: documentType,
                items:
                    ['Cédula', 'Cédula extranjera']
                        .map(
                          (type) =>
                              DropdownMenuItem(value: type, child: Text(type)),
                        )
                        .toList(),
                onChanged: (value) {
                  setState(() {
                    documentType = value!;
                  });
                },
                decoration: InputDecoration(labelText: 'Tipo de documento'),
              ),
              TextField(
                controller: documentNumberController,
                decoration: InputDecoration(labelText: 'Número de documento'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(labelText: 'Contraseña'),
                obscureText: true,
              ),
              DropdownButtonFormField<String>(
                value: personType,
                items:
                    ['Usuario', 'Empresario']
                        .map(
                          (type) =>
                              DropdownMenuItem(value: type, child: Text(type)),
                        )
                        .toList(),
                onChanged: (value) {
                  setState(() {
                    personType = value!;
                  });
                },
                decoration: InputDecoration(labelText: 'Tipo de persona'),
              ),
              if (personType == 'Empresario')
                TextField(
                  controller: nitController,
                  decoration: InputDecoration(labelText: 'NIT de la empresa'),
                  keyboardType: TextInputType.number,
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _register,
                child: const Text('Registrarse'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _registerWithGoogle,
                child: const Text('Registrarse con Google'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
