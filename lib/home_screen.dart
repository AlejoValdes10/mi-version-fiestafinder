import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'agregar_evento_screen.dart';

// Pantalla principal que muestra eventos y el perfil del usuario
class HomeScreen extends StatefulWidget {
  
  final User user;  // Usuario que ha iniciado sesión
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
  int _selectedIndex = 0;  // Indica qué pestaña está seleccionada
  

  // Lista de eventos inicial
  List<Map<String, String>> events = [
    {
      "name": "Concierto de Rock al Parque",
      "image": "assets/unnamed.png",
      "localidad": "Centro",
      "fecha": "2025-03-12",
      "tipo": "Amigos",
    },
  ];

  // Filtrados y eventos favoritos
  List<Map<String, String>> filteredEvents = [];
  List<Map<String, String>> favoriteEvents = [];
  TextEditingController searchController = TextEditingController();
  String selectedFilter = "Todos";
  String selectedDate = "Todas";
  String selectedType = "Todos";

  // Opciones de filtros
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
  // Función para mostrar un mensaje personalizado con animación
void _showCustomSnackBar(String animationPath) {
  OverlayEntry overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: MediaQuery.of(context).size.height / 3,  // Centrado en la pantalla
      left: MediaQuery.of(context).size.width / 2 - 75,  // Centrado horizontalmente (ajustado al tamaño de la animación)
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),  // Fondo negro con opacidad
            borderRadius: BorderRadius.circular(25),  // Bordes redondeados
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),  // Asegura que el borde redondeado también se aplique al contenedor
            child: Lottie.asset(
              animationPath,  // Cargar la animación
              width: 150,  // Tamaño de la animación
              height: 150,  // Tamaño de la animación
            ),
          ),
        ),
      ),
    ),
  );

  Overlay.of(context)?.insert(overlayEntry);

  // Eliminar la animación después de 3 segundos
  Future.delayed(Duration(seconds: 3), () {
    overlayEntry.remove();
  });
}



  @override
  void initState() {
    super.initState();
    
    // Cargar los datos del usuario desde Firestore
    _getUserData();
    
    // Cargar eventos desde Firestore si el usuario está logueado
    if (widget.user != null && widget.user.email != null) {
      _getEventsFromFirestore();
    }

    filteredEvents = events;  // Inicializar lista de eventos filtrados
    searchController.addListener(_filterEvents);  // Escuchar cambios en la búsqueda
  }

  
  
 
  // Obtener eventos desde Firestore
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
        events = loadedEvents;  // Actualizar los eventos
        filteredEvents = events;  // Filtrar eventos
      });
    } catch (e) {
      print("Error al cargar los eventos: $e");
    }
  }

  // Obtener datos del usuario desde Firestore
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

  // Filtrar eventos según la búsqueda y los filtros seleccionados
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

  // Añadir o eliminar eventos de la lista de favoritos
  void _toggleFavorite(Map<String, String> event) {
    setState(() {
      if (favoriteEvents.contains(event)) {
        favoriteEvents.remove(event);
      } else {
        favoriteEvents.add(event);
      }
    });
  }

  // Cambiar la pestaña seleccionada en el BottomNavigationBar
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }


  // Actualizar el nombre del usuario en Firestore
Future<void> _updateUserName() async {
  try {
    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.user.uid)
        .update({'nombre': nameController.text});
    setState(() {
      userName = nameController.text;
    });

    // Mostrar mensaje de éxito con animación
    _showCustomSnackBar("assets/listo.json");
  } catch (e) {
    print("Error al actualizar el nombre: $e");
    // Mostrar mensaje de error con animación
    _showCustomSnackBar("assets/listo.json");
  }
}




  

  // Enviar correo para restablecer la contraseña
