import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  List<Map<String, String>> events = [
    {
      "name": "Concierto de Rock al Parque",
      "image": "assets/rock_al_parque.jpg",
      "localidad": "Centro",
      "fecha": "2025-03-12",
      "tipo": "Amigos",
    },
    {
      "name": "Feria Internacional del Libro de Bogotá",
      "image": "assets/filbo.jpg",
      "localidad": "Centro",
      "fecha": "2025-04-25",
      "tipo": "Familia",
    },
    {
      "name": "Festival de Teatro y Circo de Bogotá",
      "image": "assets/teatro_circo.jpg",
      "localidad": "Centro",
      "fecha": "2025-08-10",
      "tipo": "Familia",
    },
    {
      "name": "Festival de Salsa al Parque",
      "image": "assets/salsa_al_parque.jpg",
      "localidad": "Antonio Nariño",
      "fecha": "2025-03-15",
      "tipo": "Parejas",
    },
    {
      "name": "Cine al Aire Libre en el Parque Simón Bolívar",
      "image": "assets/cine_parque.jpg",
      "localidad": "Barrios Unidos",
      "fecha": "2025-03-20",
      "tipo": "Familia",
    },
    {
      "name": "Exposición de Arte Contemporáneo",
      "image": "assets/arte_contemporaneo.jpg",
      "localidad": "La Candelaria",
      "fecha": "2025-04-05",
      "tipo": "Amigos",
    },
    {
      "name": "Festival de Música Andina",
      "image": "assets/musica_andina.jpg",
      "localidad": "Usaquén",
      "fecha": "2025-05-01",
      "tipo": "Familia",
    },
    {
      "name": "Obra de Teatro Infantil: 'El Último Árbol'",
      "image": "assets/ultimo_arbol.jpg",
      "localidad": "Teusaquillo",
      "fecha": "2025-03-08",
      "tipo": "Familia",
    },
    {
      "name": "Noche de Salsa en Vivo",
      "image": "assets/noche_salsa.jpg",
      "localidad": "Chapinero",
      "fecha": "2025-03-22",
      "tipo": "Parejas",
    },
    {
      "name": "Festival de Jazz al Parque",
      "image": "assets/jazz_al_parque.jpg",
      "localidad": "Suba",
      "fecha": "2025-06-15",
      "tipo": "Amigos",
    },
    {
      "name": "Feria de Servicios y Emprendimientos",
      "image": "assets/feria_servicios.jpg",
      "localidad": "San Cristóbal",
      "fecha": "2025-03-25",
      "tipo": "Familia",
    },
    {
      "name": "Caminata Ecológica Nocturna",
      "image": "assets/caminata_ecologica.jpg",
      "localidad": "Sumapaz",
      "fecha": "2025-04-10",
      "tipo": "Amigos",
    },
    {
      "name": "Talleres de Artesanía para Niños",
      "image": "assets/talleres_ninos.jpg",
      "localidad": "Ciudad Bolívar",
      "fecha": "2025-05-05",
      "tipo": "Familia",
    },
    {
      "name": "Festival de Cine Independiente",
      "image": "assets/cine_independiente.jpg",
      "localidad": "Fontibón",
      "fecha": "2025-07-20",
      "tipo": "Amigos",
    },
    {
      "name": "Concierto de Música Electrónica",
      "image": "assets/musica_electronica.jpg",
      "localidad": "Kennedy",
      "fecha": "2025-08-05",
      "tipo": "Parejas",
    },
    {
      "name": "Exposición de Fotografía Urbana",
      "image": "assets/fotografia_urbana.jpg",
      "localidad": "Engativá",
      "fecha": "2025-09-10",
      "tipo": "Amigos",
    },
    {
      "name": "Festival de Danzas Folclóricas",
      "image": "assets/danzas_folcloricas.jpg",
      "localidad": "Rafael Uribe Uribe",
      "fecha": "2025-10-15",
      "tipo": "Familia",
    },
    {
      "name": "Concierto de Música Clásica al Parque",
      "image": "assets/musica_clasica.jpg",
      "localidad": "Teusaquillo",
      "fecha": "2025-11-05",
      "tipo": "Parejas",
    },
    {
      "name": "Feria de la Ciencia y la Tecnología",
      "image": "assets/ciencia_tecnologia.jpg",
      "localidad": "Bosa",
      "fecha": "2025-12-01",
      "tipo": "Familia",
    },
    {
      "name": "Cine al Parque",
      "image": "assets/cine_parque.jpg",
      "localidad": "Centro",
      "fecha": "2025-06-10",
      "tipo": "Familia",
    },
    {
      "name": "Festival de Rock en el Parque",
      "image": "assets/rock_parque.jpg",
      "localidad": "Usaquén",
      "fecha": "2025-08-05",
      "tipo": "Amigos",
    },
    {
      "name": "Noche de Tango",
      "image": "assets/tango.jpg",
      "localidad": "Chapinero",
      "fecha": "2025-06-25",
      "tipo": "Parejas",
    },
    {
      "name": "Festival de Jazz en el Parque Simón Bolívar",
      "image": "assets/jazz_parque.jpg",
      "localidad": "Teusaquillo",
      "fecha": "2025-09-12",
      "tipo": "Amigos",
    },
    {
      "name": "Noche de Salsa",
      "image": "assets/salsa_noche.jpg",
      "localidad": "Suba",
      "fecha": "2025-05-15",
      "tipo": "Amigos",
    },
    {
      "name": "Festival Internacional de Música de Bogotá",
      "image": "assets/musica_internacional.jpg",
      "localidad": "Centro",
      "fecha": "2025-07-01",
      "tipo": "Amigos",
    },
    {
      "name": "Cine de Verano",
      "image": "assets/cine_verano.jpg",
      "localidad": "Fontibón",
      "fecha": "2025-07-22",
      "tipo": "Familia",
    },
    {
      "name": "Feria de las Flores",
      "image": "assets/feria_flores.jpg",
      "localidad": "Usaquén",
      "fecha": "2025-08-10",
      "tipo": "Familia",
    },
    {
      "name": "Festival de Comedia",
      "image": "assets/festival_comedia.jpg",
      "localidad": "Barrios Unidos",
      "fecha": "2025-09-17",
      "tipo": "Amigos",
    },
    {
      "name": "Concierto en Vivo: Banda Local",
      "image": "assets/banda_local.jpg",
      "localidad": "Kennedy",
      "fecha": "2025-10-02",
      "tipo": "Amigos",
    },
    {
      "name": "Fiesta de Verano",
      "image": "assets/fiesta_verano.jpg",
      "localidad": "Engativá",
      "fecha": "2025-06-15",
      "tipo": "Amigos",
    },
    {
      "name": "Festival de Cine Independiente",
      "image": "assets/cine_independiente.jpg",
      "localidad": "Bosa",
      "fecha": "2025-07-14",
      "tipo": "Amigos",
    },
    {
      "name": "Día del Niño: Actividades Culturales",
      "image": "assets/dia_del_nino.jpg",
      "localidad": "Rafael Uribe Uribe",
      "fecha": "2025-04-30",
      "tipo": "Familia",
    },
    {
      "name": "Exposición de Arte Urbano",
      "image": "assets/arte_urbano.jpg",
      "localidad": "La Candelaria",
      "fecha": "2025-10-03",
      "tipo": "Amigos",
    },
    {
      "name": "Concierto de Música Electrónica",
      "image": "assets/musica_electronica.jpg",
      "localidad": "Sumapaz",
      "fecha": "2025-11-12",
      "tipo": "Parejas",
    },
    {
      "name": "Festival de Hip Hop",
      "image": "assets/hip_hop.jpg",
      "localidad": "San Cristóbal",
      "fecha": "2025-07-28",
      "tipo": "Amigos",
    },
    {
      "name": "Noche de Cumbia y Vallenato",
      "image": "assets/cumbia_vallenato.jpg",
      "localidad": "Tunjuelito",
      "fecha": "2025-06-05",
      "tipo": "Parejas",
    },
    {
      "name": "Festival de Teatro",
      "image": "assets/festival_teatro.jpg",
      "localidad": "Antonio Nariño",
      "fecha": "2025-08-17",
      "tipo": "Familia",
    },
    {
      "name": "Concierto de Música Clásica",
      "image": "assets/musica_clasica.jpg",
      "localidad": "Chapinerito",
      "fecha": "2025-09-09",
      "tipo": "Parejas",
    },
    {
      "name": "Fiesta de Año Nuevo",
      "image": "assets/fiesta_ano_nuevo.jpg",
      "localidad": "Calle 80",
      "fecha": "2025-12-31",
      "tipo": "Amigos",
    },
    {
      "name": "Encuentro Gastronómico: Sabores de Bogotá",
      "image": "assets/encuentro_gastronomico.jpg",
      "localidad": "Engativá",
      "fecha": "2025-06-18",
      "tipo": "Familia",
    },
    {
      "name": "Exposición de Escultura Contemporánea",
      "image": "assets/escultura_contemporanea.jpg",
      "localidad": "Teusaquillo",
      "fecha": "2025-08-21",
      "tipo": "Amigos",
    },
    {
      "name": "Concierto de Música Reggae",
      "image": "assets/musica_reggae.jpg",
      "localidad": "Rafael Uribe Uribe",
      "fecha": "2025-07-19",
      "tipo": "Parejas",
    },
    {
      "name": "Festival de Arte Urbano",
      "image": "assets/arte_urbano.jpg",
      "localidad": "La Candelaria",
      "fecha": "2025-06-30",
      "tipo": "Amigos",
    },
    {
      "name": "Feria de Emprendimientos de Bogotá",
      "image": "assets/feria_emprendimientos.jpg",
      "localidad": "Chapinero",
      "fecha": "2025-09-22",
      "tipo": "Familia",
    },
    {
      "name": "Concierto de Música en Vivo",
      "image": "assets/musica_viva.jpg",
      "localidad": "Suba",
      "fecha": "2025-08-20",
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
    "Chapinero",
    "Usaquén",
    "Centro",
    "Suba",
    "Kennedy",
    "Teusaquillo",
    "Fontibón",
    "Antonio Nariño",
    "Barrios Unidos",
    "Bosa",
    "Ciudad Bolívar",
    "Engativá",
    "La Candelaria",
    "Los Mártires",
    "Puente Aranda",
    "Rafael Uribe Uribe",
    "San Cristóbal",
    "Santa Fe",
    "Sumapaz",
    "Tunjuelito",
    "Usme",
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
    filteredEvents = events;
    searchController.addListener(_filterEvents);
  }

  void _filterEvents() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredEvents =
          events.where((event) {
            return event["name"]!.toLowerCase().contains(query) &&
                (selectedFilter == "Todos" ||
                    event["localidad"] == selectedFilter) &&
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Fiesta Finder")),
      body: Column(
        children: [
          // Reemplazamos el CircleAvatar con la animación Lottie
          Lottie.asset(
            'assets/user.json', // Ruta de tu archivo JSON con la animación
            width: 100, // Ajusta el tamaño de la animación
            height: 100, // Ajusta el tamaño de la animación
            fit:
                BoxFit
                    .fill, // Cómo se ajusta la animación dentro del contenedor
          ),
          const SizedBox(height: 10),
          const Text("Usuario"),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Buscar evento...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          // Filtros adicionales (Fecha, Localidad, Tipo de Evento)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 10.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDropdown("Localidad", localidades, (String? value) {
                  setState(() {
                    selectedFilter = value!;
                  });
                  _filterEvents();
                }),
                _buildDropdown("Fecha", fechas, (String? value) {
                  setState(() {
                    selectedDate = value!;
                  });
                  _filterEvents();
                }),
                _buildDropdown("Tipo", tipos, (String? value) {
                  setState(() {
                    selectedType = value!;
                  });
                  _filterEvents();
                }),
              ],
            ),
          ),
          Expanded(child: _buildScreenContent()),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.purple,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favoritos',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Buscar'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }

  // Método para construir los filtros tipo Dropdown
  Widget _buildDropdown(
    String label,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Expanded(
      child: DropdownButtonFormField<String>(
        value: items.first,
        decoration: InputDecoration(labelText: label),
        items:
            items.map((item) {
              return DropdownMenuItem<String>(value: item, child: Text(item));
            }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildScreenContent() {
    if (_selectedIndex == 1) {
      return _buildFavoriteScreen();
    } else {
      return _buildHomeScreen();
    }
  }

  Widget _buildHomeScreen() {
    return GridView.builder(
      padding: EdgeInsets.all(10),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: filteredEvents.length,
      itemBuilder: (context, index) {
        var event = filteredEvents[index];
        return _buildEventCard(event);
      },
    );
  }

  Widget _buildFavoriteScreen() {
    return favoriteEvents.isEmpty
        ? Center(child: Text("No hay eventos favoritos"))
        : GridView.builder(
          padding: EdgeInsets.all(10),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: favoriteEvents.length,
          itemBuilder: (context, index) {
            var event = favoriteEvents[index];
            return _buildEventCard(event);
          },
        );
  }

  Widget _buildEventCard(Map<String, String> event) {
    bool isFavorite = favoriteEvents.contains(event);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailScreen(event: event),
          ),
        );
      },
      child: Card(
        child: Column(
          children: [
            Expanded(child: Image.asset(event["image"]!, fit: BoxFit.cover)),
            Text(event["name"]!, style: TextStyle(fontWeight: FontWeight.bold)),
            Text("${event["localidad"]} - ${event["fecha"]}"),
            IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : Colors.grey,
              ),
              onPressed: () => _toggleFavorite(event),
            ),
          ],
        ),
      ),
    );
  }
}

class EventDetailScreen extends StatelessWidget {
  final Map<String, String> event;
  const EventDetailScreen({super.key, required this.event});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(event["name"]!)),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(event["image"]!, fit: BoxFit.cover),
            const SizedBox(height: 10),
            Text(
              event["name"]!,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text("Fecha: ${event["fecha"]}"),
            Text("Localidad: ${event["localidad"]}"),
            Text("Tipo: ${event["tipo"]}"),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Acción de agregar a favoritos
              },
              child: const Text("Añadir a Favoritos"),
            ),
          ],
        ),
      ),
    );
  }
}

