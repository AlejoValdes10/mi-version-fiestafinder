import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'agregar_evento_screen.dart';

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
  String telefono = ""; // Nuevo campo para teléfono
  int _selectedIndex = 0;

  bool _loadingUser = true;
  bool _loadingEvents = true;
  bool _loadingFavorites = true;
  bool _initialDataLoaded = false; // Agrégalo con las otras variables de estado

  // Controladores
  final TextEditingController nameController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController phoneController =
      TextEditingController(); // Controlador para teléfono

  // Listas y filtros
  List<Map<String, dynamic>> events = [];
  List<Map<String, dynamic>> filteredEvents = [];
  List<Map<String, dynamic>> favoriteEvents = [];

  String selectedFilter = "Todos";
  String selectedDate = "Todas";
  String selectedType = "Todos";

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

      if (mounted) {
        setState(() {
          favoriteEvents =
              favoritesSnapshot.docs.map((doc) {
                final data = doc.data();
                return {
                  'id': doc.id,
                  'name': data['name'] ?? 'Evento sin nombre',
                  'image': data['image'] ?? '',
                  'fecha': data['fecha'] ?? 'Sin fecha',
                };
              }).toList();
          _loadingFavorites = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingFavorites = false);
      }
      debugPrint("Error cargando favoritos: $e");
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

      // Filtrado por tipo de usuario
      if (tipoPersona == "Administrador") {
        query = FirebaseFirestore.instance
            .collection('eventos')
            .orderBy('fechaTimestamp', descending: true);
      } else if (tipoPersona == "Empresario") {
        // Verificación explícita de permisos
        final userDoc =
            await FirebaseFirestore.instance
                .collection('usuarios')
                .doc(userId)
                .get();

        if (userDoc.data()?['tipoPersona'] != 'Empresario') {
          throw Exception('El usuario no tiene permisos de empresario');
        }

        // CONSULTA PRINCIPAL CON MANEJO DE ERRORES
        try {
          query = FirebaseFirestore.instance
              .collection('eventos')
              .where('creatorId', isEqualTo: widget.user.uid)
              .where('status', isEqualTo: 'approved') // ✅ Compatible con reglas
              .orderBy('fechaTimestamp', descending: true);

          // Prueba la consulta
          final testQuery = await query.limit(1).get();
          debugPrint(
            "✅ Consulta válida. Eventos encontrados: ${testQuery.docs.length}",
          );
        } catch (e) {
          debugPrint("🔴 Error en consulta: ${e.toString()}");
          if (e is FirebaseException && e.code == 'failed-precondition') {
            debugPrint("Se requiere índice compuesto: ${e.message}");
            // Consulta alternativa temporal
            query = FirebaseFirestore.instance
                .collection('eventos')
                .where('creatorId', isEqualTo: userId)
                .orderBy('fechaTimestamp', descending: true);
          } else {
            rethrow;
          }
        }
      } else {
        query = FirebaseFirestore.instance
            .collection('eventos')
            .where('status', isEqualTo: 'approved')
            .orderBy('fechaTimestamp', descending: true);
      }

      // Stream de eventos en tiempo real
      query.snapshots().listen(
        (snapshot) {
          if (!mounted) return;

          final newEvents =
              snapshot.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>? ?? {};
                return {
                  'id': doc.id,
                  'name': data['eventName'] ?? 'Evento sin nombre',
                  'image': data['image'] ?? '',
                  'localidad': data['direccion'] ?? 'Ubicación desconocida',
                  'fecha': _formatDate(data['fechaTimestamp'] ?? data['fecha']),
                  'tipo': data['tipo'] ?? 'General',
                  'status': data['status'] ?? 'pending',
                  'creatorId': data['creatorId'] ?? '',
                  'descripcion': data['descripcion'] ?? 'Sin descripción',
                };
              }).toList();

          if (mounted) {
            setState(() {
              events = newEvents;
              _loadingEvents = false;
              _filterEvents();
            });
          }
        },
        onError: (e) {
          debugPrint("Error en stream: ${e.toString()}");
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
      debugPrint("Error en _setupEventListeners: ${e.toString()}");
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
            final matchesSearch =
                event["name"]?.toLowerCase().contains(query) ?? false;
            final matchesLocation =
                selectedFilter == "Todos" ||
                event["localidad"] == selectedFilter;
            final matchesDate =
                selectedDate == "Todas" || event["fecha"] == selectedDate;
            final matchesType =
                selectedType == "Todos" || event["tipo"] == selectedType;

            // Para Admin/Empresario: ver todos o solo sus eventos
            if (tipoPersona == "Administrador") {
              return matchesSearch &&
                  matchesLocation &&
                  matchesDate &&
                  matchesType;
            } else if (tipoPersona == "Empresario") {
              final isMyEvent = event["creatorId"] == widget.user.uid;
              return matchesSearch &&
                  matchesLocation &&
                  matchesDate &&
                  matchesType &&
                  (isMyEvent || event["status"] == "approved");
            } else {
              // Usuario normal
              return matchesSearch &&
                  matchesLocation &&
                  matchesDate &&
                  matchesType;
            }
          }).toList();
    });
  }

  // Manejar favoritos
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
        await favoritesRef.doc(eventId).delete();
        _showSuccessFeedback("Removido de favoritos");
      } else {
        final favoriteData = {
          'id': eventId,
          'name': event['name'],
          'image': event['image'],
          'fecha': event['fecha'],
          'addedAt': FieldValue.serverTimestamp(),
        };
        await favoritesRef.doc(eventId).set(favoriteData);
        _showSuccessFeedback("Agregado a favoritos");
      }

      // Forzar recarga de favoritos
      await _loadFavorites();
    } catch (e) {
      _showErrorSnackBar("Error: ${e.toString()}");
      debugPrint("Error en favoritos: $e");
    }
  }

  // Mostrar panel de administración
  // Agrega este método en tu clase HomeScreenState
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

  Widget _getStatusIcon(String status) {
    switch (status) {
      case 'approved':
        return Icon(Icons.check_circle, color: Colors.green, size: 40);
      case 'rejected':
        return Icon(Icons.cancel, color: Colors.red, size: 40);
      case 'pending':
        return Icon(Icons.pending, color: Colors.orange, size: 40);
      default:
        return Icon(Icons.help_outline, color: Colors.grey, size: 40);
    }
  }

  // Mostrar panel de administración
  void _showAdminPanel() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Panel de Administración"),
            content: SizedBox(
              width: double.maxFinite,
              child: DefaultTabController(
                length: 4,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const TabBar(
                      isScrollable: true,
                      tabs: [
                        Tab(text: "Pendientes"),
                        Tab(text: "Aprobados"),
                        Tab(text: "Rechazados"),
                        Tab(text: "Todos"),
                      ],
                    ),
                    SizedBox(
                      height: 400,
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
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cerrar"),
              ),
            ],
          ),
    );
  }

  // Construir lista de eventos para administrador
  Widget _buildAdminEventList(String status) {
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

            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                // Mostrar imagen del evento en lugar del icono de estado
                leading:
                    data['image'] != null && data['image'].isNotEmpty
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            data['image'],
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) => Icon(Icons.event, size: 50),
                          ),
                        )
                        : Icon(Icons.event, size: 50),
                title: Row(
                  children: [
                    // Icono de estado al lado del nombre
                    if (data['status'] == 'approved')
                      Icon(Icons.check_circle, color: Colors.green, size: 24),
                    if (data['status'] == 'rejected')
                      Icon(Icons.cancel, color: Colors.red, size: 24),
                    if (data['status'] == 'pending')
                      Icon(Icons.pending, color: Colors.orange, size: 24),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        data['eventName'] ?? 'Evento sin nombre',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Estado: ${_getStatusText(data['status'])}"),
                    Text("Fecha: ${_formatDate(data['fechaTimestamp'])}"),
                    if (data['status'] == 'rejected' &&
                        data['rejectionReason'] != null)
                      Text("Razón: ${data['rejectionReason']}"),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (data['status'] == 'pending')
                      IconButton(
                        icon: Icon(Icons.check, color: Colors.green),
                        onPressed:
                            () => _approveEvent(doc.id, data['creatorId']),
                      ),
                    if (data['status'] == 'pending')
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.red),
                        onPressed:
                            () => _rejectEvent(doc.id, data['creatorId']),
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

      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text(
                tipoPersona == "Administrador"
                    ? "Panel de Administración"
                    : "Mis Eventos",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: MediaQuery.of(context).size.height * 0.7,
                child: DefaultTabController(
                  length: 3, // Solo 3 pestañas para empresario
                  child: Column(
                    children: [
                      TabBar(
                        isScrollable: true,
                        labelColor: Colors.deepPurple,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Colors.deepPurple,
                        tabs: [
                          Tab(icon: Icon(Icons.pending), text: "Pendientes"),
                          Tab(
                            icon: Icon(Icons.check_circle),
                            text: "Aprobados",
                          ),
                          Tab(icon: Icon(Icons.cancel), text: "Rechazados"),
                        ],
                      ),
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
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Cerrar",
                    style: TextStyle(color: Colors.deepPurple),
                  ),
                ),
              ],
            ),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            data['eventName'] ?? 'Evento sin nombre',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Chip(
                          label: Text(
                            _getStatusText(status),
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          backgroundColor: _getColorForStatus(status),
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
      default:
        return Colors.orange;
    }
  }

  Future<void> _resubmitEvent(String eventId) async {
    try {
      await FirebaseFirestore.instance
          .collection('eventos')
          .doc(eventId)
          .update({
            'status': 'pending',
            'rejectionReason': FieldValue.delete(),
          });

      Navigator.pop(context); // Cerrar el diálogo
      _showSuccessFeedback("Evento reenviado para revisión");
    } catch (e) {
      _showErrorSnackBar("Error al reenviar el evento: $e");
    }
  }

  Future<void> _editEvent(String eventId) async {
    // Implementa la navegación a tu pantalla de edición de eventos
    // Navigator.push(context, MaterialPageRoute(builder: (context) => EditEventScreen(eventId: eventId));
    _showSuccessFeedback("Editar evento: $eventId");
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
                  // Mostrar icono de calendario solo si NO es administrador
                  if (tipoPersona != "Administrador")
                    IconButton(
                      icon: const Icon(
                        Icons.calendar_today,
                        size: 28,
                        color: Colors.black,
                      ),
                      onPressed: _showMyEventsDialog,
                    ),
                  if (tipoPersona == "Empresario")
                    IconButton(
                      icon: const Icon(
                        Icons.add_box_rounded,
                        size: 28,
                        color: Colors.black,
                      ),
                      onPressed: () => _showAddEventDialog(),
                    ),
                  if (tipoPersona == "Administrador")
                    IconButton(
                      icon: const Icon(
                        Icons.admin_panel_settings,
                        size: 28,
                        color: Colors.black,
                      ),
                      onPressed: _showAdminPanel,
                    ),
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

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Buscar eventos...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed:
                () => FilterModal.show(
                  context: context,
                  currentFilter: selectedFilter,
                  currentDate: selectedDate,
                  currentType: selectedType,
                  onApply: (filter, date, type) {
                    setState(() {
                      selectedFilter = filter;
                      selectedDate = date;
                      selectedType = type;
                    });
                    _filterEvents();
                  },
                ),
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
      return Center(child: CircularProgressIndicator());
    }

    if (filteredEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available, size: 50, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              events.isEmpty
                  ? "No hay eventos disponibles"
                  : "No hay coincidencias con los filtros",
              style: TextStyle(fontSize: 18),
            ),
            if (events.isEmpty) ...[
              SizedBox(height: 8),
              TextButton(
                onPressed: _setupEventListeners,
                child: Text("Recargar eventos"),
              ),
            ],
          ],
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.all(8.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.8,
      ),
      itemCount: filteredEvents.length,
      itemBuilder: (context, index) {
        final event = filteredEvents[index];
        return EventCard(
          event: event,
          isFavorite: favoriteEvents.any((e) => e['id'] == event['id']),
          onToggleFavorite: _toggleFavorite,
        );
      },
    );
  }

  Widget _buildFavoritesScreen() {
    if (_loadingFavorites) {
      return Center(child: CircularProgressIndicator());
    }

    if (favoriteEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 50, color: Colors.grey),
            SizedBox(height: 10),
            Text("No tienes eventos favoritos"),
            TextButton(
              onPressed: () => setState(() => _selectedIndex = 0),
              child: Text("Explorar eventos"),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.all(8.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.8,
      ),
      itemCount: favoriteEvents.length,
      itemBuilder: (context, index) {
        final event = favoriteEvents[index];
        return EventCard(
          event: event,
          isFavorite: true,
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
