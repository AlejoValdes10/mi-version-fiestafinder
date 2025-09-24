import 'package:flutter/material.dart';

class MisReservasScreen extends StatelessWidget {
  const MisReservasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mis Reservas")),
      body: const Center(
        child: Text("Aquí se mostrarán las reservas del usuario."),
      ),
    );
  }
}
