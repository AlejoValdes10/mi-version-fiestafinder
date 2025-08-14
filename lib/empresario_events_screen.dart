import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class EmpresarioEventsScreen extends StatefulWidget {
  final User user;
  const EmpresarioEventsScreen({Key? key, required this.user}) : super(key: key);

  @override
  EmpresarioEventsScreenState createState() => EmpresarioEventsScreenState();
}

class EmpresarioEventsScreenState extends State<EmpresarioEventsScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mis Eventos', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'Pendientes'),
            Tab(text: 'Aprobados'),
            Tab(text: 'Rechazados'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEventsList('pending'),
          _buildEventsList('approved'),
          _buildEventsList('rejected'),
        ],
      ),
    );
  }

  Widget _buildEventsList(String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('eventos')
          .where('creatorId', isEqualTo: widget.user.uid) // Cambiado a creatorId
          .where('status', isEqualTo: status)
          .orderBy('fechaTimestamp', descending: false) // Ordenar por fecha
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getIconForStatus(status),
                  size: 50,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16),
                Text(
                  'No hay eventos ${_getStatusText(status).toLowerCase()}',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        final events = snapshot.data!.docs;

        return ListView.builder(
          padding: EdgeInsets.all(12),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            final data = event.data() as Map<String, dynamic>;
            
            return _buildEventCard(data, status);
          },
        );
      },
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event, String status) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');
    
    DateTime? eventDate;
    try {
      if (event['fecha'] != null) {
        eventDate = dateFormat.parse(event['fecha']);
      }
    } catch (e) {
      debugPrint('Error parsing date: $e');
    }

    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Aquí puedes agregar la navegación a los detalles del evento
        },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    event['eventName'] ?? 'Sin nombre',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Chip(
                    label: Text(
                      _getStatusText(status),
                      style: TextStyle(color: Colors.white),
                    ),
                    backgroundColor: _getColorForStatus(status),
                  ),
                ],
              ),
              SizedBox(height: 8),
              if (event['descripcion'] != null)
                Text(
                  event['descripcion'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  SizedBox(width: 8),
                  Text(
                    eventDate != null ? 
                      '${dateFormat.format(eventDate)} • ${event['hora'] ?? ''}' : 
                      'Fecha no disponible',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event['direccion'] ?? 'Dirección no especificada',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              if (status == 'rejected' && event['rejectionReason'] != null)
                Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Razón del rechazo:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      Text(event['rejectionReason']),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending': return 'Pendiente';
      case 'approved': return 'Aprobado';
      case 'rejected': return 'Rechazado';
      default: return status;
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