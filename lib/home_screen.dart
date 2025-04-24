// home_screen.dart (versión refactorizada)
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'agregar_evento_screen.dart';

// Importamos los nuevos widgets que crearemos
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
  int _selectedIndex = 0;
  
  // Controladores
  TextEditingController nameController = TextEditingController();
  TextEditingController searchController = TextEditingController();
  
  // Listas y filtros
  List<Map<String, dynamic>> events = [];
  List<Map<String, dynamic>> filteredEvents = [];
  List<Map<String, dynamic>> favoriteEvents = [];
  
  String selectedFilter = "Todos";
  String selectedDate = "Todas";
  String selectedType = "Todos";

  Future<void> _approveEvent(String eventId) async {
  await FirebaseFirestore.instance
      .collection('eventos')
      .doc(eventId)
      .update({'status': 'approved'});
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("Evento aprobado")),
  );
}

Future<void> _rejectEvent(String eventId) async {
  final reason = await showDialog<String>(
    context: context,
    builder: (context) {
      final controller = TextEditingController();
      return AlertDialog(
        title: Text("Razón de rechazo"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: "Ingrese la razón"),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text("Enviar"),
          ),
        ],
      );
    },
  );

  if (reason != null) {
    await FirebaseFirestore.instance
        .collection('eventos')
        .doc(eventId)
        .update({
          'status': 'rejected',
          'rejectionReason': reason,
          'rejectedAt': FieldValue.serverTimestamp(),
          'reviewedBy': widget.user.uid,
        });
  }
}

  @override
  void initState() {
    super.initState();
    _verifyEventStructure(); // Solo una llamada aquí
    _getUserData();
    _setupEventListeners();
    searchController.addListener(_filterEvents);
  }

  // 1. Mejoramos la carga de datos con Stream para actualizaciones en tiempo real
  void _setupEventListeners() {
  FirebaseFirestore.instance
      .collection('eventos')
      //.where('status', isEqualTo: 'approved') // Elimina esto si no existe
      .orderBy('fecha', descending: true) // Usa 'fecha' en lugar de 'createdAt'
      .snapshots()
      .listen((snapshot) {
    if (mounted) {
      setState(() {
        events = snapshot.docs.map((doc) {
  final data = doc.data() as Map<String, dynamic>;
  return {
    'id': doc.id,
    'name': _getString(data, ['eventName', 'nombre']),
    'image': _getString(data, ['image', 'imagen'], defaultValue: 'https://via.placeholder.com/400'),
    'localidad': _getString(data, ['localidad', 'ubicacion']),
    'fecha': _formatDate(data['fecha'] ?? data['fechaTimestamp']),
    'tipo': _getString(data, ['tipo']),
    'descripcion': _getString(data, ['descripcion']),
    'createdAt': data['createdAt'] is Timestamp 
        ? data['createdAt'] 
        : Timestamp.now(),
    'creatorId': _getString(data, ['creatorId', 'empresarioId', 'createdBy']),
  };
}).toList();
        _filterEvents();
      });
    }
  });
}
String _getString(Map<String, dynamic> data, List<String> possibleKeys, {String? defaultValue}) {
  for (var key in possibleKeys) {
    if (data[key] != null && data[key] is String) {
      return data[key];
    }
  }
  return defaultValue ?? '';
}

String _formatDate(dynamic date) {
  if (date == null) return 'Sin fecha';
  if (date is String) return date;
  if (date is Timestamp) {
    final DateTime dt = date.toDate();
    return '${dt.day}/${dt.month}/${dt.year}';
  }
  if (date is DateTime) {
    return '${date.day}/${date.month}/${date.year}';
  }
  return date.toString();
}

  // Método para formatear la fecha
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Sin fecha';
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  // 2. Verificación de estructura de eventos

