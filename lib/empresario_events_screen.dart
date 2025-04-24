import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmpresarioEventsScreen extends StatefulWidget {
  final User user;
  const EmpresarioEventsScreen({Key? key, required this.user}) : super(key: key);

  @override
  EmpresarioEventsScreenState createState() => EmpresarioEventsScreenState();
}

class EmpresarioEventsScreenState extends State<EmpresarioEventsScreen> 
    with SingleTickerProviderStateMixin { // ✅ Necesario para el TabController
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // ✅ 3 pestañas
  }

  @override
  void dispose() {
    _tabController.dispose(); // ✅ Liberar memoria
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mis Eventos'),
        bottom: TabBar(
          controller: _tabController, // ✅ Asignar controlador
          tabs: [
            Tab(text: 'Pendientes'),
            Tab(text: 'Aprobados'),
            Tab(text: 'Rechazados'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController, // ✅ Asignar controlador
        children: [
          _buildEventsList('pending'),
          _buildEventsList('approved'),
          _buildEventsList('rejected'),
        ],
      ),
    );
  }

  // ✅ Widget para mostrar la lista de eventos (sin cambios de diseño)
  Widget _buildEventsList(String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('eventos')
          .where('createdBy', isEqualTo: widget.user.uid)
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final events = snapshot.data!.docs;

        if (events.isEmpty) {
          return Center(
            child: Text('No hay eventos ${_getStatusText(status)}'),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(8),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return Card(
              margin: EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: Icon(
                  _getIconForStatus(status),
                  color: _getColorForStatus(status),
                ),
                title: Text(event['eventName']),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event['descripcion']),
                    if (status == 'rejected')
                      Text(
                        'Razón: ${event['rejectionReason']}',
                        style: TextStyle(color: Colors.red),
                      ),
                  ],
                ),
                trailing: Text(
                  _getStatusText(status),
                  style: TextStyle(
                    color: _getColorForStatus(status),
                    fontWeight: FontWeight.bold),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ✅ Funciones auxiliares (sin cambios)
  String _getStatusText(String status) {
    switch (status) {
      case 'pending': return 'Pendiente';
      case 'approved': return 'Aprobado';
      case 'rejected': return 'Rechazado';
      default: return '';
    }
  }

  IconData _getIconForStatus(String status) {
    switch (status) {
      case 'approved': return Icons.check_circle;
      case 'rejected': return Icons.cancel;
      default: return Icons.pending;
    }
  }

  Color _getColorForStatus(String status) {
    switch (status) {
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      default: return Colors.orange;
    }
  }
}