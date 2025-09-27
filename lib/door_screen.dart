import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class DoorScreen extends StatefulWidget {
  const DoorScreen({super.key});

  @override
  State<DoorScreen> createState() => _DoorScreenState();
}

class _DoorScreenState extends State<DoorScreen> {
  List<Map<String, dynamic>> userEvents = [];
  Map<String, dynamic>? selectedEvent;

  String selectedTripType = "ida";
  final TextEditingController addressController = TextEditingController();

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserEvents();
  }

  Future<void> _loadUserEvents() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final snapshot =
          await FirebaseFirestore.instance
              .collection("reservas")
              .where("userId", isEqualTo: uid)
              .where("estado", isEqualTo: "pago confirmado")
              .get();

      List<Map<String, dynamic>> events = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final eventId = data["eventoId"];

        final eventRef =
            await FirebaseFirestore.instance
                .collection("eventos")
                .doc(eventId)
                .get();

        if (eventRef.exists) {
          final eventData = eventRef.data()!;
          events.add({
            "id": eventRef.id,
            "nombre": eventData["eventName"] ?? "Evento sin nombre",
            "direccion": eventData["direccion"] ?? "Dirección no disponible",
            "fecha": eventData["fecha"] ?? "",
          });
        }
      }

      setState(() {
        userEvents = events;
        isLoading = false;
      });
    } catch (e) {
      print("❌ Error al cargar eventos del usuario: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _sendToWhatsApp() async {
    if (selectedEvent == null || addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Completa todos los campos")),
      );
      return;
    }

    final eventName = selectedEvent!["nombre"];
    final eventDate = selectedEvent!["fecha"];
    final address = addressController.text;
    final tripType = selectedTripType;

    final message =
        "🚖 *Reserva Puerta a Puerta*\n\n"
        "🎉 Evento: $eventName\n"
        "📅 Fecha: $eventDate\n"
        "📍 Dirección: $address\n"
        "🔄 Tipo de viaje: $tripType\n";

    final phone = "573227131453";
    final url = Uri.parse(
      "https://wa.me/$phone?text=${Uri.encodeComponent(message)}",
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo abrir WhatsApp")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity, // 🔹 Ocupa todo el ancho
        height: double.infinity, // 🔹 Ocupa toda la altura
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1F1C2C), Color(0xFF928DAB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child:
              isLoading
                  ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                  : userEvents.isEmpty
                  ? const Center(
                    child: Text(
                      "No tienes eventos con pago confirmado.",
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  )
                  : LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: IntrinsicHeight(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: // ... mismo código arriba
                                  Column(
                                mainAxisAlignment:
                                    MainAxisAlignment
                                        .center, // 🔹 Centra vertical
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text(
                                    "🚖 Puerta a Puerta",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 30),

                                  // 🔹 Selección de evento
                                  DropdownButtonFormField<String>(
                                    value: selectedEvent?["id"],
                                    dropdownColor: const Color(0xFF2C2C2E),
                                    items:
                                        userEvents
                                            .map(
                                              (e) => DropdownMenuItem<String>(
                                                value: e["id"],
                                                child: Text(
                                                  e["nombre"],
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                    decoration: InputDecoration(
                                      labelText: "Selecciona un evento",
                                      labelStyle: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.1),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    onChanged: (id) {
                                      final event = userEvents.firstWhere(
                                        (e) => e["id"] == id,
                                      );
                                      setState(() => selectedEvent = event);
                                    },
                                  ),
                                  const SizedBox(height: 20),

                                  // 🔹 Dirección
                                  TextFormField(
                                    controller: addressController,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      labelText: "Dirección de recogida",
                                      labelStyle: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.1),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // 🔹 Tipo de viaje
                                  DropdownButtonFormField<String>(
                                    value: selectedTripType,
                                    dropdownColor: const Color.fromARGB(
                                      255,
                                      160,
                                      160,
                                      167,
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: "ida",
                                        child: Text("Casa ➝ Evento"),
                                      ),
                                      DropdownMenuItem(
                                        value: "vuelta",
                                        child: Text("Evento ➝ Casa"),
                                      ),
                                      DropdownMenuItem(
                                        value: "ambos",
                                        child: Text("Ida y Vuelta"),
                                      ),
                                    ],
                                    decoration: InputDecoration(
                                      labelText: "Tipo de viaje",
                                      labelStyle: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.1),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(
                                          () => selectedTripType = value,
                                        );
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 30),

                                  // 🔹 Botón moderno
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Colors.greenAccent.shade400,
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    onPressed: _sendToWhatsApp,
                                    icon: const Icon(Icons.send),
                                    label: const Text("Confirmar en WhatsApp"),
                                  ),

                                  // ❌ Quitamos el Spacer() que empujaba hacia arriba
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
        ),
      ),
    );
  }
}
