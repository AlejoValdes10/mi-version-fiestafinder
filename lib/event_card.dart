import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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

  dynamic _getField(String key, [dynamic defaultValue = '--']) {
  final value = event[key];
  if (value == null) return defaultValue;
  if (value is String && value.trim().isEmpty) return defaultValue;
  return value;
}


  String _getPrice() {
    final bool esGratis = _getField('esGratis', false);
    if (esGratis) return 'Gratis';

    final price = _getField('costo', null);

    if (price == null || price.toString().trim().isEmpty) {
      return 'Consultar precio';
    }

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

  String _getCapacidad() {
    final tieneCapacidad = _getField('tieneCapacidad', false);
    final capacidad = _getField('capacidad', 0);
    if (tieneCapacidad && capacidad > 0) {
      return "$capacidad personas";
    }
    return "Ilimitado";
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
        mainAxisSize: MainAxisSize.min, // 👈 deja que el alto se ajuste al contenido
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildImageSection(), // la imagen arriba
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // 👈 también aquí
              children: [
                Text(
                  _getField('eventName', _getField('name', 'Evento sin nombre')),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 6),

                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _getField('direccion', _getField('localidad', 'Ubicación no especificada')),
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // 📌 Fecha en una fila
Row(
  children: [
    Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
    const SizedBox(width: 4),
    Expanded(
      child: Text(
        _getField('fecha', 'Por definir'),
        style: const TextStyle(fontSize: 14),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ),
  ],
),

const SizedBox(height: 6),

// 📌 Capacidad en otra fila
Row(
  children: [
    Icon(Icons.people, size: 16, color: Colors.grey[600]),
    const SizedBox(width: 4),
    Expanded(
      child: Text(
        _getCapacidad(),
        style: const TextStyle(fontSize: 14),
        maxLines: 1,
        overflow: TextOverflow.ellipsis, // 🔹 controla "Ilimitado"
      ),
    ),
  ],
),



                const SizedBox(height: 12),

                Row(
                  children: [
                    if (_getField('tipo') != '--')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(_getField('tipo')),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getField('tipo'),
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),

                    const SizedBox(width: 8),
                    Expanded(
  child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: _getPrice() == 'Gratis' ? Colors.green[50] : Colors.blue[50],
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: _getPrice() == 'Gratis' ? Colors.green[100]! : Colors.blue[100]!,
      ),
    ),
    child: Text(
      _getPrice(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: _getPrice() == 'Gratis' ? Colors.green[800] : Colors.blue[800],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis, // 👈 evita overflow en números largos
    ),
  ),
),

                  ],
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
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: CachedNetworkImage(
            imageUrl: _getField('image', '').toString().isNotEmpty
                ? _getField('image').toString()
                : 'https://via.placeholder.com/400x200?text=Evento',
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),

        // sombreado
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                stops: const [0.1, 0.5],
              ),
            ),
          ),
        ),

        Positioned(
          top: 12,
          right: 12,
          child: InkWell(
            onTap: () => onToggleFavorite(event),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : Colors.grey[600],
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
    final imageUrl = _getField('image', _getField('imagen', '')).toString();
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoPopupSurface(
        isSurfacePainted: true,
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
          child: SafeArea(
            top: false,
            child: Material(
              color: CupertinoColors.systemBackground.resolveFrom(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // top grab handle
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Imagen grande (aspectRatio para que no se estire ni se recorte extra)
                  if (imageUrl.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            imageBuilder: (context, imageProvider) => Image(
                              image: imageProvider,
                              fit: BoxFit.cover,
                              filterQuality: FilterQuality.high,
                            ),
                            placeholder: (c, u) => Container(color: Colors.transparent),
                            errorWidget: (c, u, e) => Container(
                              color: Colors.grey[200],
                              child: const Center(child: Icon(Icons.broken_image)),
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Container(
                        height: 190,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFF7F9FB), Color(0xFFEFF3F6)],
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Contenido scrollable
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getField('eventName', _getField('name', 'Evento sin nombre')).toString(),
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 8),

                          Row(
                            children: [
                              const Icon(CupertinoIcons.calendar, size: 18),
                              const SizedBox(width: 8),
                              Text(_getField('fecha', 'Por definir').toString(), style: const TextStyle(fontSize: 15)),
                              const SizedBox(width: 14),
                              const Icon(CupertinoIcons.time, size: 18),
                              const SizedBox(width: 8),
                              Text(_getField('hora', 'Por confirmar').toString(), style: const TextStyle(fontSize: 15)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(CupertinoIcons.location, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
  child: Text(
    _getField('direccion', _getField('address', 'Ubicación no disponible')).toString(),
    style: const TextStyle(fontSize: 15),
  ),
),

                            ],
                          ),
                          const SizedBox(height: 16),

                          // acciones rápidas (compartir, ruta, guardar)
                          Row(
                            children: [
                              _actionButton(context, CupertinoIcons.share, "Compartir", () {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Compartir (placeholder)')));
                              }),
                              const SizedBox(width: 10),
                              _actionButton(context, CupertinoIcons.location_solid, "Ruta", () {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Abrir mapa (placeholder)')));
                              }),
                              const SizedBox(width: 10),
                              _actionButton(context, isFavorite ? CupertinoIcons.heart_solid : CupertinoIcons.heart, "Favorito", () {
                                onToggleFavorite(event);
                              }),
                            ],
                          ),
                          const SizedBox(height: 18),
                          const Divider(),
                          const SizedBox(height: 12),

                          // Descripción
                          const Text("Descripción", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Text(
                            _getField('descripcion', 'No hay descripción').toString(),
                            style: const TextStyle(fontSize: 15, height: 1.45, color: Colors.black87),
                          ),
                          const SizedBox(height: 16),

                          // Información extra (uso FaIcon para accesibilidad)
                          _detailRow(Icon(CupertinoIcons.person_2, size: 18, color: Colors.black54), "Capacidad", _getCapacidad()),
                          const SizedBox(height: 8),
                          _detailRow(Icon(CupertinoIcons.money_dollar, size: 18, color: Colors.black54), "Costo", _getPrice()),
                          const SizedBox(height: 8),
                          _detailRow(Icon(CupertinoIcons.square_list, size: 18, color: Colors.black54), "Tipo", _getField('tipo', 'No definido').toString()),
                          const SizedBox(height: 8),
                          // accesibilidad - icono de FontAwesome
                          _detailRow(const FaIcon(FontAwesomeIcons.wheelchair, size: 18, color: Colors.black54), "Accesibilidad", _getField('accesibilidad', false) ? 'Sí' : 'No'),
                          const SizedBox(height: 8),
                          _detailRow(Icon(CupertinoIcons.car_detailed, size: 18, color: Colors.black54), "Parqueadero", _getField('parqueadero', false) ? 'Sí' : 'No'),
                          const SizedBox(height: 30),

                          // botón de acción principal (ej: reservar / comprar)
                          SizedBox(
                            width: double.infinity,
                            child: CupertinoButton.filled(
                              borderRadius: BorderRadius.circular(12),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              onPressed: () {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Acción principal (placeholder)')));
                              },
                              child: Text(_getPrice() == 'Gratis' ? 'Registrar gratis' : 'Comprar / Reservar'),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionButton(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: Colors.black87),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(Widget iconWidget, String label, String value) {
    return Row(
      children: [
        iconWidget,
        const SizedBox(width: 10),
        Text("$label:", style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(width: 8),
        Expanded(child: Text(value, style: const TextStyle(color: Colors.black87))),
      ],
    );
  }
}
