import 'dart:ui';
import 'package:fiesta_finder/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class MisReservasScreen extends StatefulWidget {
  const MisReservasScreen({super.key});

  @override
  State<MisReservasScreen> createState() => _MisReservasScreenState();
}

class _MisReservasScreenState extends State<MisReservasScreen> {
  final ScrollController _scrollController = ScrollController();
  String? highlightedEventId;

  Future<List<Map<String, dynamic>>> _getUserEventos(String userId) async {
    final firestore = FirebaseFirestore.instance;

    final reservasSnapshot =
        await firestore
            .collection('reservas')
            .where('userId', isEqualTo: userId)
            .get();

    final pagosSnapshot =
        await firestore
            .collection('pagos')
            .where('userId', isEqualTo: userId)
            .get();

    final List<Map<String, dynamic>> eventos = [];

    for (var doc in [...reservasSnapshot.docs, ...pagosSnapshot.docs]) {
      final data = doc.data();
      final eventSnapshot =
          await firestore.collection('eventos').doc(data['eventoId']).get();

      final eventData = eventSnapshot.data() ?? {};
      eventos.add({
        'id': doc.id,
        'eventoId': data['eventoId'],
        'estado': data['estado'],
        'price': data['price'],
        'paymentMethod': data['paymentMethod'],
        'timestamp': data['timestamp'],
        'tipo': reservasSnapshot.docs.contains(doc) ? 'reserva' : 'pago',
        // 🔹 info extra del evento
        'name': eventData['eventName'] ?? 'Evento sin nombre',
        'image': eventData['image'] ?? '',
        'fecha': eventData['fecha'] ?? 'Sin fecha',
        'tipoEvento': eventData['tipo'] ?? 'General',
        'descripcion': eventData['descripcion'] ?? '',
        'direccion': eventData['direccion'] ?? 'Dirección no disponible',
        'costo': eventData['costo'] ?? 0,
        'esGratis': eventData['esGratis'] ?? false,
        'capacidad': eventData['capacidad'] ?? 0,
        'hora': eventData['hora'] ?? '',
        'contacto': eventData['contacto'] ?? '',
        'accesibilidad': eventData['accesibilidad'] ?? false,
        'parqueadero': eventData['parqueadero'] ?? false,
      });
    }

    eventos.sort((a, b) {
      final ta = a['timestamp'] as Timestamp?;
      final tb = b['timestamp'] as Timestamp?;
      return (tb?.compareTo(ta ?? Timestamp.now())) ?? 0;
    });

    return eventos;
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return "";
    final date = timestamp.toDate();
    return DateFormat("dd MMM yyyy • HH:mm").format(date);
  }

  void _highlightEvent(String eventId, int index) async {
    setState(() {
      highlightedEventId = eventId;
    });

    await _scrollController.animateTo(
      index * 180,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );

    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        highlightedEventId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Debes iniciar sesión para ver tus reservas")),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Mis Reservas"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getUserEventos(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("❌ Error: ${snapshot.error}"));
          }

          final eventos = snapshot.data ?? [];

          if (eventos.isEmpty) {
            return const Center(
              child: Text(
                "No tienes reservas ni compras aún.",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            );
          }

          final totalReservas =
              eventos.where((e) => e['esGratis'] == true).length;
          final totalPagos =
              eventos.where((e) => e['esGratis'] == false).length;
          final totalGastado = eventos
              .where((e) => e['esGratis'] == false)
              .fold<double>(
                0,
                (sum, e) => sum + (e['price'] as num).toDouble(),
              );

          return Column(
            children: [
              // 🔥 HEADER con stats
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.deepPurple, Colors.purpleAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurple.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCard(
                          "Gratis",
                          totalReservas.toString(),
                          Icons.event,
                        ),
                        _buildStatCard(
                          "De pago",
                          totalPagos.toString(),
                          Icons.credit_card,
                        ),
                        _buildStatCard(
                          "Gastado",
                          "\$${totalGastado.toStringAsFixed(0)}",
                          Icons.monetization_on,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 🔥 LISTA DE EVENTOS
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: eventos.length,
                  itemBuilder: (context, index) {
                    final e = eventos[index];
                    final isPago = e['esGratis'] == false;
                    final estado = e['estado'];
                    final isHighlighted = highlightedEventId == e['eventoId'];

                    IconData estadoIcon;
                    Color estadoColor;

                    if (estado == "aprobado") {
                      estadoIcon = Icons.check_circle;
                      estadoColor = Colors.greenAccent;
                    } else if (estado == "rechazado") {
                      estadoIcon = Icons.cancel;
                      estadoColor = Colors.redAccent;
                    } else {
                      estadoIcon = Icons.hourglass_top;
                      estadoColor = Colors.orangeAccent;
                    }

                    return GestureDetector(
                      onTap: () async {
                        final confirm = await showDialog<String>(
                          context: context,
                          builder:
                              (_) => AlertDialog(
                                title: const Text("Ir al evento"),
                                content: Text(
                                  "¿Quieres ir al evento \"${e['name']}\"?",
                                ),
                                actions: [
                                  TextButton(
                                    child: const Text("Cancelar"),
                                    onPressed:
                                        () => Navigator.pop(context, "cancel"),
                                  ),
                                  TextButton(
                                    child: const Text("Copiar nombre"),
                                    onPressed: () {
                                      Clipboard.setData(
                                        ClipboardData(text: e['name']),
                                      );
                                      Navigator.pop(context, "copied");
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "Nombre copiado al portapapeles",
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  ElevatedButton(
                                    child: const Text("Sí, ir"),
                                    onPressed:
                                        () => Navigator.pop(context, "yes"),
                                  ),
                                ],
                              ),
                        );

                        if (confirm == "yes") {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => HomeScreen(
                                    FirebaseAuth.instance.currentUser!,
                                  ),
                            ),
                          );
                        }
                      },

                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        margin: const EdgeInsets.only(bottom: 16),
                        transform:
                            isHighlighted
                                ? (Matrix4.identity()..scale(1.05))
                                : Matrix4.identity(),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors:
                                isPago
                                    ? [
                                      Colors.green.shade400,
                                      Colors.green.shade700,
                                    ]
                                    : [
                                      Colors.blue.shade400,
                                      Colors.blue.shade700,
                                    ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  isHighlighted
                                      ? Colors.yellowAccent.withOpacity(0.8)
                                      : Colors.black.withOpacity(0.1),
                              blurRadius: isHighlighted ? 20 : 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          leading: CircleAvatar(
                            radius: 28,
                            backgroundImage:
                                e['image'] != ''
                                    ? NetworkImage(e['image'])
                                    : null,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            child:
                                e['image'] == ''
                                    ? Icon(
                                      isPago
                                          ? Icons.credit_card_rounded
                                          : Icons.event_available_rounded,
                                      size: 30,
                                      color: Colors.white,
                                    )
                                    : null,
                          ),
                          title: Text(
                            e['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                isPago
                                    ? "💳 ${e['paymentMethod']} • \$${e['price']}"
                                    : "Reserva confirmada (gratis)",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatDate(e['timestamp']),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                          trailing: Icon(
                            estadoIcon,
                            color: estadoColor,
                            size: 28,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Column(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: Colors.white.withOpacity(0.2),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        Text(
          title,
          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
        ),
      ],
    );
  }
}
