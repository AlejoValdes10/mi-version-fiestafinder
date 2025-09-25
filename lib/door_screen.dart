import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';

class DoorScreen extends StatefulWidget {
  const DoorScreen({super.key});

  @override
  State<DoorScreen> createState() => _DoorScreenState();
}

class _DoorScreenState extends State<DoorScreen> {
  String? selectedEventoId;
  String? selectedEventAddress;
  final TextEditingController addressController = TextEditingController();
  List<Map<String, dynamic>> eventosUsuario = [];
  GoogleMapController? mapController;

  LatLng? userLatLng;
  LatLng? eventLatLng;
  Set<Polyline> polylines = {};

  String travelOption = "ida"; // "ida", "vuelta", "idaVuelta"
  double estimatedDistanceKm = 0;
  int calculatedPrice = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserEvents();
  }

  Future<void> _fetchUserEvents() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    final reservasSnapshot =
        await FirebaseFirestore.instance
            .collection('reservas')
            .where('userId', isEqualTo: userId)
            .get();

    final List<Map<String, dynamic>> eventos = [];

    for (var reserva in reservasSnapshot.docs) {
      final eventoDoc =
          await FirebaseFirestore.instance
              .collection('eventos')
              .doc(reserva['eventoId'])
              .get();

      if (eventoDoc.exists) {
        final data = eventoDoc.data()!;
        eventos.add({
          "id": eventoDoc.id,
          "nombre": data['nombre'] ?? data['eventName'] ?? 'Evento',
          "direccion": data['direccion'] ?? 'Sin dirección',
          "lat": data['lat'] ?? 4.7110, // por defecto Bogotá
          "lng": data['lng'] ?? -74.0721,
        });
      }
    }

    setState(() {
      eventosUsuario = eventos;
    });
  }

  void _onEventoChanged(Map<String, dynamic> evento) {
    setState(() {
      selectedEventoId = evento['id'];
      selectedEventAddress = evento['direccion'];
      eventLatLng = LatLng(evento['lat'], evento['lng']);
      _calculateDistanceAndPrice();
    });
  }

  void _calculateDistanceAndPrice() {
    if (userLatLng != null && eventLatLng != null) {
      // Distancia simulada entre puntos (simple Euclideana)
      double dx = eventLatLng!.latitude - userLatLng!.latitude;
      double dy = eventLatLng!.longitude - userLatLng!.longitude;
      double distanceKm = sqrt(dx * dx + dy * dy) * 111;
      double factor = (travelOption == "idaVuelta") ? 2 : 1;
      estimatedDistanceKm = distanceKm;
      calculatedPrice = (distanceKm * 1500 * factor).round();
    } else {
      calculatedPrice = 0;
    }
  }

  void _confirmDoorService() async {
    if (selectedEventoId == null || addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecciona evento y dirección")),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('door_services').add({
      "userId": FirebaseAuth.instance.currentUser!.uid,
      "eventoId": selectedEventoId,
      "userAddress": addressController.text,
      "eventAddress": selectedEventAddress,
      "travelOption": travelOption,
      "distanceKm": estimatedDistanceKm,
      "price": calculatedPrice,
      "timestamp": FieldValue.serverTimestamp(),
      "status": "pendiente",
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Servicio confirmado: \$${calculatedPrice.toString()}"),
      ),
    );

    setState(() {
      selectedEventoId = null;
      selectedEventAddress = null;
      addressController.clear();
      userLatLng = null;
      eventLatLng = null;
      polylines.clear();
      estimatedDistanceKm = 0;
      calculatedPrice = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C2C2E),
        title: const Text("Puerta a Puerta"),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Dropdown de eventos
            DropdownButtonFormField<Map<String, dynamic>>(
              decoration: InputDecoration(
                labelText: "Selecciona tu evento",
                labelStyle: const TextStyle(color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: const Color(0xFF2C2C2E),
              ),
              dropdownColor: const Color(0xFF2C2C2E),
              value:
                  selectedEventoId == null
                      ? null
                      : eventosUsuario.firstWhere(
                        (e) => e['id'] == selectedEventoId,
                        orElse: () => {},
                      ),
              items:
                  eventosUsuario.map((evento) {
                    return DropdownMenuItem<Map<String, dynamic>>(
                      value: evento,
                      child: Text(
                        evento['nombre'],
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
              onChanged: (value) {
                if (value != null) _onEventoChanged(value);
              },
            ),

            const SizedBox(height: 16),

            // Dirección del usuario
            TextFormField(
              controller: addressController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Dirección de recogida",
                labelStyle: const TextStyle(color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: const Color(0xFF2C2C2E),
                prefixIcon: const Icon(Icons.home, color: Colors.white70),
              ),
              onChanged: (val) {
                // Aquí podrías convertir dirección a LatLng con Geocoding
                userLatLng = const LatLng(4.7109, -74.0721); // ejemplo Bogotá
                _calculateDistanceAndPrice();
              },
            ),

            const SizedBox(height: 16),

            // Opciones de viaje
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ChoiceChip(
                  label: const Text("Casa → Evento"),
                  selected: travelOption == "ida",
                  onSelected: (v) {
                    setState(() {
                      travelOption = "ida";
                      _calculateDistanceAndPrice();
                    });
                  },
                ),
                ChoiceChip(
                  label: const Text("Evento → Casa"),
                  selected: travelOption == "vuelta",
                  onSelected: (v) {
                    setState(() {
                      travelOption = "vuelta";
                      _calculateDistanceAndPrice();
                    });
                  },
                ),
                ChoiceChip(
                  label: const Text("Ida y Vuelta"),
                  selected: travelOption == "idaVuelta",
                  onSelected: (v) {
                    setState(() {
                      travelOption = "idaVuelta";
                      _calculateDistanceAndPrice();
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Precio estimado
            if (calculatedPrice > 0)
              Text(
                "Precio estimado: \$${calculatedPrice}",
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),

            const SizedBox(height: 16),

            // Mapa
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child:
                    eventLatLng != null && userLatLng != null
                        ? GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: eventLatLng!,
                            zoom: 14,
                          ),
                          markers: {
                            Marker(
                              markerId: const MarkerId("user"),
                              position: userLatLng!,
                              infoWindow: const InfoWindow(
                                title: "Tu ubicación",
                              ),
                            ),
                            Marker(
                              markerId: const MarkerId("evento"),
                              position: eventLatLng!,
                              infoWindow: InfoWindow(
                                title: selectedEventAddress,
                              ),
                            ),
                          },
                          polylines: polylines,
                          onMapCreated: (controller) {
                            mapController = controller;
                          },
                        )
                        : const Center(
                          child: Text(
                            "Selecciona un evento y dirección",
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
              ),
            ),

            const SizedBox(height: 16),

            // Botón confirmar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _confirmDoorService,
                child: const Text(
                  "Confirmar servicio",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
