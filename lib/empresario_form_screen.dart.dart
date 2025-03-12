import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
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
  String? selectedDocumentType;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/inicio3.mp4')
      ..initialize().then((_) {
        setState(() {});
        _controller.setLooping(true);
        _controller.play();
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
          // **1. Fondo de video que ocupa toda la pantalla**
          Positioned.fill(
            child: _controller.value.isInitialized
                ? FittedBox(
                    fit: BoxFit.cover, // Ajusta el video sin dejar espacios en negro
                    child: SizedBox(
                      width: _controller.value.size.width,
                      height: _controller.value.size.height,
                      child: VideoPlayer(_controller),
                    ),
                  )
                : const Center(child: CircularProgressIndicator()),
          ),
          // **2. Contenedor semi-transparente con el formulario**
          Align(
            alignment: Alignment.center,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  padding: const EdgeInsets.all(20.0),
                  width: MediaQuery.of(context).size.width * 0.9,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(25),
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
                      // **3. Imagen del logo**
                      Image.asset(
                        'assets/ff.png',
                        height: 100,
                      ),
                      const SizedBox(height: 20),
                      // **4. Título**
                      const Text(
                        'EMPRESARIO',
                        style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      const SizedBox(height: 30),
                      // **5. Campos del formulario**
                      _buildTextField(nameController, 'Nombre del Empresario'),
                      const SizedBox(height: 15),
                      _buildTextField(nameController, 'NIT'),
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
                      // **6. Botón de enviar**
                      ElevatedButton(
                        onPressed: () {
                          // Acción para enviar el formulario
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          elevation: 10,
                        ),
                        child: const Text(
                          "Enviar",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
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
    decoration: InputDecoration(
      labelText: labelText,
      filled: true,
      fillColor: Colors.white.withOpacity(0.2),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    ),
    validator: validator,
  );
}

Widget _buildElevatedButton(String text, String route) {
  return ElevatedButton(
    onPressed: () {
      if (mounted) {
        Navigator.pushNamed(context, route);
      }
    },
    child: Text(text),
  );
}
}