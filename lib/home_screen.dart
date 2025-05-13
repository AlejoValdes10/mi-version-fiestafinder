// home_screen.dart (versión corregida y simplificada)
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
  final TextEditingController phoneController = TextEditingController(); // Controlador para teléfono
  
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
  _loadUserData().then((_) {
    _setupEventListeners().then((_) {
      if (mounted) setState(() => _initialDataLoaded = true);
    });
  });
}


Future<void> _loadUserData() async {
  try {
    DocumentSnapshot doc = await FirebaseFirestore.instance
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
    final favoritesSnapshot = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.user.uid)
        .collection('favoritos')
        .get();
    
    if (mounted) {
      setState(() {
        favoriteEvents = favoritesSnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
      });
    }
  } catch (e) {
    debugPrint("Error cargando favoritos: $e");
  }
}

Future<void> _setupEventListeners() async {
  setState(() {
    _loadingEvents = true;
    events = [];
  });

  try {
    Query query = FirebaseFirestore.instance.collection('eventos');

    // Filtrado por tipo de usuario
    if (tipoPersona == "Administrador") {
      query = query.orderBy('fechaTimestamp', descending: true);
    } 
   else if (tipoPersona == "Empresario") {
  query = FirebaseFirestore.instance
      .collection('eventos')
      .where('creatorId', isEqualTo: widget.user.uid)
      .where('status', whereIn: ['approved', 'rejected', 'pending'])  // Filtra múltiples estados
      .orderBy('status')  // Ordena por estado primero
      .orderBy('fechaTimestamp', descending: true);  // Luego por fecha
}
    else {
      query = query.where('status', isEqualTo: 'approved')
                  .orderBy('fechaTimestamp', descending: true);
    }

    // Usar snapshots para cambios en tiempo real
    query.snapshots().listen((snapshot) {
      if (!mounted) return;
      
      final newEvents = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        return {
          'id': doc.id,
          'name': data['eventName'] ?? 'Evento sin nombre',
          'image': data['image'] ?? '',
          'localidad': data['localidad'] ?? 'Ubicación desconocida',
          'fecha': _formatDate(data['fechaTimestamp'] ?? data['fecha']),
          'tipo': data['tipo'] ?? 'General',
          'status': data['status'] ?? 'pending',
          'creatorId': data['creatorId'] ?? data['empresarioId'] ?? '',
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
    });

  } catch (e) {
    if (mounted) {
      setState(() => _loadingEvents = false);
    }
    debugPrint("Error en _setupEventListeners: $e");
    _showErrorSnackBar("Error al cargar eventos. Intente nuevamente.");
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
    filteredEvents = events.where((event) {
      final matchesSearch = event["name"]?.toLowerCase().contains(query) ?? false;
      final matchesLocation = selectedFilter == "Todos" || event["localidad"] == selectedFilter;
      final matchesDate = selectedDate == "Todas" || event["fecha"] == selectedDate;
      final matchesType = selectedType == "Todos" || event["tipo"] == selectedType;
      
      // Para Admin/Empresario: ver todos o solo sus eventos
      if (tipoPersona == "Administrador") {
        return matchesSearch && matchesLocation && matchesDate && matchesType;
      }
      else if (tipoPersona == "Empresario") {
        final isMyEvent = event["creatorId"] == widget.user.uid;
        return matchesSearch && matchesLocation && matchesDate && matchesType && 
              (isMyEvent || event["status"] == "approved");
      }
      else { // Usuario normal
        return matchesSearch && matchesLocation && matchesDate && matchesType;
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
      setState(() {
        favoriteEvents.removeWhere((e) => e['id'] == eventId);
      });
      _showSuccessFeedback("Removido de favoritos");
    } else {
      // Solo guarda los datos esenciales
      final favoriteData = {
        'id': eventId,
        'name': event['name'],
        'image': event['image'],
        'fecha': event['fecha'],
        'addedAt': FieldValue.serverTimestamp(),
      };
      
      await favoritesRef.doc(eventId).set(favoriteData);
      setState(() {
        favoriteEvents.add(favoriteData);
      });
      _showSuccessFeedback("Agregado a favoritos");
    }
  } catch (e) {
    _showErrorSnackBar("Error: ${e.toString()}");
    debugPrint("Error en favoritos: $e");
  }
}
  // Mostrar panel de administración
  void _showAdminPanel() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Panel de Administración"),
      content: SizedBox(
        width: double.maxFinite,
        child: DefaultTabController(
          length: 3, // Pestañas: Pendientes, Aprobados, Todos
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TabBar(
                tabs: [
                  Tab(text: "Pendientes"),
                  Tab(text: "Aprobados"),
                  Tab(text: "Todos"),
                ],
              ),
              SizedBox(
                height: 400,
                child: TabBarView(
                  children: [
                    _buildPendingEventsForAdmin(),
                    _buildApprovedEventsForAdmin(),
                    _buildAllEventsForAdmin(),
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

Widget _buildAllEventsForAdmin() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('eventos')
        .orderBy('fechaTimestamp', descending: true)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator());
      }

      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return Center(child: Text("No hay eventos registrados"));
      }

      return ListView.builder(
        itemCount: snapshot.data!.docs.length,
        itemBuilder: (context, index) {
          final doc = snapshot.data!.docs[index];
          final data = doc.data() as Map<String, dynamic>;
          
          return Card(
            margin: EdgeInsets.all(8),
            child: ListTile(
              leading: _getStatusIcon(data['status']),
              title: Text(data['eventName']),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Estado: ${_getStatusText(data['status'])}"),
                  Text("Fecha: ${_formatDate(data['fechaTimestamp'])}"),
                  if (data['status'] == 'rejected' && data['rejectionReason'] != null)
                    Text("Razón: ${data['rejectionReason']}"),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (data['status'] == 'pending')
                    IconButton(
                      icon: Icon(Icons.check, color: Colors.green),
                      onPressed: () => _approveEvent(doc.id, data['creatorId']),
                    ),
                  if (data['status'] == 'pending')
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.red),
                      onPressed: () => _rejectEvent(doc.id, data['creatorId']),
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

Widget _buildApprovedEventsForAdmin() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('eventos')
        .where('status', isEqualTo: 'approved')
        .orderBy('fechaTimestamp', descending: true)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator());
      }

      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return Center(child: Text("No hay eventos aprobados"));
      }

      return ListView.builder(
        itemCount: snapshot.data!.docs.length,
        itemBuilder: (context, index) {
          final doc = snapshot.data!.docs[index];
          final data = doc.data() as Map<String, dynamic>;
          
          return Card(
            margin: EdgeInsets.all(8),
            child: ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green),
              title: Text(data['eventName']),
              subtitle: Text("Fecha: ${_formatDate(data['fechaTimestamp'])}"),
            ),
          );
        },
      );
    },
  );
}

