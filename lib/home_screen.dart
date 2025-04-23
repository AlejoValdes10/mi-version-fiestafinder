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

  @override
  void initState() {
    super.initState();
    _getUserData();
    _setupEventListeners();
    searchController.addListener(_filterEvents);
  }

  // 1. Mejoramos la carga de datos con Stream para actualizaciones en tiempo real
  void _setupEventListeners() {
    FirebaseFirestore.instance
        .collection('eventos')
        .snapshots()
        .listen((snapshot) {
      final loadedEvents = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'name': doc['eventName'],
          'image': doc['image'],
          'localidad': doc['localidad'],
          'fecha': doc['fecha'],
          'tipo': doc['tipo'],
          'descripcion': doc['descripcion'] ?? '',
        };
      }).toList();
      
      if (mounted) {
        setState(() {
          events = loadedEvents;
          _filterEvents();
        });
      }
    });
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
        SizedBox(width: 8), // Espacio entre botones
        IconButton(
          icon: Icon(Icons.logout, size: 28, color: Colors.black),
          tooltip: 'Cerrar sesión',
          onPressed: _confirmLogout, // Método de confirmación
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