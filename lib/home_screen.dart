import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'agregar_evento_screen.dart';

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


  @override
void initState() {
  super.initState();
  
  // Cargar los datos del usuario
  _getUserData();
  
  // Si ya está logueado, no cargues eventos inmediatamente (puedes hacerlo luego cuando sea necesario)
  if (widget.user != null && widget.user.email != null) {
  _getEventsFromFirestore();
}

  filteredEvents = events;  // Inicializar la lista de eventos filtrados
  searchController.addListener(_filterEvents);  // Escuchar cambios en la búsqueda
}


  Future<void> _getEventsFromFirestore() async {
  try {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('eventos').get();
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
      // Hacemos el cast explícito de doc.data() a Map<String, dynamic>
      var data = doc.data() as Map<String, dynamic>;

      setState(() {
        userName = data.containsKey('nombre') ? data['nombre'] : "Usuario";
        email = widget.user.email ?? "No disponible";
        cedula = data.containsKey('numeroDocumento') ? data['numeroDocumento'] : "No disponible";
        tipoPersona = data.containsKey('tipoPersona') ? data['tipoPersona'] : "Usuario";
        nameController.text = userName;
      });
    } else {
      print("El documento no existe.");
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
      setState(() {
        userName = nameController.text;
      });
    } catch (e) {
      print("Error al actualizar el nombre: $e");
    }
  }

  Future<void> _resetPassword() async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: widget.user.email!);
    } catch (e) {
      print("Error al enviar correo de recuperación: $e");
    }
  }
  Future<void> _logout() async {
  try {
    // Cerrar sesión de Firebase
    await FirebaseAuth.instance.signOut();
    
    // Cerrar sesión de Google
    await GoogleSignIn().signOut();
    
    // Redirigir a la pantalla de inicio de sesión
    Navigator.pushReplacementNamed(context, '/welcome');
  } catch (e) {
    print("Error al cerrar sesión: $e");
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  title: const Text("Fiesta Finder"),
  actions: [
    // Agregar el botón de cerrar sesión
    IconButton(
      icon: const Icon(Icons.logout),
      tooltip: "Cerrar sesión",
      onPressed: _logout,
    ),
    // Si el tipo de persona es 'Empresario', mostrar el botón de agregar evento
    if (tipoPersona == "Empresario")
      IconButton(
        icon: const Icon(Icons.add_box_rounded),
        tooltip: "Agregar Evento",
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
          Text(userName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: ElevatedButton.icon(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                  ),
                  isScrollControlled: true,
                  builder: (BuildContext context) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("Filtrar Eventos", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 20),
                          _buildDropdown("Localidad", localidades, (value) {
                            setState(() {
                              selectedFilter = value!;
                              _filterEvents();
                            });
                            Navigator.pop(context);
                          }),
                          const SizedBox(height: 15),
                          _buildDropdown("Fecha", fechas, (value) {
                            setState(() {
                              selectedDate = value!;
                              _filterEvents();
                            });
                            Navigator.pop(context);
                          }),
                          const SizedBox(height: 15),
                          _buildDropdown("Tipo", tipos, (value) {
                            setState(() {
                              selectedType = value!;
                              _filterEvents();
                            });
                            Navigator.pop(context);
                          }),
                        ],
                      ),
                    );
                  },
                );
              },
              icon: const Icon(Icons.filter_list),
              label: const Text("Filtros"),
            ),
          ),
          const SizedBox(height: 10),
          Flexible(child: _buildScreenContent()),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.deepPurpleAccent,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favoritos'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Usuario'),
        ],
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
      items: items.map((item) => DropdownMenuItem<String>(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
    );
  }
  // Contenido de la pantalla, basado en la opción seleccionada
  Widget _buildScreenContent() {
    return _selectedIndex == 1
        ? _buildFavoriteScreen()
        : _selectedIndex == 2
            ? _buildUserScreen()
            : _buildHomeScreen();
  }

  // Pantalla principal de eventos
  Widget _buildHomeScreen() {
  return GridView.builder(
    padding: const EdgeInsets.all(10),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 0.7,
    ),
    itemCount: filteredEvents.length,
    itemBuilder: (context, index) => _buildEventCard(filteredEvents[index]),
  );
}


  // Pantalla de eventos favoritos
  Widget _buildFavoriteScreen() {
    return favoriteEvents.isEmpty
        ? const Center(child: Text("No hay eventos favoritos"))
        : GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.7,
            ),
            itemCount: favoriteEvents.length,
            itemBuilder: (context, index) =>
                _buildEventCard(favoriteEvents[index]),
          );
  }

  // Pantalla de usuario con datos
  Widget _buildUserScreen() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Text("Correo: $email", style: TextStyle(fontSize: 18)),
          const SizedBox(height: 10),
          Text("Cédula: $cedula", style: TextStyle(fontSize: 18)),
          const SizedBox(height: 10),
          TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: "Nombre",
              filled: true,
              fillColor: Colors.deepPurple[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _updateUserName,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 0, 0, 0), // Botón con color neón
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Actualizar Información"),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _resetPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 0, 0, 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Restablecer Contraseña"),
          ),
        ],
      ),
    );
  }

  // Tarjeta para mostrar cada evento
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
