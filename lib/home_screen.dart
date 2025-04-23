import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'agregar_evento_screen.dart';
import 'package:flutter/services.dart';
import 'dart:ui'; // Para ImageFilter.blur

class HomeScreen extends StatefulWidget {
  final User user;
  const HomeScreen(this.user, {super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  String userName = "";
  String email = "";
  String cedula = "";
  String tipoPersona = "";
  String _tempSelectedFilter = "Todos"; // Temporal para localidad
  String _tempSelectedDate = "Todas";   // Temporal para fecha
  String _tempSelectedType = "Todos";   // Temporal para tipo

  TextEditingController nameController = TextEditingController();
  int _selectedIndex = 0;

  List<Map<String, String>> events = [
    {
      "name": "Concierto de Rock al Parque",
      "image": "assets/unnamed.png",
      "localidad": "Centro",
      "fecha": "2025-03-12",
      "tipo": "Amigos",
    },
  ];

  List<Map<String, String>> filteredEvents = [];
  List<Map<String, String>> favoriteEvents = [];
  TextEditingController searchController = TextEditingController();
  String selectedFilter = "Todos";
  String selectedDate = "Todas";
  String selectedType = "Todos";

  List<String> localidades = ["Todos", "Centro", "Norte", "Sur"];
  List<String> fechas = [
    "Todas",
    "2025-03-01",
    "2025-03-05",
    "2025-03-10",
    "2025-03-15",
    "2025-03-20",
  ];
  List<String> tipos = ["Todos", "Entretenimiento", "Parejas", "Amigos"];

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showCustomSnackBar(String animationPath) {
    OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).size.height / 3,
        left: MediaQuery.of(context).size.width / 2 - 75,
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(25),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: Lottie.asset(
                animationPath,
                width: 150,
                height: 150,
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context)?.insert(overlayEntry);
    Future.delayed(Duration(seconds: 3), () => overlayEntry.remove());
  }

  void _showMessageSnackBar(String message) {
    OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).size.height / 3,
        left: MediaQuery.of(context).size.width / 2 - 150,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Center(
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context)?.insert(overlayEntry);
    Future.delayed(Duration(seconds: 3), () => overlayEntry.remove());
  }

  @override
  void initState() {
    super.initState();
    _tempSelectedFilter = selectedFilter; // Inicializa con los valores actuales
    _tempSelectedDate = selectedDate;
    _tempSelectedType = selectedType;
    _getUserData();
    if (widget.user != null && widget.user.email != null) {
      _getEventsFromFirestore();
    }
    filteredEvents = events;
    searchController.addListener(_filterEvents);
  }