// Método único de verificación - ¡Solo debe existir una vez!
  Future<void> _verifyEventStructure() async {
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('eventos')
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      debugPrint("No hay eventos en la colección");
      return;
    }

    final eventData = snapshot.docs.first.data();
    debugPrint("Estructura actual del evento:");
    debugPrint(eventData.toString());
    
    // Verifica campos existentes en lugar de los esperados
    if (eventData['nombre'] == null) {
      debugPrint("Advertencia: Campo 'nombre' no encontrado (se usa como nombre del evento)");
    }
    if (eventData['fecha'] == null) {
      debugPrint("Advertencia: Campo 'fecha' no encontrado (se usa para ordenar)");
    }
  } catch (e) {
    debugPrint("Error verificando estructura: $e");
  }
}
  // 2. Mejoramos el manejo de errores
  Future<void> _getUserData() async {
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
          nameController.text = userName;
        });
      }
    } catch (e) {
      _showErrorSnackBar("Error al cargar datos del usuario");
      debugPrint("Error al cargar datos: $e");
    }
  }

  // 3. Filtrado mejorado con búsqueda
  void _filterEvents() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredEvents = events.where((event) {
        final matchesSearch = event["name"]!.toLowerCase().contains(query);
        final matchesLocation = selectedFilter == "Todos" || 
                              event["localidad"] == selectedFilter;
        final matchesDate = selectedDate == "Todas" || 
                           event["fecha"] == selectedDate;
        final matchesType = selectedType == "Todos" || 
                          event["tipo"] == selectedType;
        
        return matchesSearch && matchesLocation && matchesDate && matchesType;
      }).toList();
    });
  }

  // 4. Manejo de favoritos con persistencia en Firestore
  Future<void> _toggleFavorite(Map<String, dynamic> event) async {
    try {
      final userId = widget.user.uid;
      final eventId = event['id'];
      final favoritesRef = FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .collection('favoritos');
      
      if (favoriteEvents.any((e) => e['id'] == eventId)) {
        await favoritesRef.doc(eventId).delete();
        setState(() {
          favoriteEvents.removeWhere((e) => e['id'] == eventId);
        });
        _showSuccessFeedback("assets/removed_favorite.json", "Removido de favoritos");
      } else {
        await favoritesRef.doc(eventId).set(event);
        setState(() {
          favoriteEvents.add(event);
        });
        _showSuccessFeedback("assets/added_favorite.json", "Agregado a favoritos");
      }
    } catch (e) {
      _showErrorSnackBar("Error al actualizar favoritos");
      debugPrint("Error en favoritos: $e");
    }
  }

  // 5. Feedback mejorado al usuario
  void _showSuccessFeedback(String animationPath, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Lottie.asset(animationPath, width: 40, height: 40),
            SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

void _showPendingEventsDialog() {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text("Eventos Pendientes"),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('eventos')
                .where('status', isEqualTo: 'pending')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }
              final events = snapshot.data!.docs;
              return ListView.builder(
                shrinkWrap: true,
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return ListTile(
                    title: Text(event['eventName']),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.check, color: Colors.green),
                          onPressed: () => _approveEvent(event.id),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.red),
                          onPressed: () => _rejectEvent(event.id),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      );
    },
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
      icon: Icon(Icons.calendar_today, size: 28, color: Colors.black),
      tooltip: 'Mis eventos',
      onPressed: () => _showMyEventsDialog(), // Nuevo método
    ),
    if (tipoPersona == "Empresario")
      IconButton(
        icon: Icon(Icons.add_box_rounded, size: 28, color: Colors.black),
        tooltip: 'Agregar evento',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AgregarEventoScreen(user: widget.user),
          ),
        ),
      ),
    SizedBox(width: 8),
    if (tipoPersona == "Admin")
      IconButton(
        icon: Icon(Icons.pending_actions, size: 28, color: Colors.black),
        onPressed: () => _showPendingEventsDialog(),
      ),
    IconButton(
      icon: Icon(Icons.logout, size: 28, color: Colors.black),
      tooltip: 'Cerrar sesión',
      onPressed: _confirmLogout,
    ),
  ],
),
    body: Column(
      children: [
        _buildUserHeader(),
        _buildSearchAndFilter(),
        Expanded(child: _buildCurrentScreen()),
      ],
    ),
    bottomNavigationBar: CustomBottomNavBar(
      currentIndex: _selectedIndex,
      onTap: (index) => setState(() => _selectedIndex = index),
    ),
  );
}

void _showMyEventsDialog() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text("Mis Eventos"),
      content: SizedBox(
        width: double.maxFinite,
        child: DefaultTabController(
          length: tipoPersona == "Admin" ? 4 : 3,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TabBar(
                isScrollable: true,
                tabs: [
                  if (tipoPersona == "Admin") Tab(text: "Pendientes"),
                  Tab(text: "Aprobados"),
                  Tab(text: "Rechazados"),
                  Tab(text: "Mis Creaciones"),
                ],
              ),
              SizedBox(
                height: 300,
                child: TabBarView(
                  children: [
                    if (tipoPersona == "Admin") 
                      _buildEventList('pending'),
                    _buildEventList('approved'),
                    _buildEventList('rejected'),
                    _buildMyCreatedEvents(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh),
          onPressed: () {
            Navigator.pop(context);
            _showMyEventsDialog(); // Recarga el diálogo
          },
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cerrar"),
        ),
      ],
    ),
  );
}

  Widget _buildEventList(String status) {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('eventos')
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator());
      }

      if (snapshot.hasError) {
        return Center(child: Text('Error: ${snapshot.error}'));
      }

      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return Center(child: Text('No hay eventos $status'));
      }

      final events = snapshot.data!.docs;

      return ListView.builder(
        shrinkWrap: true,
        itemCount: events.length,
        itemBuilder: (context, index) {
          final doc = events[index];
          final event = doc.data() as Map<String, dynamic>;
          
          return ListTile(
            leading: event['image'] != null 
                ? Image.network(event['image'], width: 50, height: 50)
                : Icon(Icons.event),
            title: Text(event['eventName'] ?? 'Sin nombre'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Estado: ${event['status']}"),
                if (status == 'rejected' && event['rejectionReason'] != null)
                  Text("Razón: ${event['rejectionReason']}"),
                Text("Fecha: ${event['fecha'] ?? 'Sin fecha'}"),
              ],
            ),
          );
        },
      );
    },
  );
}