Future<void> _resetPassword() async {
  try {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: widget.user.email!);
    
    // Mostrar mensaje de éxito
    _showSnackBar("Correo de recuperación enviado");
  } catch (e) {
    print("Error al enviar correo de recuperación: $e");
    // Mostrar mensaje de error
    _showSnackBar("Error al enviar correo de recuperación");
  }
}




  // Cerrar sesión
Future<void> _logout() async {
  try {
    // Cerrar sesión de Firebase
    await FirebaseAuth.instance.signOut();
    
    // Cerrar sesión de Google
    await GoogleSignIn().signOut();
    
    // Redirigir a la pantalla de inicio de sesión
    Navigator.pushReplacementNamed(context, '/welcome');
    
    // Mostrar mensaje de éxito
    _showSnackBar("Sesión cerrada con éxito");
  } catch (e) {
    print("Error al cerrar sesión: $e");
    // Mostrar mensaje de error
    _showSnackBar("Error al cerrar sesión");
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Fiesta Finder"),
        actions: [
          // Botón de cerrar sesión
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Cerrar sesión",
            onPressed: _logout,
          ),
          // Si es un "Empresario", mostrar el botón de agregar evento
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
          Lottie.asset('assets/user.json', width: 100, height: 100),  // Animación Lottie
          Text(userName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),  // Nombre del usuario
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
          Flexible(child: _buildScreenContent()),  // Mostrar el contenido según la pestaña seleccionada
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

  // Construir un DropdownButton para seleccionar filtros
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







  Widget _buildUserScreen() {
  return Padding(
    padding: const EdgeInsets.all(20.0),
    child: SingleChildScrollView(
      child: Center( // Centra todo el contenido
        child: Column(
          mainAxisSize: MainAxisSize.min, // Esto asegura que el contenido no ocupe espacio extra
          children: [
            // Correo del usuario
            _buildUserInfoRow("Correo: ", email),
            const SizedBox(height: 10),

            // Cédula del usuario
            _buildUserInfoRow("Cédula: ", cedula),
            const SizedBox(height: 20),

            // Campo de texto para editar el nombre
            _buildTextField(
              label: "Nombre",
              controller: nameController,
              icon: Icons.person,
            ),
            const SizedBox(height: 30),

            // Botón para actualizar información
            _buildActionButton(
              text: "Actualizar Información",
              onPressed: _updateUserName,
            ),
            const SizedBox(height: 15),

            // Botón para restablecer la contraseña
            _buildActionButton(
              text: "Restablecer Contraseña",
              onPressed: _resetPassword,
            ),
            const SizedBox(height: 30),

            // Botón para cerrar sesión (si lo deseas añadir aquí)
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

// Método para construir cada fila de información
Widget _buildUserInfoRow(String label, String value) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center, // Centra la fila
    children: [
      Icon(
        Icons.info_outline,
        color: Colors.black, // Color negro
        size: 20,
      ),
      const SizedBox(width: 10),
      Text(
        "$label$value",
        style: TextStyle(fontSize: 18, color: Colors.black), // Solo texto negro
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
    width: double.infinity, // Ancho completo
    child: TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.black),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.3), width: 1), // Borde sutil
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      ),
    ),
  );
}


// Método para construir un botón estilizado
Widget _buildActionButton({
  required String text,
  required VoidCallback onPressed,
}) {
  return Container(
    width: double.infinity * 0.9, // Un poco más pequeño que el ancho completo
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 30),
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


Widget _buildUserInfoCard(String label, String value) {
  return Container(
    width: double.infinity, // Ancho completo
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white, // Fondo blanco
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.black.withOpacity(0.3), width: 1), // Borde sutil negro
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1), // Sombra ligera para profundidad
          offset: Offset(0, 4),
          blurRadius: 6,
        ),
      ],
    ),
    child: Row(
      children: [
        Icon(
          Icons.info_outline,
          color: Colors.black,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            "$label$value",
            style: TextStyle(fontSize: 16, color: Colors.black),
            overflow: TextOverflow.ellipsis, // Evita que el texto se desborde
          ),
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
