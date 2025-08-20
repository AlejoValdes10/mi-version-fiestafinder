import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EventCard extends StatelessWidget {
  final Map<String, dynamic> event;
  final bool isFavorite;
  final Function(Map<String, dynamic>) onToggleFavorite;

  const EventCard({
    super.key,
    required this.event,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  // Método auxiliar para obtener campos con valor por defecto
  dynamic _getField(String key, [dynamic defaultValue = '--']) {
    final value = event[key];
    return (value != null && value.toString().trim().isNotEmpty)
        ? value
        : defaultValue;
  }

  // Método para obtener el precio formateado
  String _getPrice() {
    final bool esGratis = _getField('esGratis', false);
    if (esGratis) return 'Gratis';

    final price = _getField('costo');
    if (price == null) return 'Consultar precio';

    if (price is num) {
      return price <= 0 ? 'Gratis' : '\$${price.toStringAsFixed(0)}';
    }

    final parsed = double.tryParse(price.toString().replaceAll(',', '.'));
    return parsed == null
        ? 'Consultar precio'
        : parsed <= 0
        ? 'Gratis'
        : '\$${parsed.toStringAsFixed(0)}';
  }

  // Método para obtener los medios de pago
  String _getMediosPago() {
    final mediosPago = _getField('mediosPago', []);
    if (mediosPago is List && mediosPago.isNotEmpty) {
      return mediosPago.join(', ');
    }
    return 'Efectivo';
  }

  // Método para mostrar políticas de privacidad
  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text(
              'Políticas de Privacidad',
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'En Fiesta Finder nos comprometemos a proteger tu privacidad. Esta política explica cómo recopilamos, usamos y protegemos tu información personal:',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 12),
                  Text(
                    '• Recopilamos información que nos proporcionas al registrarte o crear eventos',
                    style: TextStyle(fontSize: 14),
                  ),
                  Text(
                    '• Utilizamos tu información para mejorar nuestros servicios y personalizar tu experiencia',
                    style: TextStyle(fontSize: 14),
                  ),
                  Text(
                    '• Protegemos tus datos con medidas de seguridad avanzadas',
                    style: TextStyle(fontSize: 14),
                  ),
                  Text(
                    '• No compartimos tu información personal con terceros sin tu consentimiento',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Al utilizar nuestra aplicación, aceptas estas políticas de privacidad.',
                    style: TextStyle(fontStyle: FontStyle.italic, fontSize: 14),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showEventDetails(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sección de imagen con título y favoritos
            _buildImageSection(),

            // Contenido mínimo de la tarjeta (solo tipo y precio)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .start, // Cambiado a start para alinear a la izquierda
                children: [
                  // Tipo de evento
                  if (_getField('tipo') != '--')
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(_getField('tipo')),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getField('tipo'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12, // Tamaño reducido
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                  const SizedBox(width: 8), // Espacio reducido
                  // Precio
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ), // Tamaño reducido
                    decoration: BoxDecoration(
                      color:
                          _getPrice() == 'Gratis'
                              ? Colors.green[50]
                              : Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            _getPrice() == 'Gratis'
                                ? Colors.green[100]!
                                : Colors.blue[100]!,
                      ),
                    ),
                    child: Text(
                      _getPrice(),
                      style: TextStyle(
                        fontSize: 12, // Tamaño reducido
                        fontWeight: FontWeight.bold,
                        color:
                            _getPrice() == 'Gratis'
                                ? Colors.green[800]
                                : Colors.blue[800],
                      ),
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

  Widget _buildImageSection() {
    return Stack(
      children: [
        // Imagen del evento
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: CachedNetworkImage(
            imageUrl:
                _getField('image', '').toString().isNotEmpty
                    ? _getField('image').toString()
                    : 'https://via.placeholder.com/400x200?text=Evento',
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            errorWidget:
                (_, __, ___) => Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: const Icon(Icons.event, size: 50, color: Colors.grey),
                ),
          ),
        ),

        // Gradiente overlay para mejor contraste del texto
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                stops: const [0.1, 0.5],
              ),
            ),
          ),
        ),

        // Título superpuesto en la parte inferior de la imagen
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Text(
            _getField('eventName', _getField('name', 'Evento sin nombre')),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  offset: Offset(1, 1),
                  blurRadius: 4,
                  color: Colors.black,
                ),
              ],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // Botón de favorito
        Positioned(
          top: 12,
          right: 12,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => onToggleFavorite(event),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: isFavorite ? Colors.red : Colors.grey[600],
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'gastrobar':
        return Colors.orange[800]!;
      case 'discotecas':
        return Colors.purple[700]!;
      case 'cultural':
        return Colors.teal[700]!;
      case 'deportivo':
        return Colors.blue[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  void _showEventDetails(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            insetPadding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isSmallScreen ? double.infinity : 600,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Imagen
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                          child: CachedNetworkImage(
                            imageUrl: _getField('image', '').toString(),
                            width: double.infinity,
                            height: isSmallScreen ? 220 : 280,
                            fit: BoxFit.cover,
                            errorWidget:
                                (_, __, ___) => Container(
                                  color: Colors.grey[200],
                                  height: isSmallScreen ? 220 : 280,
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    size: 50,
                                  ),
                                ),
                          ),
                        ),
                        Positioned(
                          top: 16,
                          right: 16,
                          child: CircleAvatar(
                            backgroundColor: Colors.white.withOpacity(0.9),
                            child: IconButton(
                              icon: Icon(
                                isFavorite
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color:
                                    isFavorite ? Colors.red : Colors.grey[600],
                              ),
                              onPressed: () {
                                onToggleFavorite(event);
                                Navigator.of(context).pop();
                                _showEventDetails(context);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Contenido - ORDEN MODIFICADO
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Nombre del evento y precio a la derecha
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  _getField(
                                    'eventName',
                                    _getField('name', 'Evento sin nombre'),
                                  ),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      _getPrice() == 'Gratis'
                                          ? Colors.green[50]
                                          : Colors.blue[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        _getPrice() == 'Gratis'
                                            ? Colors.green[100]!
                                            : Colors.blue[100]!,
                                  ),
                                ),
                                child: Text(
                                  _getPrice(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        _getPrice() == 'Gratis'
                                            ? Colors.green[800]
                                            : Colors.blue[800],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // 2. Tipo de evento
                          if (_getField('tipo') != '--')
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getCategoryColor(_getField('tipo')),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getField('tipo'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),

                          const SizedBox(height: 24),

                          // 3. Descripción del evento (AHORA ARRIBA de fecha/hora)
                          const Text(
                            'Descripción',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getField(
                              'descripcion',
                              'No hay descripción disponible',
                            ),
                            style: const TextStyle(fontSize: 16, height: 1.5),
                          ),

                          const SizedBox(height: 24),

                          // 4. Fecha y hora (AHORA ABAJO de la descripción)
                          const Text(
                            'Fecha y Hora',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 20,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _getField('fecha'),
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(width: 16),
                              Icon(
                                Icons.access_time_rounded,
                                size: 20,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _getField('hora', 'Por confirmar'),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // 5. Ubicación exacta
                          const Text(
                            'Ubicación',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: 20,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _getField(
                                    'direccion',
                                    _getField(
                                      'localidad',
                                      'Ubicación no especificada',
                                    ),
                                  ),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // 6. Parqueadero y accesibilidad
                          const Text(
                            'Servicios',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              // Parqueadero
                              Expanded(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.local_parking_rounded,
                                      size: 30,
                                      color:
                                          _getField('parqueadero', false)
                                              ? Colors.green
                                              : Colors.grey,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _getField('parqueadero', false)
                                          ? 'Con parqueadero'
                                          : 'Sin parqueadero',
                                      style: TextStyle(
                                        color:
                                            _getField('parqueadero', false)
                                                ? Colors.green
                                                : Colors.grey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Accesibilidad
                              Expanded(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.accessible_rounded,
                                      size: 30,
                                      color:
                                          _getField('accesibilidad', false)
                                              ? Colors.green
                                              : Colors.grey,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _getField('accesibilidad', false)
                                          ? 'Accesible'
                                          : 'No accesible',
                                      style: TextStyle(
                                        color:
                                            _getField('accesibilidad', false)
                                                ? Colors.green
                                                : Colors.grey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // 7. Medios de pago (solo si no es gratis)
                          if (_getField('esGratis', false) == false) ...[
                            const Text(
                              'Medios de pago aceptados',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _getMediosPago(),
                              style: const TextStyle(fontSize: 16, height: 1.5),
                            ),

                            const SizedBox(height: 16),

                            // Políticas de privacidad (NUEVO)
                            GestureDetector(
                              onTap: () => _showPrivacyPolicy(context),
                              child: const Center(
                                child: Text(
                                  'Políticas de Privacidad',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }
}
