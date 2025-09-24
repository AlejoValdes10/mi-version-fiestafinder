import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool rememberMe = false;
  bool passwordVisible = false;

  // Función de login con email
  Future<void> _signInWithEmail() async {
    try {
      final email = emailController.text.trim();
      final password = passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Por favor, ingrese su correo y contraseña')),
        );
        return;
      }

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(userCredential.user!.uid)
              .get();

      if (!userDoc.exists) {
        _showEmailAccountAlert();
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(userCredential.user!),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        _showEmailAccountAlert();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al iniciar sesión: ${e.message}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al iniciar sesión: $e')));
    }
  }

  // Función de login con Google
  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(userCredential.user!.uid)
              .get();

      if (!userDoc.exists) {
        _showGoogleAccountAlert();
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(userCredential.user!),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al iniciar sesión con Google: $e')),
      );
    }
  }

  // 🔐 Recuperar contraseña
  void _showForgotPasswordDialog() {
    final TextEditingController emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 30,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_reset_rounded,
                      size: 50,
                      color: Colors.deepPurple,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Recuperar contraseña',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Escribe tu correo y te enviaremos un enlace para restablecerla.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El correo es obligatorio';
                        }
                        final emailRegex = RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        );
                        if (!emailRegex.hasMatch(value.trim())) {
                          return 'Correo inválido';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.email_outlined),
                        hintText: 'Correo electrónico',
                        filled: true,
                        fillColor: Color(0xFFF3F4F6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    SizedBox(height: 25),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Cancelar',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed:
                                isLoading
                                    ? null
                                    : () async {
                                      if (formKey.currentState!.validate()) {
                                        setModalState(() => isLoading = true);

                                        final email =
                                            emailController.text.trim();

                                        try {
                                          // Intentar enviar el correo de recuperación directamente
                                          await FirebaseAuth.instance
                                              .sendPasswordResetEmail(
                                                email: email,
                                              );

                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Te enviamos un correo para recuperar tu contraseña',
                                              ),
                                            ),
                                          );
                                        } catch (e) {
                                          setModalState(
                                            () => isLoading = false,
                                          );
                                          print(
                                            'Error al recuperar la contraseña: $e',
                                          );
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Error: ${e.toString()}',
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child:
                                isLoading
                                    ? SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                    : Text('Enviar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Alertas
  void _showGoogleAccountAlert() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('¡Cuenta no encontrada!'),
            content: Text(
              'No hay una cuenta creada con esta cuenta de Google.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RegisterScreen()),
                  );
                },
                child: Text('Registrarse'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancelar'),
              ),
            ],
          ),
    );
  }

  void _showEmailAccountAlert() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('¡Cuenta no encontrada!'),
            content: Text(
              'No hay una cuenta creada con este correo electrónico.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RegisterScreen()),
                  );
                },
                child: Text('Registrarse'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancelar'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(
        255,
        255,
        255,
        255,
      ), // <-- Aquí puedes definir el color que prefieras
      body: LayoutBuilder(
        builder:
            (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('assets/ff.png', height: 100),
                        SizedBox(height: 20),
                        Text(
                          'Iniciar Sesión',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 30),
                        TextField(
                          controller: emailController,
                          decoration: InputDecoration(
                            labelText: 'Correo electrónico',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                        ),
                        SizedBox(height: 15),
                        TextField(
                          controller: passwordController,
                          obscureText: !passwordVisible,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                passwordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.black,
                              ),
                              onPressed: () {
                                setState(() {
                                  passwordVisible = !passwordVisible;
                                });
                              },
                            ),
                          ),
                        ),

                        // 🔐 Botón de recuperar contraseña
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _showForgotPasswordDialog,
                            child: Text(
                              '¿Olvidaste tu contraseña?',
                              style: TextStyle(color: Colors.blue),
                            ),
                          ),
                        ),

                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Recordarme'),
                            Switch(
                              value: rememberMe,
                              onChanged: (bool value) {
                                setState(() {
                                  rememberMe = value;
                                });
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 10),

                        // 🔧 ===== BOTONES TEMPORALES DE PRUEBA DE LOGIN ===== 🔧
                        // 🔴 ELIMINA ESTO DESPUÉS DE LAS PRUEBAS 🔴
                        Column(
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  emailController.text = 'cristian@gmail.com';
                                  passwordController.text = 'Fiestafinder123';
                                });
                                _signInWithEmail();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              child: Text('Login EMPRESARIO'),
                            ),
                            SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  emailController.text = 'admin@admin.com';
                                  passwordController.text = 'Fiestafinder123';
                                });
                                _signInWithEmail();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              child: Text('Login ADMINISTRADOR'),
                            ),
                            SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  emailController.text =
                                      'jersonusuario@gmail.com';
                                  passwordController.text = 'Jersonusuario123';
                                });
                                _signInWithEmail();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              child: Text('Login USUARIO'),
                            ),
                          ],
                        ),
                        // 🔧 ===== FIN BOTONES TEMPORALES DE PRUEBA ===== 🔧
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _signInWithEmail,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromARGB(255, 39, 48, 176),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: 80,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: Text(
                            'INGRESAR',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                        SizedBox(height: 20),
                        Text('También puedes iniciar sesión con ...'),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: _signInWithGoogle,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white, // Fondo blanco
                                foregroundColor:
                                    Colors.black, // Color del texto
                                padding: EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 24,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 5, // Sombra sutil
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    'assets/google.png', // Asegúrate de que el archivo esté en assets
                                    width: 28,
                                    height: 28,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Continuar con Google',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 20),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RegisterScreen(),
                              ),
                            );
                          },
                          child: Text(
                            '¿No tienes cuenta? Regístrate',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        SizedBox(height: constraints.maxHeight * 0.1),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      ),
    );
  }
}
