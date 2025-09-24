import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MisReservasScreen extends StatelessWidget {
  const MisReservasScreen({super.key});

  Future<List<Map<String, dynamic>>> _getUserEventos(String userId) async {
    final firestore = FirebaseFirestore.instance;

    // Consultar RESERVAS
    final reservasSnapshot =
        await firestore
            .collection('reservas')
            .where('userId', isEqualTo: userId)
            .get();

    // Consultar PAGOS
    final pagosSnapshot =
        await firestore
            .collection('pagos')
            .where('userId', isEqualTo: userId)
            .get();

    // Unir resultados
    final eventos = [
      ...reservasSnapshot.docs.map(
        (doc) => {
          'id': doc.id,
          'eventoId': doc['eventoId'],
          'estado': doc['estado'],
          'price': doc['price'],
          'paymentMethod': doc['paymentMethod'],
          'timestamp': doc['timestamp'],
          'tipo': 'reserva',
        },
      ),
      ...pagosSnapshot.docs.map(
        (doc) => {
          'id': doc.id,
          'eventoId': doc['eventoId'],
          'estado': doc['estado'],
          'price': doc['price'],
          'paymentMethod': doc['paymentMethod'],
          'timestamp': doc['timestamp'],
          'tipo': 'pago',
        },
      ),
    ];

    // Ordenar por fecha (más reciente primero)
    eventos.sort((a, b) {
      final ta = a['timestamp'] as Timestamp?;
      final tb = b['timestamp'] as Timestamp?;
      return (tb?.compareTo(ta ?? Timestamp.now())) ?? 0;
    });

    return eventos;
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
      appBar: AppBar(title: const Text("Mis Reservas")),
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
              child: Text("No tienes reservas ni compras aún."),
            );
          }

          return ListView.builder(
            itemCount: eventos.length,
            itemBuilder: (context, index) {
              final e = eventos[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: Icon(
                    e['tipo'] == 'pago'
                        ? Icons.payment_rounded
                        : Icons.event_available_rounded,
                    color: e['tipo'] == 'pago' ? Colors.green : Colors.blue,
                  ),
                  title: Text("Evento ID: ${e['eventoId']}"),
                  subtitle: Text(
                    e['tipo'] == 'pago'
                        ? "Pagado con ${e['paymentMethod']} - \$${e['price']}"
                        : "Reserva confirmada (gratis)",
                  ),
                  trailing: Text(
                    e['estado'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
