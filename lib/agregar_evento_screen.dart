import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AgregarEventoScreen extends StatefulWidget {
  final User user;
  const AgregarEventoScreen({Key? key, required this.user}) : super(key: key);

  @override
  _AgregarEventoScreenState createState() => _AgregarEventoScreenState();
}

class _AgregarEventoScreenState extends State<AgregarEventoScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _fechaController = TextEditingController();
  String _localidadSeleccionada = 'Centro';
  String _tipoSeleccionado = 'Entretenimiento';
  bool _isLoading = false;
  File? _imageFile;
  final picker = ImagePicker();

  final List<String> _localidades = ['Centro', 'Norte', 'Sur'];
  final List<String> _tiposEvento = ['Entretenimiento', 'Parejas', 'Amigos'];

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _fechaController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
  final DateTime? picked = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime.now(),
    lastDate: DateTime(2100),
    builder: (BuildContext context, Widget? child) {
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: Color(0xFF2730B0), // Color del header y botones
            onPrimary: Colors.white, // Texto en el header
            onSurface: Colors.black, // Texto en el selector
          ),
          dialogBackgroundColor: Colors.white, // Fondo del diálogo
        ),
        child: child!,
      );
    },
  );

  if (picked != null && picked != DateTime.now()) {
    setState(() {
      _fechaController.text = DateFormat('yyyy-MM-dd').format(picked);
    });
  }
}

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitEvent() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);

  try {
    final fechaEvento = DateFormat('yyyy-MM-dd').parse(_fechaController.text);
    final imageUrl = await _uploadImage(_imageFile);

    await FirebaseFirestore.instance.collection('eventos').add({
      // Campos principales (nuevo formato)
      'eventName': _nombreController.text,
      'descripcion': _descripcionController.text,
      'localidad': _localidadSeleccionada,
      'fecha': DateFormat('dd/MM/yyyy').format(fechaEvento), // String
      'fechaTimestamp': Timestamp.fromDate(fechaEvento), // Timestamp
      'tipo': _tipoSeleccionado,
      'image': imageUrl,
      'creatorId': widget.user.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending',
      
      // Campos compatibilidad (puedes eliminar luego)
      'nombre': _nombreController.text,
      'ubicacion': _localidadSeleccionada,
      'imagen': imageUrl,
      'empresarioId': widget.user.uid,
    });

    Navigator.pop(context, true);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: ${e.toString()}')),
    );
  } finally {
    setState(() => _isLoading = false);
  }
}

Future<String> _uploadImage(File? image) async {
  if (image == null) return 'https://via.placeholder.com/400';
  
  try {
    // Implementa la subida real a Firebase Storage aquí
    return 'https://tu-dominio.com/imagenes/${DateTime.now().millisecondsSinceEpoch}.jpg';
  } catch (e) {
    return 'https://via.placeholder.com/400?text=Imagen+no+disponible';
  }
}
  Widget _buildImagePreview() {
    if (_imageFile == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo, size: 50, color: Colors.grey[400]),
          SizedBox(height: 10),
          Text('Agregar imagen del evento', 
              style: TextStyle(color: Colors.grey[600])),
        ],
      );
    }

    return Image.file(
      _imageFile!,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, size: 50, color: Colors.red),
              SizedBox(height: 10),
              Text('Error al cargar la imagen', 
                  style: TextStyle(color: Colors.red)),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nuevo Evento', 
            style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF2730B0),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.save, color: Colors.white),
            onPressed: _isLoading ? null : _submitEvent,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2730B0)),
            ))
          : SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1.5,
                            style: BorderStyle.solid
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _buildImagePreview(),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _nombreController,
                      decoration: InputDecoration(
                        labelText: 'Nombre del Evento*',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: Icon(Icons.event, color: Color(0xFF2730B0)),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Este campo es requerido' : null,
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _descripcionController,
                      decoration: InputDecoration(
                        labelText: 'Descripción*',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: Icon(Icons.description, color: Color(0xFF2730B0)),
                      ),
                      maxLines: 3,
                      validator: (value) =>
                          value!.isEmpty ? 'Este campo es requerido' : null,
                    ),
                    SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: _localidadSeleccionada,
                      items: _localidades
                          .map((loc) => DropdownMenuItem(
                                value: loc,
                                child: Text(loc),
                              ))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _localidadSeleccionada = value!),
                      decoration: InputDecoration(
                        labelText: 'Localidad*',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: Icon(Icons.location_on, color: Color(0xFF2730B0)),
                      ),
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _fechaController,
                      decoration: InputDecoration(
                        labelText: 'Fecha del Evento*',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: Icon(Icons.calendar_today, color: Color(0xFF2730B0)),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.arrow_drop_down, color: Color(0xFF2730B0)),
                          onPressed: () => _selectDate(context),
                        ),
                      ),
                      readOnly: true,
                      validator: (value) =>
                          value!.isEmpty ? 'Selecciona una fecha' : null,
                    ),
                    SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: _tipoSeleccionado,
                      items: _tiposEvento
                          .map((tipo) => DropdownMenuItem(
                                value: tipo,
                                child: Text(tipo),
                              ))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _tipoSeleccionado = value!),
                      decoration: InputDecoration(
                        labelText: 'Tipo de Evento*',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: Icon(Icons.category, color: Color(0xFF2730B0)),
                      ),
                    ),
                    SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _submitEvent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF2730B0),
                        minimumSize: Size(double.infinity, 50),
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'ENVIAR PARA APROBACIÓN',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ],  
                ),
              ),
            ),
    );
  }
}