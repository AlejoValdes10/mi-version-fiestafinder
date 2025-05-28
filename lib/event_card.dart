import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class EventCard extends StatelessWidget {
  final Map<String, dynamic> event;
  final bool isFavorite;
  final Function(Map<String, dynamic>) onToggleFavorite;

  const EventCard({
    Key? key,
    required this.event,
    required this.isFavorite,
    required this.onToggleFavorite,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.all(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showEventDetails(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: CachedNetworkImage(
                imageUrl: event['image']?.isNotEmpty == true 
                    ? event['image'] 
                    : 'https://via.placeholder.com/400?text=Imagen+no+disponible',
                placeholder: (context, url) => Container(
                  height: 150,
                  color: Colors.grey[200],
                  child: Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 150,
                  color: Colors.grey[200],
                  child: Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                ),
                fit: BoxFit.cover,
                height: 150,
              ),
            ),
            
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event['eventName'] ?? 'Nombre no disponible',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : Colors.grey,
                        ),
                        onPressed: () => onToggleFavorite(event),
                      ),
                    ],
                  ),
                  
                  _buildInfoRow(Icons.location_on, event['localidad'] ?? 'No especificado'),
                  _buildInfoRow(Icons.calendar_today, 
                      '${event['fecha'] ?? 'Fecha no disponible'} • ${event['hora'] ?? ''}'),
                  _buildInfoRow(Icons.people, 
                      'Capacidad: ${event['capacidad'] ?? 'No especificada'}'),
                  
                  if (event['etiquetas'] != null && (event['etiquetas'] as List).isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Wrap(
                        spacing: 4,
                        children: (event['etiquetas'] as List).map<Widget>((tag) => Chip(
                          label: Text(tag.toString()),
                          backgroundColor: Colors.blue[50],
                          labelStyle: TextStyle(fontSize: 12),
                        )).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showEventDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
  height: MediaQuery.of(context).size.height * 0.85,
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  ),
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
              SizedBox(height: 16),
              
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: event['image']?.isNotEmpty == true 
                      ? event['image'] 
                      : 'https://via.placeholder.com/800x400?text=Imagen+no+disponible',
                  placeholder: (context, url) => Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
                  ),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 200,
                ),
              ),
              SizedBox(height: 20),
              
              Row(
                children: [
                  Expanded(
                    child: Text(
                      event['eventName'] ?? 'Evento sin nombre',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.grey,
                      size: 28,
                    ),
                    onPressed: () {
                      onToggleFavorite(event);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              
              _buildDetailSection(
                title: 'Información del Evento',
                children: [
                  _buildDetailItem(Icons.category, 'Tipo', event['tipo'] ?? 'No especificado'),
                  _buildDetailItem(Icons.location_on, 'Localidad', event['localidad'] ?? 'No especificada'),
                  _buildDetailItem(Icons.calendar_today, 'Fecha', event['fecha'] ?? 'No especificada'),
                  _buildDetailItem(Icons.access_time, 'Hora', event['hora'] ?? 'No especificada'),
                  _buildDetailItem(Icons.place, 'Dirección', event['direccion'] ?? 'No especificada'),
                  _buildDetailItem(Icons.people, 'Capacidad', event['capacidad']?.toString() ?? 'No especificada'),
                  _buildDetailItem(Icons.attach_money, 'Costo', 
                      event['costo'] > 0 ? '\$${event['costo']}' : 'Gratis'),
                ],
              ),
              
              _buildDetailSection(
                title: 'Descripción',
                children: [
                  Text(
                    event['descripcion'] ?? 'No hay descripción disponible',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
              
              if (event['mediosPago'] != null && (event['mediosPago'] as List).isNotEmpty)
                _buildDetailSection(
                  title: 'Medios de Pago',
                  children: [
                    Wrap(
                      spacing: 8,
                      children: (event['mediosPago'] as List).map<Widget>((medio) => Chip(
                        label: Text(medio.toString()),
                        backgroundColor: Colors.green[50],
                      )).toList(),
                    ),
                  ],
                ),
              
              _buildDetailSection(
                title: 'Características',
                children: [
                  _buildFeatureChip('Accesibilidad', event['accesibilidad'] == true),
                  _buildFeatureChip('Parqueadero', event['parqueadero'] == true),
                  _buildFeatureChip('Puerta a puerta', event['puertaAPuerta'] == true),
                ],
              ),
              
              if (event['politicas'] != null && event['politicas'].toString().isNotEmpty)
                _buildDetailSection(
                  title: 'Políticas del Evento',
                  children: [
                    Text(event['politicas'].toString()),
                  ],
                ),
              
              _buildDetailSection(
                title: 'Contacto',
                children: [
                  Text(event['contacto'] ?? 'No hay contacto disponible'),
                ],
              ),
              
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue[800],
          ),
        ),
        Divider(),
        ...children,
      ],
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(String label, bool isAvailable) {
    return Padding(
      padding: EdgeInsets.only(right: 8, bottom: 8),
      child: Chip(
        label: Text(label),
        avatar: Icon(
          isAvailable ? Icons.check : Icons.close,
          size: 16,
          color: isAvailable ? Colors.green : Colors.red,
        ),
        backgroundColor: isAvailable ? Colors.green[50] : Colors.red[50],
      ),
    );
  }
}