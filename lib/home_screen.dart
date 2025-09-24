import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'agregar_evento_screen.dart';
import 'dart:ui';
import 'mis_eventos_empresario_screen.dart';
import 'mis_reservas_screen.dart';

// Widgets personalizados
import 'event_card.dart';
import 'filter_modal.dart';
import 'custom_bottom_nav.dart';
import 'user_profile_section.dart';

class HomeScreen extends StatefulWidget {
  final User user;
  const HomeScreen(this.user, {super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  // Variables de estado
  String userName = "";
  String email = "";
  String cedula = "";
  String tipoPersona = "";
  String telefono = "";
  int _selectedIndex = 0;

  bool _loadingUser = true;
  bool _loadingEvents = true;
  bool _loadingFavorites = true;
  bool _initialDataLoaded = false;

  // Controladores
  final TextEditingController nameController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  // Listas y filtros
  List<Map<String, dynamic>> events = [];
  List<Map<String, dynamic>> filteredEvents = [];
  List<Map<String, dynamic>> favoriteEvents = [];

  // 🔹 Filtros (usaremos estos en lugar de selectedFilter/selectedDate/selectedType)
  String selectedLocalidad = "Todos";
  String selectedEntrada = "Todos";
  String selectedTipo = "Todos";

  // 🔹 Opciones de los dropdowns
  final List<String> localidades = ["Todos", "Norte", "Sur", "Centro"];
  final List<String> entradas = ["Todos", "Gratis", "De pago"];
  final List<String> tipos = [
    "Todos",
    "Concierto",
    "Festival",
    "Cultural",
    "Fiesta",
  ];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _loadUserData().then((_) {
      _setupEventListeners().then((_) {
        if (mounted) setState(() => _initialDataLoaded = true);
      });
    });
  }

  Future<void> _loadUserData() async {
    try {
      DocumentSnapshot doc =
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(widget.user.uid)
              .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          userName = data['nombre'] ?? "Usuario";
          email = widget.user.email ?? "No disponible";
          cedula = data['numeroDocumento'] ?? "No disponible";
          tipoPersona = data['tipoPersona'] ?? "Usuario";
          telefono = data['telefono'] ?? "";
          nameController.text = userName;
          phoneController.text = telefono;
          _loadingUser = false;
        });
      }
      // Cargar eventos y favoritos después de cargar los datos del usuario
      _setupEventListeners();
      _loadFavorites();
    } catch (e) {
      setState(() => _loadingUser = false);
      _showErrorSnackBar("Error al cargar datos del usuario");
    }
  }

  // Cargar eventos favoritos del usuario
  Future<void> _loadFavorites() async {
    try {
      final favoritesSnapshot =
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(widget.user.uid)
              .collection('favoritos')
              .orderBy('addedAt', descending: true)
              .get();

      final List<Map<String, dynamic>> loadedEvents = [];

      for (final favDoc in favoritesSnapshot.docs) {
        final eventId = favDoc.id;

        final eventSnapshot =
            await FirebaseFirestore.instance
                .collection('eventos')
                .doc(eventId)
                .get();

        if (eventSnapshot.exists) {
          final data = eventSnapshot.data()!;
          debugPrint(
            '✅ Evento encontrado (favorito): ${data['eventName']} - Dirección: ${data['direccion']}',
          );

          loadedEvents.add({
            'id': eventSnapshot.id,
            'name': data['eventName'] ?? data['name'] ?? 'Evento sin nombre',
            'image': data['image'] ?? '',
            'fecha': data['fecha'] ?? 'Sin fecha',
            'tipo': data['tipo'] ?? 'General',
            'descripcion': data['descripcion'] ?? '',
            'direccion':
                data['direccion'] ??
                data['address'] ??
                'Dirección no disponible',
            'costo': data['costo'],
            'esGratis': data['esGratis'] ?? false,
            'tieneCapacidad': data['tieneCapacidad'] ?? false,
            'capacidad': data['capacidad'] ?? 0,
            'hora': data['hora'] ?? '',
            'contacto': data['contacto'] ?? '',
            'mediosPago': data['mediosPago'] ?? [],
            'infoPagos': data['infoPagos'] ?? {},
            // <<--- booleanos añadidos
            'accesibilidad': data['accesibilidad'] ?? false,
            'parqueadero': data['parqueadero'] ?? false,
          });
        } else {
          debugPrint('⚠️ Evento no encontrado: $eventId');
        }
      }

      if (mounted) {
        setState(() {
          favoriteEvents = loadedEvents;
          _loadingFavorites = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingFavorites = false);
      }
      debugPrint("❌ Error cargando favoritos: $e");
    }
  }

  Future<void> _setupEventListeners() async {
    setState(() {
      _loadingEvents = true;
      events = [];
    });

    try {
      Query query;
      final userId = widget.user.uid;

      debugPrint("🟢 Usuario: $tipoPersona | ID: $userId");

      if (tipoPersona == "Administrador") {
        query = FirebaseFirestore.instance
            .collection('eventos')
            .orderBy('fechaTimestamp', descending: true);
      } else if (tipoPersona == "Empresario") {
        final userDoc =
            await FirebaseFirestore.instance
                .collection('usuarios')
                .doc(userId)
                .get();

        if (userDoc.data()?['tipoPersona'] != 'Empresario') {
          throw Exception('El usuario no tiene permisos de empresario');
        }

        query = FirebaseFirestore.instance
            .collection('eventos')
            .where('creatorId', isEqualTo: userId)
            .orderBy('fechaTimestamp', descending: true);
      } else {
        // Usuarios normales sólo ven approved
        query = FirebaseFirestore.instance
            .collection('eventos')
            .where('status', isEqualTo: 'approved')
            .orderBy('fechaTimestamp', descending: true);

        // filtros opcionales (si aplican)
        if (selectedLocalidad != null && selectedLocalidad != "Todos") {
          query = query.where('zona', isEqualTo: selectedLocalidad);
        }
        if (selectedTipo != null && selectedTipo != "Todos") {
          query = query.where('tipo', isEqualTo: selectedTipo);
        }
      }

      query.snapshots().listen(
        (snapshot) {
          if (!mounted) return;

          final newEvents =
              snapshot.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>? ?? {};
                final rawStatus =
                    (data['status'] ?? '').toString().trim().toLowerCase();

                // Añadimos accesibilidad y parqueadero aquí
                final accesibilidadVal =
                    data.containsKey('accesibilidad')
                        ? data['accesibilidad']
                        : false;
                final parqueaderoVal =
                    data.containsKey('parqueadero')
                        ? data['parqueadero']
                        : false;

                debugPrint(
                  "✅ Evento encontrado: ${data['eventName']} | status: $rawStatus | accesibilidad: $accesibilidadVal | parqueadero: $parqueaderoVal",
                );

                return {
                  'id': doc.id,
                  'eventName': data['eventName'] ?? 'Evento sin nombre',
                  'status': rawStatus,
                  'image': data['image'] ?? '',
                  'localidad':
                      data['zona'] ??
                      data['direccion'] ??
                      'Ubicación desconocida',
                  'fecha': _formatDate(data['fechaTimestamp'] ?? data['fecha']),
                  'fechaRaw': data['fecha'] ?? '',
                  'tipo': data['tipo'] ?? 'General',
                  'creatorId': data['creatorId'] ?? '',
                  'descripcion': data['descripcion'] ?? 'Sin descripción',
                  'direccion': data['direccion'] ?? data['address'] ?? '',
                  'costo': data['costo'],
                  'esGratis': data['esGratis'] ?? false,
                  'hora': data['hora'] ?? '',
                  'contacto': data['contacto'] ?? '',
                  'zona': data['zona'] ?? '',
                  // <<--- AQUI los booleanos
                  'accesibilidad': accesibilidadVal ?? false,
                  'parqueadero': parqueaderoVal ?? false,
                };
              }).toList();

          debugPrint(
            "📌 Eventos recibidos (${tipoPersona}): ${newEvents.length}",
          );

          if (mounted) {
            setState(() {
              events = newEvents;
              _loadingEvents = false;
              _filterEvents();
            });
          }
        },
        onError: (e) {
          debugPrint("❌ Error en stream: ${e.toString()}");
          if (mounted) {
            setState(() => _loadingEvents = false);
            _showErrorSnackBar("Error en tiempo real: ${e.toString()}");
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _loadingEvents = false);
        _showErrorSnackBar("Error al cargar eventos: ${e.toString()}");
      }
      debugPrint("❌ Error en _setupEventListeners: ${e.toString()}");
    }
  }

  // Formatear fecha desde diferentes formatos
  String _formatDate(dynamic date) {
    if (date == null) return 'Sin fecha';
    if (date is String) return date;
    if (date is Timestamp) {
      final dateTime = date.toDate(); // Eliminamos el cast innecesario
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
    if (date is DateTime) {
      return '${date.day}/${date.month}/${date.year}';
    }
    return date.toString();
  }

  // Filtrar eventos según búsqueda y filtros
  void _filterEvents() {
    final query = searchController.text.toLowerCase();

    setState(() {
      filteredEvents =
          events.where((event) {
            final nombre = (event['eventName'] ?? '').toString().toLowerCase();
            final localidad = (event['localidad'] ?? 'Todos').toString();
            final entrada =
                (event['esGratis'] == true || (event['costo'] ?? 0) == 0)
                    ? "Gratis"
                    : "De pago";
            final tipo = (event['tipo'] ?? "Todos").toString();

            // Validaciones de filtros
            final matchSearch = nombre.contains(query);
            final matchLocalidad =
                (selectedLocalidad == "Todos" ||
                    localidad == selectedLocalidad);
            final matchEntrada =
                (selectedEntrada == "Todos" || entrada == selectedEntrada);
            final matchTipo = (selectedTipo == "Todos" || tipo == selectedTipo);

            final include =
                matchSearch && matchLocalidad && matchEntrada && matchTipo;

            debugPrint(
              "🔎 Evaluando: ${event['eventName'] ?? 'sin nombre'} "
              "| Localidad: $localidad | Entrada: $entrada | Tipo: $tipo "
              "| Search: $matchSearch | Loc: $matchLocalidad | Entrada: $matchEntrada | Tipo: $matchTipo "
              "=> ${include ? "✅ INCLUIDO" : "❌ FILTRADO"}",
            );

            return include;
          }).toList();

      debugPrint("📊 Total después de filtros: ${filteredEvents.length}");
    });
  }

  // tarjeta favoritos
  Future<void> _toggleFavorite(Map<String, dynamic> event) async {
    try {
      final userId = widget.user.uid;
      final eventId = event['id'];

      final favoritesRef = FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .collection('favoritos');

      final doc = await favoritesRef.doc(eventId).get();

      if (doc.exists) {
        // 🔴 Si ya está en favoritos, lo eliminamos
        await favoritesRef.doc(eventId).delete();
        _showSuccessFeedback("Removido de favoritos");
      } else {
        // 🟢 Si no está, lo agregamos con toda la info
        final favoriteData = {
          'id': eventId,
          'name': event['name'] ?? event['eventName'] ?? 'Evento sin nombre',
          'image': event['image'] ?? '',
          'localidad': event['direccion'] ?? 'Ubicación desconocida',
          'fecha': _formatDate(event['fechaTimestamp'] ?? event['fecha']),
          'fechaRaw': event['fecha'] ?? '',
          'tipo': event['tipo'] ?? 'General',
          'status': event['status'] ?? 'pending',
          'creatorId': event['creatorId'] ?? '',
          'descripcion': event['descripcion'] ?? 'Sin descripción',
          'costo': event['costo'],
          'esGratis': event['esGratis'] ?? false,
          'hora': event['hora'] ?? '',
          'contacto': event['contacto'] ?? '',
          'zona': event['zona'] ?? '',
          // <<--- booleanos
          'accesibilidad': event['accesibilidad'] ?? false,
          'parqueadero': event['parqueadero'] ?? false,
          'addedAt': FieldValue.serverTimestamp(),
        };

        await favoritesRef.doc(eventId).set(favoriteData);
        _showSuccessFeedback("Agregado a favoritos");
      }

      // 🔄 Recarga la lista local de favoritos
      await _loadFavorites();
    } catch (e) {
      _showErrorSnackBar("Error: ${e.toString()}");
      debugPrint("Error en favoritos: $e");
    }
  }

  // Mostrar panel de administración
  String _getStatusText(String status) {
    switch (status) {
      case 'approved':
        return 'Aprobado';
      case 'rejected':
        return 'Rechazado';
      case 'pending':
        return 'Pendiente';
      case 'all':
        return 'Todos';
      default:
        return status;
    }
  }

  // Mostrar panel de administración
  void _showAdminPanel() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return DefaultTabController(
          // ✅ Aquí va el TabController
          length: 4,
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.85,
            minChildSize: 0.6,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Column(
                    children: [
                      // Handle
                      Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // Título
                      const Text(
                        "Panel de Administración",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Tabs
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: TabBar(
                          isScrollable: false, // ✅ Centrado y ancho total
                          labelColor: Colors.black,
                          unselectedLabelColor: Colors.grey,
                          indicator: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              30,
                            ), // ✅ forma de pastilla
                          ),
                          indicatorSize:
                              TabBarIndicatorSize
                                  .label, // ✅ el indicador se ajusta al texto
                          labelPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ), // ✅ más aire
                          tabs: const [
                            Tab(text: "Pendientes"),
                            Tab(text: "Aprobados"),
                            Tab(text: "Rechazados"),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),
                      // Contenido de Tabs
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildAdminEventList('pending'),
                            _buildAdminEventList('approved'),
                            _buildAdminEventList('rejected'),
                            _buildAdminEventList('all'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Construir lista de eventos para administrador
  Widget _buildAdminEventList(String status) {
    final bool isAdmin = true;

    Query query;

    if (status == 'all') {
      query = FirebaseFirestore.instance
          .collection('eventos')
          .orderBy('fechaTimestamp', descending: true);
    } else {
      query = FirebaseFirestore.instance
          .collection('eventos')
          .where('status', isEqualTo: status)
          .orderBy('fechaTimestamp', descending: true);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.event_available, size: 50, color: Colors.grey),
                const SizedBox(height: 10),
                Text("No hay eventos ${_getStatusText(status)}"),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border(
                  left: BorderSide(
                    color: _getColorForStatus(data['status'] ?? ''),
                    width: 6,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Imagen del evento
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child:
                          data['image'] != null && data['image'].isNotEmpty
                              ? Image.network(
                                data['image'],
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (_, __, ___) => Icon(Icons.event, size: 60),
                              )
                              : Icon(Icons.event, size: 60),
                    ),

                    const SizedBox(width: 14),

                    // Información del evento
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nombre + icono de estado
                          Row(
                            children: [
                              Icon(
                                data['status'] == 'approved'
                                    ? Icons.check_circle
                                    : data['status'] == 'rejected'
                                    ? Icons.cancel
                                    : Icons.pending,
                                size: 18,
                                color: _getColorForStatus(data['status']),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  data['eventName'] ?? 'Evento sin nombre',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Estado: ${_getStatusText(data['status'])}",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            "Fecha: ${_formatDate(data['fechaTimestamp'])}",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                          if (data['status'] == 'rejected' &&
                              data['rejectionReason'] != null)
                            Text(
                              "Razón: ${data['rejectionReason']}",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.red[300],
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Acciones
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Tooltip(
                          message: 'Ver detalles',
                          child: IconButton(
                            icon: Icon(
                              Icons.info_outline,
                              color: Colors.blueAccent,
                            ),
                            onPressed: () => _showEventDetailsAdmin(data),
                          ),
                        ),
                        if (data['status'] == 'pending') ...[
                          Tooltip(
                            message: 'Aprobar',
                            child: IconButton(
                              icon: Icon(Icons.check, color: Colors.green),
                              onPressed:
                                  () =>
                                      _approveEvent(doc.id, data['creatorId']),
                            ),
                          ),
                          Tooltip(
                            message: 'Rechazar',
                            child: IconButton(
                              icon: Icon(Icons.close, color: Colors.red),
                              onPressed:
                                  () => _rejectEvent(doc.id, data['creatorId']),
                            ),
                          ),
                        ],
                        if (isAdmin)
                          Tooltip(
                            message: 'Eliminar',
                            child: IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: Colors.grey,
                              ),
                              onPressed: () => _confirmDeleteEvent(doc.id),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  //Muestra los eventos en el panel de admin
  void _showEventDetailsAdmin(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(data['eventName'] ?? 'Evento sin nombre'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (data['image'] != null &&
                      data['image'].toString().isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        data['image'],
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) => Icon(Icons.event, size: 100),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    "Estado: ${_getStatusText(data['status'] ?? '')}",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text("Fecha: ${_formatDate(data['fechaTimestamp'])}"),
                  const SizedBox(height: 6),
                  if ((data['status'] ?? '') == 'rejected' &&
                      (data['rejectionReason'] ?? '').toString().isNotEmpty)
                    Text("Razón de rechazo: ${data['rejectionReason']}"),
                  const SizedBox(height: 6),
                  if ((data['creatorId'] ?? '').toString().isNotEmpty)
                    Text("ID del creador: ${data['creatorId']}"),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cerrar"),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteEvent(String eventId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Eliminar evento"),
            content: Text(
              "¿Estás seguro de que quieres eliminar este evento? Esta acción no se puede deshacer.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancelar"),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await FirebaseFirestore.instance
                      .collection('eventos')
                      .doc(eventId)
                      .delete();
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("Evento eliminado.")));
                },
                child: Text("Eliminar", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  // Mantén solo una versión de este método (elimina la duplicada)
  Future<void> _notifyUser(String userId, String title, String message) async {
    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .collection('notificaciones')
          .add({
            'titulo': title,
            'mensaje': message,
            'fecha': FieldValue.serverTimestamp(),
            'leida': false,
          });
    } catch (e) {
      debugPrint("Error enviando notificación: $e");
    }
  }

  Future<void> _approveEvent(String eventId, String creatorId) async {
    try {
      await FirebaseFirestore.instance
          .collection('eventos')
          .doc(eventId)
          .update({
            'status': 'approved',
            'reviewedAt': FieldValue.serverTimestamp(),
            'reviewedBy': widget.user.uid,
          });

      await _notifyUser(
        creatorId,
        "Evento Aprobado",
        "Tu evento ha sido aprobado por el administrador",
      );

      _showSuccessFeedback("Evento aprobado");
      if (mounted) setState(() {});
    } catch (e) {
      _showErrorSnackBar("Error al aprobar evento: ${e.toString()}");
    }
  }

  Future<void> _rejectEvent(String eventId, String creatorId) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text("Razón de rechazo"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: "Ingrese la razón del rechazo",
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text("Confirmar"),
            ),
          ],
        );
      },
    );

    if (reason != null && reason.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('eventos')
            .doc(eventId)
            .update({
              'status': 'rejected',
              'rejectionReason': reason,
              'reviewedAt': FieldValue.serverTimestamp(),
              'reviewedBy': widget.user.uid,
            });

        await _notifyUser(
          creatorId,
          "Evento Rechazado",
          "Tu evento fue rechazado. Razón: $reason",
        );

        _showSuccessFeedback("Evento rechazado");
      } catch (e) {
        _showErrorSnackBar("Error al rechazar evento: ${e.toString()}");
      }
    }
  }

  // Notificar al usuario en la app

  // Mostrar diálogo de mis eventos
  Future<void> _showMyEventsDialog() async {
    try {
      if (tipoPersona != "Empresario" && tipoPersona != "Administrador") {
        _showErrorSnackBar("Acceso solo para empresarios y administradores");
        return;
      }

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) {
          return DefaultTabController(
            length: 3, // ✅ Solo 3 pestañas para empresario
            child: DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.85,
              minChildSize: 0.6,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Column(
                      children: [
                        // Handle
                        Container(
                          margin: const EdgeInsets.only(top: 12, bottom: 8),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        // Título
                        Text(
                          tipoPersona == "Administrador"
                              ? "Panel de Administración"
                              : "Mis Eventos",
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Tabs
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: TabBar(
                            isScrollable: false, // ✅ Centrado y ancho total
                            labelColor: Colors.black,
                            unselectedLabelColor: Colors.grey,
                            indicator: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                30,
                              ), // ✅ forma de pastilla
                            ),
                            indicatorSize:
                                TabBarIndicatorSize
                                    .label, // ✅ el indicador se ajusta al texto
                            labelPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ), // ✅ más aire
                            tabs: const [
                              Tab(text: "Pendientes"),
                              Tab(text: "Aprobados"),
                              Tab(text: "Rechazados"),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Contenido Tabs
                        Expanded(
                          child: TabBarView(
                            children: [
                              _buildEmpresarioEventList('pending'),
                              _buildEmpresarioEventList('approved'),
                              _buildEmpresarioEventList('rejected'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      );
    } catch (e) {
      debugPrint("Error en diálogo mis eventos: $e");
      _showErrorSnackBar("Error: ${e.toString()}");
    }
  }

  //build empresario
  Widget _buildEmpresarioEventList(String status) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('eventos')
              .where('creatorId', isEqualTo: widget.user.uid)
              .where('status', isEqualTo: status)
              .orderBy('fechaTimestamp', descending: true)
              .snapshots(),

      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pending, size: 50, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text(
                  "No hay eventos ${_getStatusText(status).toLowerCase()}",
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(8),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;

            return Card(
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['eventName'] ?? 'Evento sin nombre',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Chip(
                            label: Text(
                              _getStatusText(status),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            backgroundColor: _getColorForStatus(status),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 8),
                    if (data['descripcion'] != null)
                      Text(
                        data['descripcion'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    SizedBox(height: 12),
                    _buildEventInfoRow(
                      Icons.calendar_today,
                      _formatDate(data['fechaTimestamp']) +
                          ' • ${data['hora'] ?? ''}',
                    ),
                    _buildEventInfoRow(
                      Icons.location_on,
                      data['direccion'] ?? 'Dirección no especificada',
                    ),

                    // Mostrar razón de rechazo si está disponible
                    if (status == 'rejected' && data['rejectionReason'] != null)
                      Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red[100]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.warning,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Razón del rechazo:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              Text(data['rejectionReason']),
                              SizedBox(height: 8),
                              Text(
                                'Debes crear un nuevo evento con las correcciones necesarias',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  //widget que sirve para el panel de empresario
  Widget _buildEventInfoRow(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Color _getColorForStatus(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // Confirmar cierre de sesión
  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Cerrar sesión"),
            content: const Text(
              "¿Estás seguro de que quieres salir de tu cuenta?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancelar"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Salir", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await _logout();
    }
  }

  // Cerrar sesión
  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/welcome');
        _showSuccessFeedback("Sesión cerrada con éxito");
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar("Error al cerrar sesión");
      }
      debugPrint("Error en logout: $e");
    }
  }

  // Actualizar nombre de usuario
  Future<void> _updateUserName() async {
    if (nameController.text.isEmpty) {
      _showErrorSnackBar("El nombre no puede estar vacío");
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.user.uid)
          .update({'nombre': nameController.text});

      setState(() => userName = nameController.text);
      _showSuccessFeedback("Nombre actualizado");
    } catch (e) {
      _showErrorSnackBar("Error al actualizar el nombre");
      debugPrint("Error actualizando nombre: $e");
    }
  }

  // Restablecer contraseña
  Future<void> _resetPassword() async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: widget.user.email!,
      );
      _showSuccessFeedback("Correo de recuperación enviado");
    } catch (e) {
      _showErrorSnackBar("Error al enviar correo de recuperación");
      debugPrint("Error reset password: $e");
    }
  }

  // Métodos de UI helpers
  void _showSuccessFeedback(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: NestedScrollView(
        headerSliverBuilder:
            (context, innerBoxIsScrolled) => [
              // AppBar superior con acciones
              SliverAppBar(
                automaticallyImplyLeading: false,
                pinned: true,
                floating: true,
                elevation: 0,
                backgroundColor: Colors.white,
                toolbarHeight: kToolbarHeight,
                actions: [
  // 👤 Usuario normal → Mis reservas
  if (tipoPersona == "Usuario")
    IconButton(
      icon: const Icon(
        Icons.event_available_rounded,
        size: 28,
        color: Colors.black,
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MisReservasScreen()),
        );
      },
    ),

  // 🏢 Empresario → crear eventos
  if (tipoPersona == "Empresario") ...[
    IconButton(
      icon: const Icon(
        Icons.add_box_rounded,
        size: 28,
        color: Colors.black,
      ),
      onPressed: () => _showAddEventDialog(),
    ),
    IconButton(
      icon: const Icon(
        Icons.people_alt_rounded,
        size: 28,
        color: Colors.black,
      ),
      onPressed: () {
        // 👥 Ir a la pantalla de asistentes
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MisEventosEmpresarioScreen()),
        );
      },
    ),
  ],

  // 🛠️ Administrador → panel admin
  if (tipoPersona == "Administrador")
    IconButton(
      icon: const Icon(
        Icons.admin_panel_settings,
        size: 28,
        color: Colors.black,
      ),
      onPressed: _showAdminPanel,
    ),

  // 🚪 Logout (para todos)
  IconButton(
    icon: const Icon(
      Icons.logout,
      size: 28,
      color: Colors.black,
    ),
    onPressed: _confirmLogout,
  ),
],

              ),
            ],
        body: Column(
          children: [
            // Sección del usuario (ahora se desplazará con el scroll)
            _buildUserHeader(),

            // Barra de búsqueda (solo si no está en perfil)
            if (_selectedIndex != 2) _buildSearchAndFilter(),

            // Contenido principal
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await _setupEventListeners();
                  await _loadFavorites();
                },
                child: _buildCurrentScreen(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          if (index != 2 && events.isEmpty) {
            _setupEventListeners();
          }
        },
      ),
    );
  }

  // Mostrar diálogo para agregar evento (con solicitud de teléfono)
  Future<void> _showAddEventDialog() async {
    // Verificar si ya tiene teléfono registrado
    if (telefono.isEmpty) {
      final phone = await showDialog<String>(
        context: context,
        builder: (context) {
          final controller = TextEditingController();
          return AlertDialog(
            title: const Text("Número telefónico"),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: "Ingrese su número telefónico",
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancelar"),
              ),
              TextButton(
                onPressed: () {
                  if (controller.text.isNotEmpty) {
                    Navigator.pop(context, controller.text);
                  }
                },
                child: const Text("Guardar"),
              ),
            ],
          );
        },
      );

      if (phone != null) {
        try {
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(widget.user.uid)
              .update({'telefono': phone});

          setState(() {
            telefono = phone;
            phoneController.text = phone;
          });

          // Ahora que tiene teléfono, puede proceder a agregar evento
          _navigateToAddEventScreen();
        } catch (e) {
          _showErrorSnackBar("Error al guardar teléfono");
        }
      }
    } else {
      // Ya tiene teléfono, proceder directamente
      _navigateToAddEventScreen();
    }
  }

  // Navegar a la pantalla de agregar evento
  void _navigateToAddEventScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AgregarEventoScreen(user: widget.user),
      ),
    ).then((_) {
      // Recargar eventos al regresar
      _setupEventListeners();
    });
  }

  // Widgets de construcción de UI
  Widget _buildUserHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: Lottie.asset('assets/user.json'),
          ),
          const SizedBox(height: 10),
          Text(
            userName,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(email, style: const TextStyle(color: Colors.grey)),
          if (telefono.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text("Tel: $telefono", style: const TextStyle(color: Colors.grey)),
          ],
        ],
      ),
    );
  }

  //FILTRO BUSCAR
  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // 🔍 Campo de búsqueda
          Expanded(
            child: TextField(
              controller: searchController,
              onChanged: (_) => _filterEvents(), // Filtra en tiempo real
              decoration: InputDecoration(
                hintText: 'Buscar eventos...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 12,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // ⚙️ Botón de filtros
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: "Filtros",
            onPressed: () {
              FilterModal.show(
                context: context,
                currentEntrada: selectedEntrada, // 🎟 Entrada
                currentLocalidad: selectedLocalidad, // 📍 Localidad
                currentTipo: selectedTipo, // 🎉 Tipo de evento
                onApply: (localidad, entrada, tipo) {
                  setState(() {
                    selectedLocalidad = localidad; // 📍 Localidad
                    selectedEntrada = entrada; // 🎟 Entrada
                    selectedTipo = tipo; // 🎉 Tipo
                  });
                  _filterEvents();
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentScreen() {
    if (!_initialDataLoaded) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 10),
            Text("Cargando datos iniciales..."),
          ],
        ),
      );
    }

    switch (_selectedIndex) {
      case 1: // Favoritos
        return _buildFavoritesContent();
      case 2: // Perfil
        return _buildProfileContent();
      default: // Eventos
        return _buildEventsContent();
    }
  }

  Widget _buildEventsContent() {
    if (_loadingEvents) {
      return Center(child: CircularProgressIndicator());
    }
    return _buildEventsGrid();
  }

  Widget _buildFavoritesContent() {
    if (_loadingFavorites) {
      return Center(child: CircularProgressIndicator());
    }
    return _buildFavoritesScreen();
  }

  Widget _buildProfileContent() {
    if (_loadingUser) {
      return Center(child: CircularProgressIndicator());
    }
    return UserProfileSection(
      user: widget.user,
      userName: userName,
      email: email,
      cedula: cedula,
      phoneNumber: telefono,
      nameController: nameController,
      phoneController: phoneController,
      onUpdate: _updateUserName,
      onPhoneUpdate: (newPhone) async {
        try {
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(widget.user.uid)
              .update({'telefono': newPhone});
          setState(() => telefono = newPhone);
          _showSuccessFeedback("Teléfono actualizado");
        } catch (e) {
          _showErrorSnackBar("Error al actualizar teléfono");
        }
      },
      onResetPassword: _resetPassword,
      onLogout: _confirmLogout,
    );
  }

  Widget _buildEventsGrid() {
    if (_loadingEvents) {
      return const Center(child: CircularProgressIndicator());
    }

    if (filteredEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_available, size: 50, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              events.isEmpty
                  ? "No hay eventos disponibles"
                  : "No hay coincidencias con los filtros",
              style: const TextStyle(fontSize: 18),
            ),
            if (events.isEmpty) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: _setupEventListeners,
                child: const Text("Recargar eventos"),
              ),
            ],
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12.0),
      shrinkWrap: true, // evita altura infinita dentro de otros scrolls
      physics: const ClampingScrollPhysics(), // scroll del grid
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 350, // ancho máximo por tarjeta
        mainAxisExtent: 390, // 🔑 altura fija suficiente para tu EventCard
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
      ),
      itemCount: filteredEvents.length,
      itemBuilder: (context, index) {
        final event = filteredEvents[index];
        return EventCard(
          event: event,
          eventId: event['id'],
          isFavorite: favoriteEvents.any((e) => e['id'] == event['id']),
          onToggleFavorite: _toggleFavorite,
        );
      },
    );
  }

  Widget _buildFavoritesScreen() {
    if (_loadingFavorites) {
      return const Center(child: CircularProgressIndicator());
    }

    if (favoriteEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_border, size: 50, color: Colors.grey),
            const SizedBox(height: 10),
            const Text("No tienes eventos favoritos"),
            TextButton(
              onPressed: () => setState(() => _selectedIndex = 0),
              child: const Text("Explorar eventos"),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12.0),
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 350,
        mainAxisExtent: 400, // 🔑 igual que arriba para consistencia
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: favoriteEvents.length,
      itemBuilder: (context, index) {
        final event = favoriteEvents[index];

        return EventCard(
          event: event,
          eventId: event['id'],
          isFavorite: true, // en favoritos siempre es true
          onToggleFavorite: _toggleFavorite,
        );
      },
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    searchController.dispose();
    phoneController.dispose();
    super.dispose();
  }
}