  Future<void> _getEventsFromFirestore() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('eventos').get();
      List<Map<String, String>> loadedEvents = [];
      for (var doc in snapshot.docs) {
        loadedEvents.add({
          'name': doc['eventName'],
          'image': doc['image'],
          'localidad': doc['localidad'],
          'fecha': doc['fecha'],
          'tipo': doc['tipo'],
        });
      }
      setState(() {
        events = loadedEvents;
        filteredEvents = events;
      });
    } catch (e) {
      print("Error al cargar los eventos: $e");
    }
  }

  Future<void> _getUserData() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.user.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        var data = doc.data() as Map<String, dynamic>;
        setState(() {
          userName = data.containsKey('nombre') ? data['nombre'] : "Usuario";
          email = widget.user.email ?? "No disponible";
          cedula = data.containsKey('numeroDocumento')
              ? data['numeroDocumento']
              : "No disponible";
          tipoPersona =
              data.containsKey('tipoPersona') ? data['tipoPersona'] : "Usuario";
          nameController.text = userName;
        });
      }
    } catch (e) {
      print("Error al cargar los datos: $e");
    }
  }

  void _filterEvents() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredEvents = events.where((event) {
        return event["name"]!.toLowerCase().contains(query) &&
            (selectedFilter == "Todos" || event["localidad"] == selectedFilter) &&
            (selectedDate == "Todas" || event["fecha"] == selectedDate) &&
            (selectedType == "Todos" || event["tipo"] == selectedType);
      }).toList();
    });
  }

  void _toggleFavorite(Map<String, String> event) {
    setState(() {
      if (favoriteEvents.contains(event)) {
        favoriteEvents.remove(event);
      } else {
        favoriteEvents.add(event);
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _updateUserName() async {
    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.user.uid)
          .update({'nombre': nameController.text});
      setState(() => userName = nameController.text);
      _showCustomSnackBar("assets/listo.json");
    } catch (e) {
      print("Error al actualizar el nombre: $e");
      _showCustomSnackBar("assets/listo.json");
    }
  }

  Future<void> _resetPassword() async {
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: widget.user.email!);
      _showMessageSnackBar("Se ha enviado un correo para restablecer la contraseña.");
    } catch (e) {
      print("Error al enviar correo de recuperación: $e");
      _showMessageSnackBar("Hubo un error al enviar el correo.");
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
      Navigator.pushReplacementNamed(context, '/welcome');
      _showSnackBar("Sesión cerrada con éxito");
    } catch (e) {
      print("Error al cerrar sesión: $e");
      _showSnackBar("Error al cerrar sesión");
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,
    extendBody: true,
    appBar: AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: _logout,
        ),
        if (tipoPersona == "Empresario")
          IconButton(
            icon: const Icon(Icons.add_box_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AgregarEventoScreen(user: widget.user),
                ),
              );
            },
          ),
      ],
    ),
    body: Column(
      children: [
        Lottie.asset('assets/user.json', width: 100, height: 100),
        Text(
          userName,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        // Botón de filtros moderno (cambia esto)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: FloatingActionButton.extended(
            onPressed: _showModernFilterModal,
            icon: Icon(Icons.tune, color: Colors.white),
            label: Text("Filtrar", style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.black,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(child: _buildScreenContent()),
      ],
    ),
    bottomNavigationBar: _buildBottomNavigationBar(),
  );
}

