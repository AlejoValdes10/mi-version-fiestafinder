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

  String _getField(String key, [String defaultValue = '--']) {
    final value = event[key];
    return (value != null && value.toString().trim().isNotEmpty)
        ? value.toString()
        : defaultValue;
  }

  String _getPrice() {
    final price = event['costo'];
    if (price == null) return 'Consultar';

    if (price is num) {
      return price <= 0 ? 'Gratis' : '\$${price.toStringAsFixed(0)}';
    }

    final parsed = double.tryParse(price.toString().replaceAll(',', '.'));
    return parsed == null
        ? 'Consultar'
        : parsed <= 0
        ? 'Gratis'
        : '\$${parsed.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSmallScreen = MediaQuery.of(context).size.width < 400;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        final isWide = cardWidth > 600;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 16,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _showEventDetails(context),
            child:
                isWide
                    ? _buildWideCard(theme)
                    : _buildNormalCard(theme, isSmallScreen),
          ),
        );
      },
    );
  }

  Widget _buildNormalCard(ThemeData theme, bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: CachedNetworkImage(
                imageUrl:
                    _getField('image', '').isNotEmpty
                        ? _getField('image')
                        : 'https://via.placeholder.com/400x200?text=Evento',
                height: isSmallScreen ? 140 : 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _buildPlaceholder(),
              ),
            ),
            _buildFavoriteButton(),
            _buildImageOverlay(),
            _buildEventTitle(theme),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailItem(
                Icons.location_on_outlined,
                _getField('localidad'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      Icons.calendar_month_outlined,
                      _getField('fecha'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  _buildPriceTag(),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWideCard(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          flex: 2,
          child: ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(18),
            ),
            child: Stack(
              children: [
                CachedNetworkImage(
                  imageUrl:
                      _getField('image', '').isNotEmpty
                          ? _getField('image')
                          : 'https://via.placeholder.com/600x300?text=Evento',
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _buildPlaceholder(),
                ),
                _buildFavoriteButton(),
                _buildImageOverlay(),
              ],
            ),
          ),
        ),
        Flexible(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getField('name', 'Evento sin nombre'),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                _buildDetailItem(
                  Icons.location_on_outlined,
                  _getField('localidad'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildDetailItem(
                      Icons.calendar_month_outlined,
                      _getField('fecha'),
                    ),
                    const Spacer(),
                    _buildPriceTag(),
                  ],
                ),
                const SizedBox(height: 12),
                if (_getField('descripcion').length < 100)
                  Text(
                    _getField('descripcion'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(Icons.event, size: 50, color: Colors.grey[400]),
      ),
    );
  }

  Widget _buildFavoriteButton() {
    return Positioned(
      top: 12,
      right: 12,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // Llamada correcta al callback con el evento
            onToggleFavorite(event);
          },
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: isFavorite ? Colors.red[400] : Colors.grey[600],
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageOverlay() {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withOpacity(0.4), Colors.transparent],
          ),
        ),
      ),
    );
  }

  Widget _buildEventTitle(ThemeData theme) {
    return Positioned(
      left: 16,
      bottom: 16,
      right: 16,
      child: Text(
        _getField('name', 'Evento sin nombre'),
        style: theme.textTheme.titleMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            style: TextStyle(fontSize: 14, color: Colors.grey[800]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceTag() {
    final price = _getPrice();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: price == 'Gratis' ? Colors.green[50] : Colors.blue[50],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        price,
        style: TextStyle(
          color: price == 'Gratis' ? Colors.green[800] : Colors.blue[800],
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showEventDetails(BuildContext context) {
    final theme = Theme.of(context);
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
                    // Sección de imagen
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                          child: CachedNetworkImage(
                            imageUrl: _getField('image', ''),
                            width: double.infinity,
                            height: isSmallScreen ? 200 : 250,
                            fit: BoxFit.cover,
                            errorWidget:
                                (_, __, ___) => Container(
                                  color: Colors.grey[200],
                                  height: isSmallScreen ? 200 : 250,
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
                                    isFavorite
                                        ? Colors.red[400]
                                        : Colors.grey[600],
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

                    // Contenido del diálogo
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Título y precio
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _getField('name', 'Evento sin nombre'),
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    if (_getField('tipo') != '--')
                                      Chip(
                                        label: Text(_getField('tipo')),
                                        backgroundColor: Colors.blue[600],
                                        labelStyle: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      _getPrice() == 'Gratis'
                                          ? Colors.green[50]
                                          : Colors.blue[50],
                                  borderRadius: BorderRadius.circular(12),
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

                          const SizedBox(height: 24),

                          // Sección de fecha/hora
                          _buildDetailRow(
                            icon: Icons.calendar_today,
                            label: 'Fecha y Hora',
                            value:
                                '${_getField('fecha')} • ${_getField('hora', '--')}',
                          ),

                          // Sección de ubicación
                          _buildDetailRow(
                            icon: Icons.location_on,
                            label: 'Ubicación',
                            value: _getField('localidad'),
                          ),

                          // Sección de descripción
                          const SizedBox(height: 16),
                          const Text(
                            'Descripción',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getField(
                              'descripcion',
                              'No hay descripción disponible',
                            ),
                            style: const TextStyle(fontSize: 16),
                          ),

                          // Botón de acción (opcional)
                          if (_getField('link') != '--') ...[
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[600],
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () {
                                  // Abrir enlace del evento
                                },
                                child: const Text(
                                  'VER MÁS DETALLES',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
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

  // Método auxiliar para construir filas de detalles
  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blue[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogItem(
    String label,
    String text, {
    bool isHighlighted = false,
    bool isMultiline = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: isHighlighted ? Colors.green[600] : Colors.black,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
            ),
            maxLines: isMultiline ? null : 2,
            overflow: isMultiline ? null : TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
