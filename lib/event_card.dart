import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

  String obtenerCampo(String clave) {
    final valor = event[clave];
    debugPrint('Intentando obtener campo: "$clave" → Valor recibido: $valor (${valor.runtimeType})');
    if (valor != null && valor.toString().trim().isNotEmpty) {
      return valor.toString();
    }
    debugPrint('! Campo "$clave" NO ESPECIFICADO');
    return 'NO ESPECIFICADA';
  }

  String obtenerCosto() {
    final costoRaw = event['costo'];
    debugPrint('🗾 [COSTO] Valor crudo recibido: $costoRaw (${costoRaw.runtimeType})');

    if (costoRaw == null) {
      debugPrint('❌ [COSTO] Valor es null');
      return 'NO ESPECIFICADA';
    }

    if (costoRaw is num) {
      if (costoRaw <= 0) {
        debugPrint('ℹ️ [COSTO] Valor numérico es cero o negativo → GRATIS');
        return 'GRATIS';
      }
      debugPrint('✅ [COSTO] Valor numérico válido → \$${costoRaw.toStringAsFixed(0)}');
      return '\$${costoRaw.toStringAsFixed(0)}';
    } else {
      debugPrint('⚠️ [COSTO] Tipo inesperado, intentando parsear como double');
      final costoString = costoRaw.toString().replaceAll(',', '.');
      final costoNum = double.tryParse(costoString);

      if (costoNum == null) {
        debugPrint('❌ [COSTO] No se pudo convertir a número');
        return 'NO ESPECIFICADA';
      } else if (costoNum <= 0) {
        debugPrint('ℹ️ [COSTO] Valor convertido es cero o negativo → GRATIS');
        return 'GRATIS';
      }

      debugPrint('✅ [COSTO] Valor convertido válido → \$${costoNum.toStringAsFixed(0)}');
      return '\$${costoNum.toStringAsFixed(0)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(obtenerCampo('name')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dirección: ${obtenerCampo('localidad')}'),
                Text('Fecha: ${obtenerCampo('fecha')}'),
                Text('Costo: ${obtenerCosto()}'),
                Text('Descripción: ${obtenerCampo('descripcion')}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              )
            ],
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            color: Colors.white,
            child: Row(
              children: [
                CachedNetworkImage(
                  imageUrl: obtenerCampo('image'),
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => const Icon(Icons.image_not_supported),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          obtenerCampo('name'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(obtenerCampo('localidad')),
                        Text(obtenerCampo('fecha')),
                        Text(obtenerCosto(), style: const TextStyle(color: Colors.green)),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: Colors.red,
                  ),
                  onPressed: () => onToggleFavorite(event),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget buildEventList(Stream<QuerySnapshot> eventStream) {
  return StreamBuilder<QuerySnapshot>(
    stream: eventStream,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      if (snapshot.hasError) {
        debugPrint("🔥 Error cargando eventos: \${snapshot.error}");
        return const Center(child: Text("Error al cargar eventos"));
      }

      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return const Center(child: Text("No hay eventos disponibles"));
      }

      final events = snapshot.data!.docs;

      return ListView.builder(
        itemCount: events.length,
        itemBuilder: (context, index) {
          final doc = events[index];
          final data = doc.data() as Map<String, dynamic>;

          debugPrint("🔎 ID: \${doc.id}");
          debugPrint("🔍 Campo 'eventName': \${data['eventName']} (\${data['eventName']?.runtimeType})");
          debugPrint("📬 Campo 'direccion': \${data['direccion']} (\${data['direccion']?.runtimeType})");
          debugPrint("💸 Campo 'costo': \${data['costo']} (\${data['costo']?.runtimeType})");

          final event = {
            ...data,
            'id': doc.id,
            'name': data['eventName'] ?? '',
            'localidad': data['direccion'] ?? '',
            'costo': data['costo'] ?? 0,
          };

          return EventCard(
            event: event,
            isFavorite: false,
            onToggleFavorite: (e) {},
          );
        },
      );
    },
  );
}