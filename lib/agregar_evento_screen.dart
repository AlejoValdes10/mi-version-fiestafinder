import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AgregarEventoScreen extends StatefulWidget {
  final User user;
  const AgregarEventoScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<AgregarEventoScreen> createState() => _AgregarEventoScreenState();
}

class _AgregarEventoScreenState extends State<AgregarEventoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _capacidadController = TextEditingController();
  final _costoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _horaController = TextEditingController();
  final _contactoController = TextEditingController();
  final _etiquetasController = TextEditingController();
  final _politicasController = TextEditingController();
  final _fechaController = TextEditingController();
  final _mediosPagoController = TextEditingController();

  String? _localidadSeleccionada;
  String? _tipoSeleccionado;
  bool _accesibilidad = false;
  bool _parqueadero = false;
  bool _puertaAPuerta = false;

  File? _imageFile;
  bool _isLoading = false;
  final List<String> _localidades = [
    'Chapinero', 'Usaquén', 'Teusaquillo', 
    'Suba', 'Engativá', 'Fontibón'
  ];
  final List<String> _tiposEvento = [
    'Concierto', 'Fiesta', 'Cultural', 'Deportivo', 
    'Académico', 'Gastronómico', 'Otro'
  ];

  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error al seleccionar imagen: ${e.toString()}');
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      setState(() => _isLoading = true);
      final fileName = 'event_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref('event_images/$fileName');
      await ref.putFile(image);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading image: $e');
      _showErrorSnackBar('Error al subir la imagen');
      return null;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Validación de fecha
      if (_fechaController.text.isEmpty) {
        throw 'Por favor selecciona una fecha válida';
      }

      final fechaEvento = DateFormat('yyyy-MM-dd').parse(_fechaController.text);
      
      // Validación de fecha futura
      if (fechaEvento.isBefore(DateTime.now())) {
        throw 'La fecha del evento debe ser futura';
      }

      // Subir imagen si existe
      String? imageUrl;
      if (_imageFile != null) {
        imageUrl = await _uploadImage(_imageFile!);
      }

      // Crear objeto de evento
      final eventData = {
        'eventName': _nombreController.text.trim(),
        'descripcion': _descripcionController.text.trim(),
        'localidad': _localidadSeleccionada,
        'fecha': DateFormat('dd/MM/yyyy').format(fechaEvento),
        'fechaTimestamp': Timestamp.fromDate(fechaEvento),
        'tipo': _tipoSeleccionado,
        'image': imageUrl ?? 'https://via.placeholder.com/150',
        'creatorId': widget.user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'capacidad': int.tryParse(_capacidadController.text) ?? 0,
        'costo': double.tryParse(_costoController.text) ?? 0.0,
        'direccion': _direccionController.text.trim(),
        'hora': _horaController.text.trim(),
        'contacto': _contactoController.text.trim(),
        'etiquetas': _etiquetasController.text.split(',').map((e) => e.trim()).toList(),
        'politicas': _politicasController.text.trim(),
        'accesibilidad': _accesibilidad,
        'parqueadero': _parqueadero,
        'puertaAPuerta': _puertaAPuerta,
        'mediosPago': _mediosPagoController.text.split(',').map((e) => e.trim()).toList(),
        'rating': 0,
        'views': 0,
      };

      // Guardar en Firestore
      await FirebaseFirestore.instance.collection('eventos').add(eventData);

      _showSuccessSnackBar('Evento enviado para aprobación');
      if (mounted) Navigator.pop(context);
      
    } on FormatException {
      _showErrorSnackBar('Formato de fecha inválido');
    } catch (e) {
      _showErrorSnackBar('Error: ${e.toString()}');
      debugPrint('Error submitting event: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _capacidadController.dispose();
    _costoController.dispose();
    _direccionController.dispose();
    _horaController.dispose();
    _contactoController.dispose();
    _etiquetasController.dispose();
    _politicasController.dispose();
    _fechaController.dispose();
    _mediosPagoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Nuevo Evento'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Sección de imagen
                    _buildImageSection(),
                    const SizedBox(height: 20),
                    
                    // Sección de información básica
                    _buildBasicInfoSection(),
                    const SizedBox(height: 20),
                    
                    // Sección de detalles
                    _buildDetailsSection(),
                    const SizedBox(height: 20),
                    
                    // Sección de características
                    _buildFeaturesSection(),
                    const SizedBox(height: 20),
                    
                    // Botón de enviar
                    ElevatedButton(
                      onPressed: _submitEvent,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('PUBLICAR EVENTO'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      children: [
        Text(
          'Imagen del Evento',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[400]!),
            ),
            child: _imageFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(_imageFile!, fit: BoxFit.cover),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Agregar imagen'),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Información Básica',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _nombreController,
          decoration: const InputDecoration(
            labelText: 'Nombre del evento*',
            border: OutlineInputBorder(),
          ),
          validator: (value) => value!.isEmpty ? 'Este campo es obligatorio' : null,
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _descripcionController,
          decoration: const InputDecoration(
            labelText: 'Descripción*',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          validator: (value) => value!.isEmpty ? 'Este campo es obligatorio' : null,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _fechaController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Fecha*',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(DateTime.now().year + 2),
                  );
                  if (picked != null) {
                    _fechaController.text = DateFormat('yyyy-MM-dd').format(picked);
                  }
                },
                validator: (value) => value!.isEmpty ? 'Selecciona una fecha' : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _horaController,
                decoration: const InputDecoration(
                  labelText: 'Hora (ej: 21:00)*',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value!.isEmpty) return 'Ingresa la hora';
                  if (!RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$').hasMatch(value)) {
                    return 'Formato inválido (HH:MM)';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Detalles del Evento',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: _localidadSeleccionada,
          items: _localidades
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e),
                  ))
              .toList(),
          onChanged: (val) => setState(() => _localidadSeleccionada = val),
          decoration: const InputDecoration(
            labelText: 'Localidad*',
            border: OutlineInputBorder(),
          ),
          validator: (value) => value == null ? 'Selecciona una localidad' : null,
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: _tipoSeleccionado,
          items: _tiposEvento
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e),
                  ))
              .toList(),
          onChanged: (val) => setState(() => _tipoSeleccionado = val),
          decoration: const InputDecoration(
            labelText: 'Tipo de evento*',
            border: OutlineInputBorder(),
          ),
          validator: (value) => value == null ? 'Selecciona un tipo' : null,
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _direccionController,
          decoration: const InputDecoration(
            labelText: 'Dirección exacta*',
            border: OutlineInputBorder(),
          ),
          validator: (value) => value!.isEmpty ? 'Este campo es obligatorio' : null,
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _capacidadController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Capacidad máxima*',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value!.isEmpty) return 'Este campo es obligatorio';
            if (int.tryParse(value) == null) return 'Ingresa un número válido';
            return null;
          },
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _costoController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Costo de entrada',
            border: OutlineInputBorder(),
            prefixText: '\$ ',
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Características',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        SwitchListTile(
          title: const Text('Accesibilidad para personas con discapacidad'),
          value: _accesibilidad,
          onChanged: (val) => setState(() => _accesibilidad = val),
        ),
        SwitchListTile(
          title: const Text('Disponibilidad de parqueadero'),
          value: _parqueadero,
          onChanged: (val) => setState(() => _parqueadero = val),
        ),
        SwitchListTile(
          title: const Text('Servicio puerta a puerta'),
          value: _puertaAPuerta,
          onChanged: (val) => setState(() => _puertaAPuerta = val),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _contactoController,
          decoration: const InputDecoration(
            labelText: 'Contacto (teléfono/email)*',
            border: OutlineInputBorder(),
          ),
          validator: (value) => value!.isEmpty ? 'Este campo es obligatorio' : null,
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _etiquetasController,
          decoration: const InputDecoration(
            labelText: 'Etiquetas (separadas por coma)',
            border: OutlineInputBorder(),
            hintText: 'ej: música, baile, arte',
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _mediosPagoController,
          decoration: const InputDecoration(
            labelText: 'Medios de pago aceptados',
            border: OutlineInputBorder(),
            hintText: 'ej: Efectivo, Tarjeta, Nequi',
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _politicasController,
          decoration: const InputDecoration(
            labelText: 'Políticas del evento',
            border: OutlineInputBorder(),
            hintText: 'Políticas de cancelación, restricciones, etc.',
          ),
          maxLines: 3,
        ),
      ],
    );
  }
}