Widget _buildMyCreatedEvents() {
  if (tipoPersona != "Empresario") {
    return Center(child: Text("Solo disponible para empresarios"));
  }

  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('eventos')
        .where('creatorId', isEqualTo: widget.user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator());
      }

      if (snapshot.hasError) {
        return Center(child: Text('Error: ${snapshot.error}'));
      }

      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_note, size: 50, color: Colors.grey),
              SizedBox(height: 10),
              Text("No has creado eventos aún"),
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
          
          return ListTile(
            leading: event['image'] != null 
                ? Image.network(event['image'], width: 50, height: 50)
                : Icon(Icons.event),
            title: Text(event['eventName'] ?? 'Sin nombre'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Estado: ${event['status'] ?? 'Sin estado'}"),
                if (event['status'] == 'rejected' && event['rejectionReason'] != null)
                  Text("Razón: ${event['rejectionReason']}"),
                Text("Fecha: ${event['fecha'] ?? 'Sin fecha'}"),
              ],
            ),
          );
        },
      );
    },
  );
}
// Método para confirmar cierre de sesión
Future<void> _confirmLogout() async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text("Cerrar sesión"),
      content: Text("¿Estás seguro de que quieres salir de tu cuenta?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text("Cancelar"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text("Salir", style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    await _logout();
  }
}



 // Método de logout original (asegúrate de tenerlo)
Future<void> _logout() async {
  try {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
    Navigator.pushReplacementNamed(context, '/welcome');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Sesión cerrada con éxito")),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error al cerrar sesión")),
    );
  }
}

  Widget _buildUserHeader() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
          width: 100,
          height: 100,
          child: Lottie.asset('assets/user.json'),
        ),
        const SizedBox(height: 10),
          SizedBox(height: 8),
          Text(
            userName,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(
            email,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Buscar eventos...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.filter_list),
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
    switch (_selectedIndex) {
      case 1:
        return _buildFavoritesScreen();
      case 2:
        return UserProfileSection(
          user: widget.user,
          userName: userName,
          email: email,
          cedula: cedula,
          nameController: nameController,
          onUpdate: _updateUserName,
          onResetPassword: _resetPassword,
          onLogout: _confirmLogout,
        );
      default:
        return _buildEventsGrid();
    }
  }

  Widget _buildEventsGrid() {
    if (filteredEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset('assets/no_events.json', width: 200),
            Text("No hay eventos disponibles", 
                style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(8),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.8,
        ),
        itemCount: filteredEvents.length,
        itemBuilder: (context, index) => EventCard(
          event: filteredEvents[index],
          isFavorite: favoriteEvents.any((e) => e['id'] == filteredEvents[index]['id']),
          onToggleFavorite: _toggleFavorite,
        ),
      ),
    );
  }

  Widget _buildFavoritesScreen() {
    if (favoriteEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset('assets/no_favorites.json', width: 200),
            Text("No tienes eventos favoritos",
                style: TextStyle(fontSize: 18, color: Colors.grey)),
            SizedBox(height: 16),
            TextButton(
              onPressed: () => setState(() => _selectedIndex = 0),
              child: Text("Explorar eventos"),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(8),
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
      _showSuccessFeedback("assets/success.json", "Nombre actualizado");
    } catch (e) {
      _showErrorSnackBar("Error al actualizar el nombre");
      debugPrint("Error actualizando nombre: $e");
    }
  }

  Future<void> _resetPassword() async {
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: widget.user.email!);
      _showSuccessFeedback("assets/email_sent.json", 
          "Correo de recuperación enviado");
    } catch (e) {
      _showErrorSnackBar("Error al enviar correo de recuperación");
      debugPrint("Error reset password: $e");
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    searchController.dispose();
    super.dispose();
  }
}

