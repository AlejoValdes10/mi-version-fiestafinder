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
    );
    if (picked != null) {
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
    if (!_formKey.currentState!.validate()) {
      print("Formulario no válido");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Placeholder temporal (esto se reemplaza si usas Firebase Storage después)
      final imageUrl = _imageFile != null 
          ? 'https://via.placeholder.com/400' 
          : 'https://via.placeholder.com/400?text=${_nombreController.text}';

      await FirebaseFirestore.instance.collection('eventos').add({
  'eventName': _nombreController.text,
  'descripcion': _descripcionController.text,
  'localidad': _localidadSeleccionada,
  'fecha': _fechaController.text,
  'tipo': _tipoSeleccionado,
  'image': 'https://via.placeholder.com/400?text=${_nombreController.text}',
  'createdBy': widget.user.uid,
  'createdAt': FieldValue.serverTimestamp(), // Este campo es crucial
});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Evento creado exitosamente!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      // En _submitEvent():
Navigator.pop(context, true); // En lugar de solo pop(context)
    } catch (e) {
      print('Error al crear evento: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear evento: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildImagePreview() {
    if (_imageFile == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
          SizedBox(height: 10),
          Text('Agregar imagen del evento'),
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
              Text('Error al cargar la imagen'),
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
        title: Text('Nuevo Evento'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _isLoading ? null : _submitEvent,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
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
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: _buildImagePreview(),
                      ),
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _nombreController,
                      decoration: InputDecoration(
                        labelText: 'Nombre del Evento*',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.event),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Este campo es requerido' : null,
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _descripcionController,
                      decoration: InputDecoration(
                        labelText: 'Descripción*',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
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
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _fechaController,
                      decoration: InputDecoration(
                        labelText: 'Fecha del Evento*',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.arrow_drop_down),
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
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                    ),
                    SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _submitEvent,
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                        padding: EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: Text(
                        'PUBLICAR EVENTO',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],  
                ),
              ),
            ),
    );
  }
}