// Método para mostrar el modal de filtros moderno (añade esto)
void _showModernFilterModal() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.4),
    builder: (context) {
      return StatefulBuilder( // <-- Permite actualizar el modal sin cerrarlo
        builder: (BuildContext context, StateSetter setModalState) {
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              padding: EdgeInsets.fromLTRB(25, 30, 25, MediaQuery.of(context).viewInsets.bottom + 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Encabezado
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filtrar Eventos',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.black54),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Filtro de Localidad con scroll horizontal mejorado
                  _buildModernFilterSection(
                    title: "Localidad",
                    options: localidades,
                    currentSelection: _tempSelectedFilter,
                    onSelect: (value) {
                      setModalState(() { // <-- Usa setModalState para actualizar solo el modal
                        _tempSelectedFilter = value;
                      });
                    },
                  ),
                  SizedBox(height: 25),

                  // Filtro de Fecha con scroll horizontal
                  _buildModernFilterSection(
                    title: "Fecha",
                    options: fechas,
                    currentSelection: _tempSelectedDate,
                    onSelect: (value) {
                      setModalState(() {
                        _tempSelectedDate = value;
                      });
                    },
                  ),
                  SizedBox(height: 25),

                  // Filtro de Tipo
                  _buildModernFilterSection(
                    title: "Tipo de Evento",
                    options: tipos,
                    currentSelection: _tempSelectedType,
                    onSelect: (value) {
                      setModalState(() {
                        _tempSelectedType = value;
                      });
                    },
                  ),
                  SizedBox(height: 30),

                  // Botón de aplicar
                  Row(
                    children: [
                      // Botón Reset
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              _tempSelectedFilter = "Todos";
                              _tempSelectedDate = "Todas";
                              _tempSelectedType = "Todos";
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            side: BorderSide(color: Colors.black),
                          ),
                          child: Text(
                            'Reiniciar',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 15),
                      // Botón Aplicar
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() { // <-- Aquí aplica los cambios a la pantalla principal
                              selectedFilter = _tempSelectedFilter;
                              selectedDate = _tempSelectedDate;
                              selectedType = _tempSelectedType;
                              _filterEvents();
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Aplicar Filtros',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
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

// Método auxiliar para construir secciones de filtro (añade esto)
Widget _buildModernFilterSection({
  required String title,
  required List<String> options,
  required String currentSelection,
  required Function(String) onSelect,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
      ),
      SizedBox(height: 12),
      Container(
        height: 50, // Altura fija para mejor UX
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: BouncingScrollPhysics(), // Efecto de rebote
          itemCount: options.length,
          itemBuilder: (context, index) {
            final option = options[index];
            bool isSelected = currentSelection == option;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: Text(
                  option,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontSize: 14,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) => onSelect(option),
                selectedColor: Colors.black,
                backgroundColor: Colors.grey[200],
                shape: StadiumBorder(),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                labelPadding: EdgeInsets.symmetric(horizontal: 4),
              ),
            );
          },
        ),
      ),
    ],
  );
}

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -5),
          )
        ],

      ),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        child: BottomNavigationBar(
          elevation: 0,
          backgroundColor: Colors.black,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: Color.fromARGB(255, 39, 48, 176),
          unselectedItemColor: Colors.white70,
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          items: [
            BottomNavigationBarItem(
              icon: _buildSelectableIcon(0, Icons.home),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: _buildSelectableIcon(1, Icons.favorite),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: _buildSelectableIcon(2, Icons.person),
              label: '',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectableIcon(int index, IconData icon) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedIndex = index);
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.all(isSelected ? 10 : 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          shape: BoxShape.circle,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Color.fromARGB(255, 39, 48, 176),
                    blurRadius: 15,
                    spreadRadius: 2,
                    offset: Offset(0, 0),
                  ),
                ]
              : [],
        ),
        child: AnimatedScale(
          duration: Duration(milliseconds: 250),
          scale: isSelected ? 1.2 : 1.0,
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: Duration(milliseconds: 250),
            transform: Matrix4.translationValues(0, isSelected ? -6 : 0, 0),
            child: Icon(
              icon,
              size: isSelected ? 30 : 26,
              color: isSelected ? Color.fromARGB(255, 39, 48, 176) : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: items.first,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.deepPurple[50],
      ),
      items: items.map((item) => DropdownMenuItem<String>(
        value: item,
        child: Text(item),
      )).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildScreenContent() {
    return _selectedIndex == 1
        ? _buildFavoriteScreen()
        : _selectedIndex == 2
            ? _buildUserScreen()
            : _buildHomeScreen();
  }

  Widget _buildHomeScreen() {
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.7,
      ),
      itemCount: filteredEvents.length,
      itemBuilder: (context, index) => _buildEventCard(filteredEvents[index]),
    );
  }

  Widget _buildFavoriteScreen() {
    return favoriteEvents.isEmpty
        ? Center(child: Text("No hay eventos favoritos"))
        : GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.7,
            ),
            itemCount: favoriteEvents.length,
            itemBuilder: (context, index) => _buildEventCard(favoriteEvents[index]),
          );
  }

  Widget _buildUserScreen() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildUserInfoRow("Correo: ", email),
              const SizedBox(height: 10),
              _buildUserInfoRow("Cédula: ", cedula),
              const SizedBox(height: 20),
              _buildTextField(
                label: "Nombre",
                controller: nameController,
                icon: Icons.person,
              ),
              const SizedBox(height: 30),
              _buildActionButton(
                text: "Actualizar Información",
                onPressed: _updateUserName,
              ),
              const SizedBox(height: 15),
              _buildActionButton(
                text: "Restablecer Contraseña",
                onPressed: _resetPassword,
              ),
              const SizedBox(height: 30),
              _buildActionButton(
                text: "Cerrar Sesión",
                onPressed: _logout,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.info_outline, color: Colors.black, size: 20),
        const SizedBox(width: 10),
        Text(
          "$label$value",
          style: TextStyle(fontSize: 18, color: Colors.black),
        ),
      ],
    );
  }

  Widget _buildTextField({
  required String label,
  required TextEditingController controller,
  required IconData icon,
}) {
  return Container(
    width: double.infinity,
    child: TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.black),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      ),
    ),
  );
}

  Widget _buildActionButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(vertical: 18, horizontal: 30),
          elevation: 5,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(Map<String, String> event) {
    bool isFavorite = favoriteEvents.contains(event);
    return Card(
      elevation: 8.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Image.asset(
            event["image"]!,
            fit: BoxFit.cover,
            height: 120,
            width: double.infinity,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              event["name"]!,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => _toggleFavorite(event),
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}