import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AsistentesEventoScreen extends StatelessWidget {
  final String eventoId;
  const AsistentesEventoScreen({super.key, required this.eventoId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Asistentes")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reservas')
            .where('eventoId', isEqualTo: eventoId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Aún no hay asistentes"));
          }

          final asistentes = snapshot.data!.docs;

          return ListView.builder(
            itemCount: asistentes.length,
            itemBuilder: (context, index) {
              final asistente = asistentes[index];
              return ListTile(
                leading: Icon(
                  asistente['estado'] == 'pago confirmado'
                      ? Icons.verified_rounded
                      : Icons.access_time,
                  color: asistente['estado'] == 'pago confirmado'
                      ? Colors.green
                      : Colors.orange,
                ),
                title: Text("Usuario: ${asistente['userId']}"),
                subtitle: Text("Estado: ${asistente['estado']}"),
              );
            },
          );
        },
      ),
    );
  }
}
