import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math';
import 'package:cloudinary_public/cloudinary_public.dart';

class AgregarEventoScreen extends StatefulWidget {
  final User user;
  const AgregarEventoScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<AgregarEventoScreen> createState() => _AgregarEventoScreenState();
}

class _AgregarEventoScreenState extends State<AgregarEventoScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _esGratis = false;
  bool _tieneCapacidad = false;
  
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
  final _cuentaBancariaController = TextEditingController();
  final _nequiController = TextEditingController();
  final _daviplataController = TextEditingController();

  final String _cloudinaryCloudName = 'di6pgbrlu';
  final String _cloudinaryUploadPreset = 'fiesta_finder_preset';

  final List<String> _zonas = [
    'Norte',
    'Occidente',
    'Oriente',
    'Sur',
    'Noroccidente',
    'Nororiente',
    'Suroccidente',
    'Suroriente',
  ];

  final List<String> _mediosDePagoDisponibles = [
    'Efectivo',
    'Tarjeta crédito/débito',
    'Transferencia bancaria',
    'Nequi',
    'Daviplata',
  ];
  final List<String> _mediosSeleccionados = [];

  String? _imagenPredefinida;
  String? _zonaSeleccionada;
  String? _tipoSeleccionado;

  bool _accesibilidad = false;
  bool _parqueadero = false;

  File? _imageFile;
  bool _isLoading = false;
  LatLng? _ubicacionEvento;
  final List<String> _tiposEvento = [
    'Gastrobar',
    'Discotecas',
    'Cultural',
    'Deportivo',
  ];

  final Map<String, List<String>> _eventoImagenes = {
    'Gastrobar': [
      'assets/unnamed.png',
      'assets/unnamed.png',
      'assets/unnamed.png',
      'assets/unnamed.png',
      'assets/unnamed.png',
    ],
    'Discotecas': [
      'assets/unnamed.png',
      'assets/unnamed.png',
      'assets/unnamed.png',
      'assets/unnamed.png',
      'assets/unnamed.png',
    ],
    'Cultural': [
      'assets/unnamed.png',
      'assets/unnamed.png',
      'assets/unnamed.png',
      'assets/unnamed.png',
      'assets/unnamed.png',
    ],
    'Deportivo': [
      'assets/depor.png',
      'assets/depor.png',
      'assets/depor.png',
      'assets/depor.png',
      'assets/depor.png',
    ],
  };

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

      final cloudinary = CloudinaryPublic(
        _cloudinaryCloudName,
        _cloudinaryUploadPreset,
        cache: false,
      );

      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          image.path,
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      return response.secureUrl;
    } on CloudinaryException catch (e) {
      debugPrint('Error al subir imagen a Cloudinary: ${e.message}');
      _showErrorSnackBar('Error al subir la imagen: ${e.message}');
      return null;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(primary: Color(0xFF6A11CB)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _horaController.text = picked.format(context);
      });
    }
  }

  Future<void> _selectLocation() async {
    final TextEditingController _direccionInputController =
        TextEditingController();
    String? errorText;

    await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Escribir dirección'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _direccionInputController,
                    decoration: InputDecoration(
                      hintText: 'Ej. Calle 123 #45-67, Bogotá',
                      errorText: errorText,
                    ),
                    autofocus: true,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () {
                    final direccion = _direccionInputController.text.trim();
                    if (direccion.isEmpty) {
                      setState(() {
                        errorText = 'Por favor escribe una dirección.';
                      });
                    } else {
                      Navigator.pop(context, direccion);
                    }
                  },
                  child: const Text('Aceptar'),
                ),
              ],
            );
          },
        );
      },
    ).then((result) {
      if (result != null && result.isNotEmpty) {
        setState(() {
          _direccionController.text = result;
          _ubicacionEvento = null;
        });
      }
    });
  }

  Future<void> _submitEvent() async {
    if (_zonaSeleccionada == null || _zonaSeleccionada!.isEmpty) {
      _showErrorSnackBar('Por favor selecciona una zona de la ciudad');
      return;
    }
    
    if (!_formKey.currentState!.validate()) return;
    
    if (!_esGratis) {
      if (_tieneCapacidad && _capacidadController.text.isEmpty) {
        _showErrorSnackBar('Por favor ingresa la capacidad del evento');
        return;
      }
      if (_costoController.text.isEmpty) {
        _showErrorSnackBar('Por favor ingresa el costo del evento');
        return;
      }
      if (_mediosSeleccionados.isEmpty) {
        _showErrorSnackBar('Selecciona al menos un medio de pago');
        return;
      }
    }
    
    if (_esGratis) {
      if (_costoController.text.isNotEmpty && _costoController.text != "0") {
        _showErrorSnackBar('Un evento gratis no puede tener costo');
        return;
      }
      if (_mediosSeleccionados.isNotEmpty) {
        _showErrorSnackBar('Un evento gratis no puede tener medios de pago');
        return;
      }
      if (_tieneCapacidad && _capacidadController.text.isEmpty) {
        _showErrorSnackBar('Por favor ingresa la capacidad del evento');
        return;
      }
    }

    if (_mediosSeleccionados.contains('Transferencia bancaria') &&
        _cuentaBancariaController.text.isEmpty) {
      _showErrorSnackBar('Ingresa la cuenta bancaria');
      return;
    }
    if (_mediosSeleccionados.contains('Nequi') &&
        _nequiController.text.isEmpty) {
      _showErrorSnackBar('Ingresa el número de Nequi');
      return;
    }
    if (_mediosSeleccionados.contains('Daviplata') &&
        _daviplataController.text.isEmpty) {
      _showErrorSnackBar('Ingresa el número de Daviplata');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_fechaController.text.isEmpty) {
        throw 'Por favor selecciona una fecha válida';
      }

      final fechaEvento = DateFormat('yyyy-MM-dd').parse(_fechaController.text);

      if (fechaEvento.isBefore(DateTime.now())) {
        throw 'La fecha del evento debe ser futura';
      }

      String? imageUrl;
      if (_imageFile != null) {
        imageUrl = await _uploadImage(_imageFile!);
      }

      Map<String, String> infoPagos = {};
      if (_mediosSeleccionados.contains('Transferencia bancaria')) {
        infoPagos['cuenta_bancaria'] = _cuentaBancariaController.text.trim();
      }
      if (_mediosSeleccionados.contains('Nequi')) {
        infoPagos['nequi'] = _nequiController.text.trim();
      }
      if (_mediosSeleccionados.contains('Daviplata')) {
        infoPagos['daviplata'] = _daviplataController.text.trim();
      }

      final eventData = {
        'eventName': _nombreController.text.trim(),
        'descripcion': _descripcionController.text.trim(),
        'zona': _zonaSeleccionada,
        'fecha': DateFormat('dd/MM/yyyy').format(fechaEvento),
        'fechaTimestamp': Timestamp.fromDate(fechaEvento),
        'tipo': _tipoSeleccionado,
        'image': imageUrl ?? _imagenPredefinida ?? 'assets/depor.png',
        'creatorId': widget.user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'capacidad': _tieneCapacidad ? (int.tryParse(_capacidadController.text) ?? 0) : 0,
        'costo': _esGratis ? 0.0 : (double.tryParse(_costoController.text) ?? 0.0),
        'esGratis': _esGratis,
        'tieneCapacidad': _tieneCapacidad,
        'direccion': _direccionController.text.trim(),
        'ubicacion': _ubicacionEvento != null
            ? GeoPoint(
                _ubicacionEvento!.latitude,
                _ubicacionEvento!.longitude,
              )
            : null,
        'hora': _horaController.text.trim(),
        'contacto': _contactoController.text.trim(),
        'etiquetas':
            _etiquetasController.text.split(',').map((e) => e.trim()).toList(),
        'politicas': _politicasController.text.trim(),
        'accesibilidad': _accesibilidad,
        'parqueadero': _parqueadero,
        'mediosPago': _esGratis ? [] : _mediosSeleccionados,
        'infoPagos': infoPagos,
        'rating': 0,
        'views': 0,
      };

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
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
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
    _cuentaBancariaController.dispose();
    _nequiController.dispose();
    _daviplataController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Crear Evento',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: Color(0xFF6A11CB)),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildImageSection(),
                    SizedBox(height: 25),
                    _buildSection(
                      title: 'Información Básica',
                      child: _buildBasicInfoSection(),
                    ),
                    SizedBox(height: 20),
                    _buildSection(
                      title: 'Detalles del Evento',
                      child: _buildDetailsSection(),
                    ),
                    SizedBox(height: 20),
                    _buildSection(
                      title: 'Características',
                      child: _buildFeaturesSection(),
                    ),
                    SizedBox(height: 20),
                    _buildSection(
                      title: 'Medios de Pago',
                      child: _buildMediosDePagoSection(),
                    ),
                    SizedBox(height: 20),
                    _buildSection(
                      title: 'Información de Pagos',
                      child: _buildPaymentInfoSection(),
                    ),
                    SizedBox(height: 30),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _submitEvent,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'PUBLICAR EVENTO',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildImageSection() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: _imageFile != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(_imageFile!, fit: BoxFit.cover),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate,
                    size: 50,
                    color: Colors.grey[600],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Agregar imagen principal',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      children: [
        _buildModernTextField(
          controller: _nombreController,
          label: 'Nombre del evento*',
          icon: Icons.event,
        ),
        SizedBox(height: 16),
        _buildModernTextField(
          controller: _descripcionController,
          label: 'Descripción*',
          icon: Icons.description,
          maxLines: 3,
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildModernTextField(
                controller: _fechaController,
                label: 'Fecha*',
                icon: Icons.calendar_today,
                readOnly: true,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(DateTime.now().year + 2),
                  );
                  if (picked != null) {
                    _fechaController.text = DateFormat('yyyy-MM-dd').format(picked);
                  }
                },
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildModernTextField(
                controller: _horaController,
                label: 'Hora',
                icon: Icons.access_time,
                readOnly: true,
                onTap: _selectTime,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    bool readOnly = false,
    int maxLines = 1,
    VoidCallback? onTap,
    TextInputType? keyboardType,
    bool? enabled,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: maxLines,
      keyboardType: keyboardType,
      enabled: enabled,
      style: GoogleFonts.poppins(),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
        floatingLabelStyle: GoogleFonts.poppins(color: Color(0xFF6A11CB)),
        prefixIcon: icon != null ? Icon(icon, color: Color(0xFF6A11CB)) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Color(0xFF6A11CB), width: 1.5),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: (value) => value!.isEmpty ? 'Este campo es obligatorio' : null,
    );
  }

  Widget _buildDetailsSection() {
    return Column(
      children: [
        _buildModernDropdown(
          value: _zonaSeleccionada,
          items: _zonas,
          label: 'Zona de la ciudad*',
          icon: Icons.location_on,
          onChanged: (val) => setState(() => _zonaSeleccionada = val),
        ),
        SizedBox(height: 16),
        _buildModernDropdown(
          value: _tipoSeleccionado,
          items: _tiposEvento,
          label: 'Tipo de evento*',
          icon: Icons.category,
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _tipoSeleccionado = val;
                _asignarImagenAleatoria(val);
              });
            }
          },
        ),
        SizedBox(height: 16),
        _buildModernTextField(
          controller: _direccionController,
          label: 'Dirección exacta*',
          icon: Icons.map,
          readOnly: true,
          onTap: _selectLocation,
        ),
        if (_ubicacionEvento != null) ...[
          SizedBox(height: 16),
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: FlutterMap(
                options: MapOptions(center: _ubicacionEvento, zoom: 15.0),
                children: [
                  TileLayer(
                    urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: ['a', 'b', 'c'],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _ubicacionEvento!,
                        builder: (ctx) => Icon(
                          Icons.location_pin,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
        SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 1.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: _buildModernSwitch(
            value: _esGratis,
            onChanged: (val) => setState(() {
              _esGratis = val;
              if (val) {
                _mediosSeleccionados.clear();
                _costoController.clear();
              }
            }),
            label: 'Evento gratuito',
            icon: Icons.money_off,
          ),
        ),
        SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 1.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: _buildModernSwitch(
            value: _tieneCapacidad,
            onChanged: (val) => setState(() {
              _tieneCapacidad = val;
              if (!val) {
                _capacidadController.clear();
              }
            }),
            label: 'Mi evento tiene capacidad limitada',
            icon: Icons.people,
          ),
        ),
        if (_tieneCapacidad) ...[
          SizedBox(height: 16),
          _buildModernTextField(
            controller: _capacidadController,
            label: 'Capacidad máxima*',
            icon: Icons.format_list_numbered,
            keyboardType: TextInputType.number,
          ),
        ],
        if (!_esGratis) ...[
          SizedBox(height: 16),
          _buildModernTextField(
            controller: _costoController,
            label: 'Costo de entrada*',
            icon: Icons.attach_money,
            keyboardType: TextInputType.number,
          ),
        ],
      ],
    );
  }

  Widget _buildModernDropdown({
    required String? value,
    required List<String> items,
    required String label,
    required IconData icon,
    required Function(String?) onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
        floatingLabelStyle: GoogleFonts.poppins(color: Color(0xFF6A11CB)),
        prefixIcon: Icon(icon, color: Color(0xFF6A11CB)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Color(0xFF6A11CB), width: 1.5),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          isExpanded: true,
          style: GoogleFonts.poppins(color: Colors.black87),
          items: items.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? newValue) {
            onChanged(newValue);
          },
          hint: Text('Selecciona', style: GoogleFonts.poppins()),
        ),
      ),
    );
  }

  void _asignarImagenAleatoria(String tipoEvento) {
    if (_eventoImagenes.containsKey(tipoEvento)) {
      final random = Random();
      final imagenes = _eventoImagenes[tipoEvento]!;
      final imagenAleatoria = imagenes[random.nextInt(imagenes.length)];

      setState(() {
        _imagenPredefinida = imagenAleatoria;
        _imageFile = null;
      });
    }
  }

  Widget _buildFeaturesSection() {
    return Column(
      children: [
        _buildModernSwitch(
          value: _accesibilidad,
          onChanged: (val) => setState(() => _accesibilidad = val),
          label: 'Accesibilidad para personas con discapacidad',
          icon: Icons.accessible,
        ),
        SizedBox(height: 12),
        _buildModernSwitch(
          value: _parqueadero,
          onChanged: (val) => setState(() => _parqueadero = val),
          label: 'Disponibilidad de parqueadero',
          icon: Icons.local_parking,
        ),
        SizedBox(height: 16),
        _buildModernTextField(
          controller: _contactoController,
          label: 'Contacto (teléfono/email)*',
          icon: Icons.contact_phone,
        ),
        SizedBox(height: 16),
        _buildModernTextField(
          controller: _etiquetasController,
          label: 'Etiquetas (separadas por coma)',
          icon: Icons.tag,
        ),
        SizedBox(height: 16),
        _buildModernTextField(
          controller: _politicasController,
          label: 'Políticas del evento',
          icon: Icons.policy,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildModernSwitch({
    required bool value,
    required Function(bool) onChanged,
    required String label,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFF6A11CB)),
          SizedBox(width: 12),
          Expanded(child: Text(label, style: GoogleFonts.poppins())),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Color(0xFF6A11CB),
            activeTrackColor: Color(0xFF6A11CB).withAlpha(76),
          ),
        ],
      ),
    );
  }

  Widget _buildMediosDePagoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selecciona los medios de pago aceptados:',
          style: GoogleFonts.poppins(
            fontSize: 14, 
            color: _esGratis ? Colors.grey : Colors.grey[700]
          ),
        ),
        SizedBox(height: 12),
        IgnorePointer(
          ignoring: _esGratis,
          child: Opacity(
            opacity: _esGratis ? 0.5 : 1.0,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _mediosDePagoDisponibles.map((medio) {
                final isSelected = _mediosSeleccionados.contains(medio);
                return ChoiceChip(
                  label: Text(medio),
                  selected: isSelected,
                  onSelected: _esGratis ? null : (selected) {
                    setState(() {
                      if (selected) {
                        _mediosSeleccionados.add(medio);
                      } else {
                        _mediosSeleccionados.remove(medio);
                      }
                    });
                  },
                  labelStyle: GoogleFonts.poppins(
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                  selectedColor: Color(0xFF6A11CB),
                  backgroundColor: Colors.grey[200],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        if (_mediosSeleccionados.isEmpty && !_esGratis)
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Selecciona al menos un medio de pago',
              style: GoogleFonts.poppins(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildPaymentInfoSection() {
    return Column(
      children: [
        if (_mediosSeleccionados.contains('Transferencia bancaria'))
          _buildModernTextField(
            controller: _cuentaBancariaController,
            label: 'Número de cuenta bancaria*',
            icon: Icons.account_balance,
            keyboardType: TextInputType.number,
            enabled: !_esGratis,
          ),
        if (_mediosSeleccionados.contains('Nequi'))
          _buildModernTextField(
            controller: _nequiController,
            label: 'Número de Nequi*',
            icon: Icons.phone_android,
            keyboardType: TextInputType.phone,
            enabled: !_esGratis,
          ),
        if (_mediosSeleccionados.contains('Daviplata'))
          _buildModernTextField(
            controller: _daviplataController,
            label: 'Número de Daviplata*',
            icon: Icons.phone_android,
            keyboardType: TextInputType.phone,
            enabled: !_esGratis,
          ),
      ],
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}