import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:lottie/lottie.dart'; // Lottie animations
import 'styles.dart'; // Tu archivo de estilos personalizados
import 'home_screen.dart';
import 'empresario_form_screen.dart.dart';
import 'package:logger/logger.dart';

void main() {
  runApp(const FiestaFinderApp());
}

class FiestaFinderApp extends StatelessWidget {
  const FiestaFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: TextTheme(
          bodyMedium: TextStyle(fontFamily: 'Poppins', fontSize: 16, color: Colors.black),
          bodyLarge: TextStyle(fontFamily: 'Poppins', fontSize: 18, color: Colors.black),
        ),
      ),
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
    Future.delayed(const Duration(seconds: 4), () {
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
          // Video de fondo (se asegura que cubra toda la pantalla)
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
                : Container(),
          ),
          // Formulario centrado con un fondo blanco y elementos modernos
          SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9), // Fondo blanco con opacidad
                    borderRadius: BorderRadius.circular(25), // Bordes redondeados
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedOpacity(
                        opacity: 1.0,
                        duration: const Duration(seconds: 2),
                        child: Image.asset(
                          'assets/ff.png',
                          height: 100,
                        ),
                      ),
                      const SizedBox(height: 20),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(seconds: 1),
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.black, // Título en negro
                        ),
                        child: const Text('FIESTA FINDER'),
                      ),
                      const SizedBox(height: 30),
                      _buildTextField(nameController, 'Nombre'),
                      const SizedBox(height: 15),
                      _buildTextField(emailController, 'Correo', keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 15),
                      _buildTextField(passwordController, 'Contraseña', obscureText: true),
                      const SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        value: selectedDocumentType,
                        items: const [
                          DropdownMenuItem(value: 'opcion1', child: Text('Cédula')),
                          DropdownMenuItem(value: 'opcion2', child: Text('Cédula Extranjera')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedDocumentType = value;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Selecciona...',
                          labelStyle: const TextStyle(color: Colors.black),
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      _buildTextField(numberController, 'Número', keyboardType: TextInputType.number),
                      const SizedBox(height: 30),
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

  Widget _buildTextField(TextEditingController controller, String labelText, {bool obscureText = false, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: Colors.black),
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildElevatedButton(String text, String route) {
    return ElevatedButton(
      onPressed: () {
        Navigator.pushNamed(context, route);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        elevation: 10,
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }
}
