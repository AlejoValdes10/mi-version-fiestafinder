import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MisEventosEmpresarioScreen extends StatelessWidget {
  const MisEventosEmpresarioScreen({super.key});

  Future<String> _getCurrentUserId() async {
    final user = FirebaseAuth.instance.currentUser;
    return user?.uid ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis Eventos"),
        backgroundColor: Colors.deepPurpleAccent,
        elevation: 0,
      ),
      body: FutureBuilder<String>(
        future: _getCurrentUserId(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final empresarioId = snapshot.data!;

          return StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('eventos')
                    .where('creatorId', isEqualTo: empresarioId)
                    .snapshots(),
            builder: (context, eventSnapshot) {
              if (eventSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!eventSnapshot.hasData || eventSnapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    "No tienes eventos creados.",
                    style: TextStyle(fontSize: 18),
                  ),
                );
              }

              final eventos = eventSnapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: eventos.length,
                itemBuilder: (context, index) {
                  final evento = eventos[index];
                  final eventoData =
                      evento.data() as Map<String, dynamic>? ?? {};
                  final eventoId = evento.id;
                  final nombreEvento =
                      eventoData['eventName'] ??
                      eventoData['nombre'] ??
                      'Sin nombre';
                  final costo = eventoData['costo'] ?? 'Gratis';
                  final fecha = eventoData['fecha'] ?? 'Fecha no definida';

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 5,
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      backgroundColor: Colors.deepPurpleAccent.withOpacity(
                        0.05,
                      ),
                      collapsedBackgroundColor: Colors.white,
                      title: Text(
                        nombreEvento,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text("Costo: $costo • Fecha: $fecha"),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Reservas
                              StreamBuilder<QuerySnapshot>(
                                stream:
                                    FirebaseFirestore.instance
                                        .collection('reservas')
                                        .where('eventoId', isEqualTo: eventoId)
                                        .snapshots(),
                                builder: (context, reservasSnapshot) {
                                  if (reservasSnapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }

                                  final reservas =
                                      reservasSnapshot.data?.docs ?? [];

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Reservas (${reservas.length})",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ...reservas.map((r) {
                                        final rData =
                                            r.data() as Map<String, dynamic>? ??
                                            {};
                                        final userId =
                                            rData['userId'] ?? 'Desconocido';
                                        final estado =
                                            rData['estado'] ?? 'Pendiente';
                                        final price = rData['price'] ?? 0;

                                        return Card(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          color: Colors.deepPurpleAccent
                                              .withOpacity(0.05),
                                          margin: const EdgeInsets.symmetric(
                                            vertical: 4,
                                          ),
                                          child: ListTile(
                                            leading: CircleAvatar(
                                              backgroundColor:
                                                  Colors.deepPurpleAccent,
                                              child: Text(
                                                userId
                                                    .substring(0, 1)
                                                    .toUpperCase(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                            title: Text(userId),
                                            subtitle: Text(
                                              "Estado: $estado • Precio: $price",
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              // Pagos
                              StreamBuilder<QuerySnapshot>(
                                stream:
                                    FirebaseFirestore.instance
                                        .collection('pagos')
                                        .where('eventoId', isEqualTo: eventoId)
                                        .snapshots(),
                                builder: (context, pagosSnapshot) {
                                  if (pagosSnapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }

                                  final pagos = pagosSnapshot.data?.docs ?? [];

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Pagos (${pagos.length})",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ...pagos.map((p) {
                                        final pData =
                                            p.data() as Map<String, dynamic>? ??
                                            {};
                                        final userId =
                                            pData['userId'] ?? 'Desconocido';
                                        final estado =
                                            pData['estado'] ?? 'Pendiente';
                                        final price = pData['price'] ?? 0;
                                        final metodo =
                                            pData['paymentMethod'] ?? '-';

                                        return Card(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          color: Colors.blueAccent.withOpacity(
                                            0.05,
                                          ),
                                          margin: const EdgeInsets.symmetric(
                                            vertical: 4,
                                          ),
                                          child: ListTile(
                                            leading: const Icon(
                                              Icons.payment,
                                              color: Colors.blueAccent,
                                            ),
                                            title: Text(userId),
                                            subtitle: Text(
                                              "Estado: $estado • Método: $metodo • Precio: $price",
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
