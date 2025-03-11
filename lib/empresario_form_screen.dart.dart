import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'styles.dart';
 // Asegúrate de que la ruta sea correcta

// Importar logger para mejorar el manejo de logs en lugar de print
import 'package:logger/logger.dart';

class EmpresarioFormScreen extends StatefulWidget {
  const EmpresarioFormScreen({super.key});

  @override
  EmpresarioFormScreenState createState() => EmpresarioFormScreenState();
}

class EmpresarioFormScreenState extends State<EmpresarioFormScreen> {
  late VideoPlayerController _controller;
  final Logger _logger = Logger();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController numberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    // Inicializa el controlador de video
    _controller = VideoPlayerController.asset('assets/inicio3.mp4')
      ..initialize().then((_) {
        setState(() {}); // Actualiza la interfaz una vez que el video se haya inicializado
        _controller.setLooping(true); // Establece el video para que se repita
        _controller.play(); // Reproduce el video automáticamente
      }).catchError((e) {
        // Usar el logger para imprimir el error en lugar de print
        _logger.e("Error al cargar el video: $e");
      });
  }

  @override
  void dispose() {
    _controller.dispose(); // Asegúrate de liberar los recursos al salir
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo del video
          Positioned.fill(
            child: _controller.value.isInitialized
                ? FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller.value.size.width,
                      height: _controller.value.size.height,
                      child: VideoPlayer(_controller), // Muestra el video aquí
                    ),
                  )
                : const Center(child: CircularProgressIndicator()),
          ),
          // Aquí va el contenido principal
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                padding: const EdgeInsets.all(20.0),
                decoration: AppStyles.containerDecoration,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo o imagen
                    AnimatedOpacity(
                      opacity: 1.0,
                      duration: const Duration(seconds: 2),
                      child: Image.asset(
                        'assets/ff.png',
                        height: 100,
                      ),
                    ),
                    const SizedBox(height: 10),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(seconds: 1),
                      style: AppStyles.titleTextStyle.copyWith(
                        color: const Color.fromARGB(255, 0, 0, 0),
                      ),
                      child: const Text('EMPRESARIO'),
                    ),
                    const SizedBox(height: 20),
                    // Campos de texto del formulario
                    _buildTextField(nameController, 'Nombre del Empresario'),
                    const SizedBox(height: 10),
                    _buildTextField(emailController, 'Correo', keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 10),
                    _buildTextField(passwordController, 'Contraseña', obscureText: true),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      items: const [
                        DropdownMenuItem(value: 'opcion1', child: Text('Cédula')),
                        DropdownMenuItem(value: 'opcion2', child: Text('Cédula Extranjera')),
                      ],
                      onChanged: (value) {},
                      decoration: AppStyles.textFieldDecoration('Selecciona...'),
                    ),
                    const SizedBox(height: 10),
                    _buildTextField(numberController, 'Número', keyboardType: TextInputType.number),
                    const SizedBox(height: 20),
                    // Botón para enviar el formulario
                    ElevatedButton(
                      onPressed: () {
                        // Acción para enviar el formulario
                      },
                      style: AppStyles.elevatedButtonStyle,
                      child: const Text("Enviar", style: TextStyle(color: Colors.white)),
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

  Widget _buildTextField(TextEditingController controller, String hintText, {bool obscureText = false, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: AppStyles.textFieldDecoration(hintText),
    );
  }
}

