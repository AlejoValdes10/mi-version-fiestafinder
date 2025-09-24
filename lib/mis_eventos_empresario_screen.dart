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
        backgroundColor: Colors.blue,
      ),
      body: FutureBuilder<String>(
        future: _getCurrentUserId(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final empresarioId = snapshot.data!;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('eventos')
                .where('empresarioId', isEqualTo: empresarioId)
                .snapshots(),
            builder: (context, eventSnapshot) {
              if (eventSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!eventSnapshot.hasData || eventSnapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text("No tienes eventos creados."),
                );
              }

              final eventos = eventSnapshot.data!.docs;

              return ListView.builder(
                itemCount: eventos.length,
                itemBuilder: (context, index) {
                  final evento = eventos[index];
                  final eventoId = evento.id;
                  final nombreEvento = evento['nombre'] ?? 'Sin nombre';
                  final costo = evento['costo'] ?? 'Gratis';

                  return ExpansionTile(
                    title: Text(nombreEvento),
                    subtitle: Text("Costo: $costo"),
                    children: [
                      
                    ],
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
