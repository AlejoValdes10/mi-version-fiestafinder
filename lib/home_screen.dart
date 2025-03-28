import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';

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
  TextEditingController nameController = TextEditingController(); // Controlador para el nombre
  int _selectedIndex = 0;
  List<Map<String, String>> events = [
    {
      "name": "Concierto de Rock al Parque",
      "image": "assets/rock_al_parque.jpg",
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

  List<String> localidades = [
    "Todos",
  ];
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
    _getUserData();
    filteredEvents = events;
    searchController.addListener(_filterEvents);
  }

  // Obtener los datos del usuario desde Firestore
  Future<void> _getUserData() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.user.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        setState(() {
          userName = doc['nombre'] ?? "Usuario";
          email = widget.user.email ?? "No disponible";
          cedula = doc['numeroDocumento'] ?? "No disponible";
          nameController.text = userName;
        });
      } else {
        setState(() {
          userName = "Sin datos";
        });
        print("No se encontró el documento o está vacío.");
      }
    } catch (e) {
      print("Error al cargar los datos: $e");
    }
  }

  // Filtrar eventos basados en la búsqueda y los filtros seleccionados
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

  // Alternar entre favorito y no favorito
  void _toggleFavorite(Map<String, String> event) {
    setState(() {
      if (favoriteEvents.contains(event)) {
        favoriteEvents.remove(event);
      } else {
        favoriteEvents.add(event);
      }
    });
  }

  // Controlar la selección del índice en la barra de navegación
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Actualizar el nombre del usuario en la base de datos
  Future<void> _updateUserName() async {
    try {
      await FirebaseFirestore.instance.collection('usuarios').doc(widget.user.uid).update({
        'nombre': nameController.text,
      });
      setState(() {
        userName = nameController.text;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nombre actualizado correctamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar el nombre: $e')),
      );
    }
  }

  // Restablecer la contraseña del usuario
  Future<void> _resetPassword() async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: widget.user.email!);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Se ha enviado un correo para restablecer la contraseña"),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Hubo un error al intentar restablecer la contraseña: $e"),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Fiesta Finder")),
      body: Column(
        children: [
          Lottie.asset('assets/user.json', width: 100, height: 100),
          userName.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: const CircularProgressIndicator(),
                )
              : Text(
                  userName,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 0, 0, 0), // El color de fondo con neón
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                shadowColor: const Color.fromARGB(255, 0, 0, 0), // Efecto de sombra
                elevation: 8,
              ),
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
        selectedItemColor: Colors.deepPurpleAccent, // Neón
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favoritos'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Usuario'),
        ],
      ),
    );
  }

  // Dropdown para los filtros
  Widget _buildDropdown(
    String label,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: items.first,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.deepPurple[50],
      ),
      items: items
          .map((item) => DropdownMenuItem<String>(value: item, child: Text(item)))
          .toList(),
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
              backgroundColor: const Color.fromARGB(255, 0, 0, 0), // Botón con color neón
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

  // Tarjeta para mostrar el evento
  Widget _buildEventCard(Map<String, String> event) {
    bool isFavorite = favoriteEvents.contains(event);
    return Card(
      key: ValueKey(event["name"]),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.asset(
                event["image"]!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.broken_image, size: 50);
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
            child: Text(
              event["name"]!,
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              "${event["localidad"]} - ${event["fecha"]}",
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : Colors.grey,
            ),
            onPressed: () => _toggleFavorite(event),
          ),
        ],
      ),
    );
  }
}