Widget _getStatusIcon(String status) {
  switch (status) {
    case 'approved': return Icon(Icons.check_circle, color: Colors.green);
    case 'rejected': return Icon(Icons.cancel, color: Colors.red);
    default: return Icon(Icons.pending, color: Colors.orange);
  }
}

String _getStatusText(String status) {
  switch (status) {
    case 'approved': return 'Aprobado';
    case 'rejected': return 'Rechazado';
    case 'pending': return 'Pendiente';
    default: return status;
  }
}

  // Construir lista de eventos pendientes para admin
  Widget _buildPendingEventsForAdmin() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('eventos')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator());
      }

      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_available, size: 50, color: Colors.grey),
              SizedBox(height: 10),
              Text("No hay eventos pendientes"),
            ],
          ),
        );
      }

      final events = snapshot.data!.docs;

      return ListView.separated(
        itemCount: events.length,
        separatorBuilder: (context, index) => Divider(height: 1),
        itemBuilder: (context, index) {
          final doc = events[index];
          final data = doc.data() as Map<String, dynamic>;
          
          return Card(
            margin: EdgeInsets.all(8),
            child: ListTile(
              contentPadding: EdgeInsets.all(12),
              leading: data['image'] != null 
                  ? Image.network(
                      data['image']!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(Icons.event, size: 50),
                    )
                  : Icon(Icons.event, size: 50),
              title: Text(data['eventName'] ?? 'Sin nombre'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Creador: ${data['creatorId']}"),
                  Text("Fecha: ${data['fecha']}"),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.check, color: Colors.green),
                    onPressed: () => _approveEvent(doc.id, data['creatorId']),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.red),
                    onPressed: () => _rejectEvent(doc.id, data['creatorId']),
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

  // Aprobar evento
  Future<void> _approveEvent(String eventId, String creatorId) async {
  try {
    await FirebaseFirestore.instance.collection('eventos').doc(eventId).update({
      'status': 'approved',
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': widget.user.uid,
    });

    // Notificar al creador del evento
    await _notifyUser(creatorId, 
      "Evento Aprobado", 
      "Tu evento ha sido aprobado por el administrador"
    );

    _showSuccessFeedback("Evento aprobado");
    
    // Forzar actualización de la lista
    _setupEventListeners();
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
        title: Text("Razón de rechazo"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: "Ingrese la razón del rechazo"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text("Confirmar"),
          ),
        ],
      );
    },
  );

  if (reason != null) {
    try {
      await FirebaseFirestore.instance.collection('eventos').doc(eventId).update({
        'status': 'rejected',
        'rejectionReason': reason,
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': widget.user.uid,
      });

      await _notifyUser(creatorId,
        "Evento Rechazado",
        "Tu evento fue rechazado. Razón: $reason"
      );

      _showSuccessFeedback("Evento rechazado");
    } catch (e) {
      _showErrorSnackBar("Error al rechazar evento: ${e.toString()}");
    }
  }
}

  // Notificar al usuario en la app
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

  // Mostrar diálogo de mis eventos
  Future<void> _showMyEventsDialog() async {
    if (tipoPersona != "Empresario" && tipoPersona != "Administrador") {
      _showErrorSnackBar("Solo disponible para empresarios y administradores");
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Mis Eventos"),
        content: SizedBox(
          width: double.maxFinite,
          child: DefaultTabController(
            length: tipoPersona == "Administrador" ? 3 : 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TabBar(
                  isScrollable: true,
                  tabs: [
                    if (tipoPersona == "Administrador") const Tab(text: "Pendientes"),
                    const Tab(text: "Aprobados"),
                    const Tab(text: "Rechazados"),
                  ],
                ),
                SizedBox(
                  height: 300,
                  child: TabBarView(
                    children: [
                      if (tipoPersona == "Administrador") 
                        _buildEventList('pending'),
                      _buildEventList('approved'),
                      _buildEventList('rejected'),
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

  // Construir lista de eventos por estado
  Widget _buildEventList(String status) {
  String collectionPath = 'eventos';
  if (tipoPersona == "Empresario") {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(collectionPath)
          .where('creatorId', isEqualTo: widget.user.uid)
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) => _buildEventListView(snapshot, status),
    );
  } else {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(collectionPath)
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) => _buildEventListView(snapshot, status),
    );
  }
}

Widget _buildEventListView(AsyncSnapshot<QuerySnapshot> snapshot, String status) {
  if (snapshot.connectionState == ConnectionState.waiting) {
    return Center(child: CircularProgressIndicator());
  }

  if (snapshot.hasError) {
    return Center(child: Text('Error: ${snapshot.error}'));
  }

  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_note, size: 50, color: Colors.grey),
          SizedBox(height: 10),
          Text('No hay eventos $status'),
        ],
      ),
    );
  }

  final events = snapshot.data!.docs;

  return ListView.builder(
    shrinkWrap: true,
    itemCount: events.length,
    itemBuilder: (context, index) {
      final doc = events[index];
      final event = doc.data() as Map<String, dynamic>;
      
      return Card(
        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          leading: SizedBox(
            width: 50,
            height: 50,
            child: event['image'] != null 
                ? Image.network(
                    event['image']!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(Icons.event),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                  )
                : Icon(Icons.event, size: 50),
          ),
          title: Text(
            event['eventName'] ?? 'Evento sin nombre',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 4),
              Text("Estado: ${event['status'] ?? 'Desconocido'}"),
              if (status == 'rejected' && event['rejectionReason'] != null)
                Column(
                  children: [
                    SizedBox(height: 4),
                    Text(
                      "Razón: ${event['rejectionReason']}",
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              SizedBox(height: 4),
              Text("Fecha: ${event['fecha'] ?? 'Sin fecha'}"),
            ],
          ),
        ),
      );
    },
  );
}
  // Confirmar cierre de sesión
  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cerrar sesión"),
        content: const Text("¿Estás seguro de que quieres salir de tu cuenta?"),
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
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: widget.user.email!);
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
    appBar: AppBar(
      automaticallyImplyLeading: false,
      title: null,
      elevation: 0,
      backgroundColor: Colors.white,
      toolbarHeight: kToolbarHeight,
      actions: [
        IconButton(
          icon: const Icon(Icons.calendar_today, size: 28, color: Colors.black),
          tooltip: 'Mis eventos',
          onPressed: _showMyEventsDialog,
        ),
        if (tipoPersona == "Empresario")
          IconButton(
            icon: const Icon(Icons.add_box_rounded, size: 28, color: Colors.black),
            tooltip: 'Agregar evento',
            onPressed: () => _showAddEventDialog(),
          ),
        if (tipoPersona == "Administrador")
          IconButton(
            icon: const Icon(Icons.admin_panel_settings, size: 28, color: Colors.black),
            tooltip: 'Panel de administración',
            onPressed: _showAdminPanel,
          ),
        IconButton(
          icon: const Icon(Icons.logout, size: 28, color: Colors.black),
          tooltip: 'Cerrar sesión',
          onPressed: _confirmLogout,
        ),
      ],
    ),
    body: Column(
      children: [
        _buildUserHeader(),
        if (_selectedIndex != 2) _buildSearchAndFilter(),
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
          Text(
            email,
            style: const TextStyle(color: Colors.grey),
          ),
          if (telefono.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              "Tel: $telefono",
              style: const TextStyle(color: Colors.grey),
            ),
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
            onPressed: () => FilterModal.show(
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
      return _buildFavoritesScreen();
    
    case 2: // Perfil de usuario
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
    
    default: // Inicio (0) - Eventos
      if (_loadingEvents) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 10),
              Text("Cargando eventos..."),
            ],
          ),
        );
      }
      if (filteredEvents.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_busy, size: 50, color: Colors.grey),
              SizedBox(height: 10),
              Text("No hay eventos disponibles"),
              if (events.isEmpty)
                TextButton(
                  onPressed: _setupEventListeners,
                  child: Text("Reintentar"),
                ),
            ],
          ),
        );
      }
      return _buildEventsGrid();
  }
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
            events.isEmpty ? "No hay eventos disponibles" : "No hay coincidencias con los filtros",
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

  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: GridView.builder(
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
    ),
  );
}

  Widget _buildFavoritesScreen() {
    if (favoriteEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset('assets/no_events.json', width: 200),
            const Text("No tienes eventos favoritos",
                style: TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => setState(() => _selectedIndex = 0),
              child: const Text("Explorar eventos"),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.8,
        ),
        itemCount: favoriteEvents.length,
        itemBuilder: (context, index) => EventCard(
          event: favoriteEvents[index],
          isFavorite: true,
          onToggleFavorite: _toggleFavorite,
        ),
      ),
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