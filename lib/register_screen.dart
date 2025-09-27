import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fiesta_finder/login_screen.dart';
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
  bool _obscurePassword = true;

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

      await _firestore.collection('usuarios').doc(userCredential.user!.uid).set(
        {
          'nombre': nameController.text.trim(),
          'correo': emailController.text.trim(),
          'tipoDocumento': documentType,
          'numeroDocumento': documentNumberController.text.trim(),
          'tipoPersona': personType, // Usuario o Empresario
          if (personType == 'Empresario') 'NIT': nitController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        },
      );

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
    await GoogleSignIn().signOut();
    bool shouldRegisterAsUser = false;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('¿Registrarse como Usuario?'),
          content: Text(
            'Si te registras con Google, serás registrado como Usuario. Si deseas registrarte como Empresario, debes llenar los datos adicionales.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                shouldRegisterAsUser = true;
              },
              child: Text('Registrar como Usuario'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                shouldRegisterAsUser = false;
              },
              child: Text('Cancelar'),
            ),
          ],
        );
      },
    );

    if (shouldRegisterAsUser) {
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
              'tipoPersona': 'Usuario',
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/ff.png', height: 90),
                      const SizedBox(height: 15),
                      const Text(
                        'Crear Cuenta',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(nameController, 'Nombre', Icons.person),
                      const SizedBox(height: 12),
                      _buildTextField(
                        emailController,
                        'Correo',
                        Icons.email,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),
                      _buildDropdown(
                        'Tipo de documento',
                        documentType,
                        ['Cédula', 'Cédula extranjera'],
                        (value) {
                          setState(() {
                            documentType = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        documentNumberController,
                        'Número de documento',
                        Icons.badge,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      // **Campo de contraseña con ojito**
                      _buildPasswordField(passwordController),
                      const SizedBox(height: 12),
                      _buildDropdown(
                        'Tipo de persona',
                        personType,
                        ['Usuario', 'Empresario', 'Administrador'],
                        (value) {
                          setState(() {
                            personType = value!;
                            if (value != 'Empresario') {
                              nitController.clear();
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      if (personType == 'Empresario')
                        _buildTextField(
                          nitController,
                          'NIT de la empresa',
                          Icons.business,
                          keyboardType: TextInputType.number,
                        ),
                      const SizedBox(height: 20),
                      _buildElevatedButton(
                        'Registrarse',
                        _register,
                        const Color.fromARGB(255, 39, 48, 176),
                      ),
                      const SizedBox(height: 20),
                      // Divisor con texto para el logo de Google
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: Colors.black54,
                                  thickness: 1,
                                  endIndent: 20,
                                ),
                              ),
                              const Text(
                                'Ó registrate con',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: Colors.black54,
                                  thickness: 1,
                                  indent: 20,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildGoogleButton(), // Botón con el logo de Google
                        ],
                      ),
                      const SizedBox(height: 15),
                      _buildLoginText(),
                      SizedBox(height: constraints.maxHeight * 0.1),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // **Campo de contraseña con el ojito**
  Widget _buildPasswordField(TextEditingController controller) {
    return TextFormField(
      controller: controller,
      obscureText: _obscurePassword,
      keyboardType: TextInputType.visiblePassword,
      style: const TextStyle(color: Colors.black87, fontSize: 14),
      decoration: InputDecoration(
        labelText: 'Contraseña',
        labelStyle: TextStyle(color: Colors.grey[600]),
        prefixIcon: const Icon(
          Icons.lock,
          color: Color.fromARGB(255, 39, 48, 176), // Morado igual a los otros
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        filled: true,
        fillColor: Colors.white, // Fondo blanco
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
          borderRadius: BorderRadius.circular(16.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
          borderRadius: BorderRadius.circular(16.0),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(
            color: Color.fromARGB(255, 39, 48, 176), // Morado al enfocar
            width: 2.0,
          ),
          borderRadius: BorderRadius.all(Radius.circular(16.0)),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        floatingLabelStyle: const TextStyle(
          color: Color.fromARGB(255, 39, 48, 176),
        ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return GestureDetector(
      onTap: _registerWithGoogle,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 5,
              offset: Offset(0, 2),
              color: Colors.black.withOpacity(0.1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/google.png', width: 28, height: 28),
            const SizedBox(width: 12),
            Text(
              'Continuar con Google',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginText() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('¿Ya tienes cuenta? '),
        GestureDetector(
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen()),
            );
          },
          child: const Text(
            'Inicia sesión',
            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String labelText,
    IconData prefixIcon, {
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(color: Colors.black87, fontSize: 14), // Texto moderno
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: Colors.grey[600]), // Color label moderno
        prefixIcon: Icon(
          prefixIcon,
          color: const Color.fromARGB(255, 39, 48, 176),
        ), // Icono morado
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ), // Más espacio interno
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
          borderRadius: BorderRadius.circular(
            16.0,
          ), // Esquinas super redondeadas
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
          borderRadius: BorderRadius.circular(16.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: const Color.fromARGB(255, 39, 48, 176),
            width: 2.0,
          ), // Morado al enfocar
          borderRadius: BorderRadius.circular(16.0),
        ),
        floatingLabelBehavior:
            FloatingLabelBehavior.auto, // Label flotante moderno
        floatingLabelStyle: TextStyle(
          color: const Color.fromARGB(255, 39, 48, 176),
        ), // Label morado al enfocar
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String? value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: Colors.white, // Fondo blanco para el dropdown
      icon: Icon(
        Icons.arrow_drop_down,
        color: Colors.deepPurple,
      ), // Icono morado
      style: TextStyle(color: Colors.black87, fontSize: 14),
      items:
          items.map((item) {
            return DropdownMenuItem<String>(value: item, child: Text(item));
          }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600]),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.deepPurple, width: 2.0),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildElevatedButton(
    String label,
    VoidCallback onPressed,
    Color color,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 18)),
    );
  }
}
