import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AgregarEventoScreen extends StatefulWidget {
  final User user;

  const AgregarEventoScreen({required this.user, Key? key}) : super(key: key);

  @override
  _AgregarEventoScreenState createState() => _AgregarEventoScreenState();
}

class _AgregarEventoScreenState extends State<AgregarEventoScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController descripcionController = TextEditingController();
  final TextEditingController direccionController = TextEditingController();
  final TextEditingController ubicacionController = TextEditingController();
  final TextEditingController costoController = TextEditingController();
  final TextEditingController capacidadController = TextEditingController();
  DateTime? fechaEvento;

  Future<void> _guardarEvento() async {
  if (!_formKey.currentState!.validate() || fechaEvento == null) return;

  try {
    // Imagen por defecto si no se proporciona una imagen personalizada
    String imagenUrl = 'assets/unnamed.png'; // Ruta de la imagen por defecto

    await FirebaseFirestore.instance.collection('eventos').add({
      'nombre': nombreController.text,
      'descripcion': descripcionController.text,
      'direccion': direccionController.text,
      'ubicacion': ubicacionController.text,
      'costo': int.parse(costoController.text),
      'capacidad': int.parse(capacidadController.text),
      'fecha': Timestamp.fromDate(fechaEvento!),
      'empresarioId': widget.user.uid,
      'imagen': imagenUrl, // Guardamos la imagen por defecto si no se ha subido una nueva
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Evento agregado correctamente')),
    );

    Navigator.pop(context);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al guardar el evento: $e')),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Agregar Evento")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField("Nombre", nombreController),
              _buildTextField("Descripción", descripcionController),
              _buildTextField("Dirección", direccionController),
              _buildTextField("Ubicación", ubicacionController),
              _buildTextField("Costo", costoController, isNumber: true),
              _buildTextField("Capacidad", capacidadController, isNumber: true),
              ListTile(
                title: Text(
                  fechaEvento == null
                      ? "Seleccionar Fecha"
                      : "Fecha: ${fechaEvento!.toLocal()}".split(' ')[0],
                ),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      fechaEvento = pickedDate;
                    });
                  }
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _guardarEvento,
                child: Text("Guardar Evento"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          fillColor: Colors.deepPurple[50],
          filled: true,
        ),
        validator: (value) => value == null || value.isEmpty ? "Campo requerido" : null,
      ),
    );
  }
}
