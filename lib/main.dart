import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:lottie/lottie.dart';
import 'package:logger/logger.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'firebase_service.dart';
import 'styles.dart';
import 'home_screen.dart';
import 'empresario_form_screen.dart.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const FiestaFinderApp());
}

class FiestaFinderApp extends StatelessWidget {
  const FiestaFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      theme: ThemeData(primarySwatch: Colors.blue),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/empresario': (context) => const EmpresarioFormScreen(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 4), () async {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const FiestaFinderScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Lottie.asset(
          'assets/spinner.json',
          width: 200,
          height: 200,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class FiestaFinderScreen extends StatefulWidget {
  const FiestaFinderScreen({super.key});

  @override
  FiestaFinderScreenState createState() => FiestaFinderScreenState();
}

class FiestaFinderScreenState extends State<FiestaFinderScreen> {
  late VideoPlayerController _controller;
  final Logger _logger = Logger();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController numberController = TextEditingController();
  String? selectedDocumentType;

  final _formKey = GlobalKey<FormState>(); // Clave global para el formulario

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/inicio3.mp4')
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _controller.setLooping(true);
            _controller.play();
          });
        }
      }).catchError((e) {
        _logger.e("Error al cargar el video: $e");
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

    @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ✅ Muestra el video directamente sin FutureBuilder
          Positioned.fill(
            child: _controller.value.isInitialized
                ? FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller.value.size.width,
                      height: _controller.value.size.height,
                      child: VideoPlayer(_controller),
                    ),
                  )
                : const Center(child: CircularProgressIndicator()),
          ),
          // Formulario flotante
          Center(
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(20.0),
                margin: const EdgeInsets.symmetric(horizontal: 30),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/ff.png', height: 100),
                      const SizedBox(height: 10),
                      Text(
                        'FIESTA FINDER',
                        style: AppStyles.titleTextStyle.copyWith(color: Colors.black),
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(nameController, 'Nombre'),
                      const SizedBox(height: 10),
                      _buildTextField(emailController, 'Correo',
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                        if (value == null || !value.contains('@')) {
                          return 'Por favor ingresa un correo válido';
                        }
                        return null;
                      }),
                      const SizedBox(height: 10),
                      _buildTextField(passwordController, 'Contraseña', obscureText: true,
                          validator: (value) {
                        if (value == null || !RegExp(r'^(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
                          return 'Debe contener al menos una mayúscula y un número';
                        }
                        return null;
                      }),
                      const SizedBox(height: 10),
                      // ✅ Evitar que el Dropdown afecte el video
                      DropdownButtonFormField<String>(
                        value: selectedDocumentType,
                        items: const [
                          DropdownMenuItem(value: 'Cédula', child: Text('Cédula')),
                          DropdownMenuItem(value: 'Cédula Extranjera', child: Text('Cédula Extranjera')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedDocumentType = value;
                          });
                          // ✅ Asegurar que el video sigue reproduciéndose
                          if (!_controller.value.isPlaying) {
                            _controller.play();
                          }
                        },
                        decoration: AppStyles.textFieldDecoration('Selecciona...'),
                      ),
                      const SizedBox(height: 10),
                      _buildTextField(numberController, 'Número',
                          keyboardType: TextInputType.number,
                          validator: (value) {
                        if (value == null || !RegExp(r'^\d+$').hasMatch(value)) {
                          return 'El número debe contener solo dígitos';
                        }
                        return null;
                      }),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildElevatedButton('INICIAR', '/home'),
                          _buildElevatedButton('EMPRESARIO', '/empresario'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildTextField(
    TextEditingController controller,
    String labelText, {
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: AppStyles.textFieldDecoration(labelText),
      validator: validator,
    );
  }

    Widget _buildElevatedButton(String text, String route) {
  return ElevatedButton(
    onPressed: () async {
      // Verificamos que el widget esté montado antes de usar el BuildContext
      if (mounted) {
        // Si el texto del botón es "INICIAR", validamos el formulario
        if (text == 'INICIAR') {
          final form = _formKey.currentState; // Usamos la clave del formulario
          if (form?.validate() ?? false) {
            // Si el formulario es válido, se guarda y navega
            await FirebaseService.guardarUsuario(
              nameController.text,
              emailController.text,
              numberController.text,
              selectedDocumentType ?? "Sin especificar",
            );

            // Aseguramos que el widget sigue montado antes de navegar
            if (mounted) {
              // Navegamos a la pantalla de inicio
              Navigator.pushNamed(context, route);
            }
          } else {
            // Si el formulario no es válido, mostramos un mensaje con SnackBar
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Por favor, corrige los errores.')),
            );
          }
        } else if (text == 'EMPRESARIO') {
          // Si el texto del botón es "EMPRESARIO", simplemente navegamos sin guardar datos ni validar
          if (mounted) {
            Navigator.pushNamed(context, route);
          }
        }
      }
    },
    style: AppStyles.buttonStyle,
    child: Text(text),
  );
}
}