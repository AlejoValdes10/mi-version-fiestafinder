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
      ..initialize()
          .then((_) {
            if (mounted) {
              setState(() {
                _controller.setLooping(true);
                _controller.play();
              });
            }
          })
          .catchError((e) {
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
          Positioned.fill(
            child:
                _controller.value.isInitialized
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
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                padding: const EdgeInsets.all(20.0),
                decoration: AppStyles.containerDecoration,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/ff.png', height: 100),
                    const SizedBox(height: 10),
                    Text(
                      'FIESTA FINDER',
                      style: AppStyles.titleTextStyle.copyWith(
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(nameController, 'Nombre'),
                    const SizedBox(height: 10),
                    _buildTextField(
                      emailController,
                      'Correo',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 10),
                    _buildTextField(
                      passwordController,
                      'Contraseña',
                      obscureText: true,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedDocumentType,
                      items: const [
                        DropdownMenuItem(
                          value: 'Cédula',
                          child: Text('Cédula'),
                        ),
                        DropdownMenuItem(
                          value: 'Cédula Extranjera',
                          child: Text('Cédula Extranjera'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedDocumentType = value;
                        });
                      },
                      decoration: AppStyles.textFieldDecoration(
                        'Selecciona...',
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildTextField(
                      numberController,
                      'Número',
                      keyboardType: TextInputType.number,
                    ),
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
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String labelText, {
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: AppStyles.textFieldDecoration(labelText),
    );
  }

  Widget _buildElevatedButton(String text, String route) {
    return ElevatedButton(
      onPressed: () async {
        await FirebaseService.guardarUsuario(
          nameController.text,
          emailController.text,
          numberController.text,
          selectedDocumentType ?? "Sin especificar",
        );
        Navigator.pushNamed(context, route);
      },
      style: AppStyles.buttonStyle,
      child: Text(text),
    );
  }
}
