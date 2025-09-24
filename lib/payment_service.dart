import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 🔹 Diálogo bonito reutilizable
void _showCustomDialog(
  BuildContext context, {
  required String title,
  required String message,
  required IconData icon,
  required Color color,
  String buttonText = "OK",
}) {
  showDialog(
    context: context,
    builder:
        (_) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 40,
            vertical: 24,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 48, color: color),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      buttonText,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
  );
}

/// 🔹 Función principal para manejar pagos y registros
Future<void> handlePayment(
  BuildContext context,
  Map<String, dynamic> event,
  String eventId,
) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    _showCustomDialog(
      context,
      title: "Inicia sesión",
      message: "Debes iniciar sesión para continuar con la reserva.",
      icon: Icons.warning_amber_rounded,
      color: Colors.orange,
    );
    return;
  }

  // ✅ Detectar si el evento es gratis o de pago
  double price = 0.0;
  final esGratis = (event['esGratis'] == true);

  if (!esGratis) {
    final costo = event['costo'];
    if (costo is num) {
      price = costo.toDouble();
    } else {
      price =
          double.tryParse(
            costo?.toString()?.replaceAll(RegExp(r'[^0-9\.,]'), '') ?? '',
          ) ??
          0.0;
    }
  }

  // ✅ Evento gratis
  if (price == 0) {
    await FirebaseFirestore.instance.collection('reservas').add({
      'eventoId': eventId,
      'userId': user.uid,
      'estado': 'confirmado',
      'price': 0,
      'paymentMethod': 'Gratis',
      'timestamp': FieldValue.serverTimestamp(),
    });

    _showCustomDialog(
      context,
      title: "Registro exitoso 🎉",
      message: "Te has registrado correctamente a este evento (gratis).",
      icon: Icons.check_circle_rounded,
      color: Colors.green,
      buttonText: "Perfecto",
    );
    return;
  }

  // ✅ Evento de pago → Mostrar selector de método de pago
  List<String> paymentOptions = [];
  if (event['mediosPago'] is List) {
    paymentOptions = List<String>.from(
      event['mediosPago'].map((e) => e.toString()),
    );
  }
  if (paymentOptions.isEmpty) {
    paymentOptions = ['Tarjeta', 'PSE', 'Efectivo'];
  }

  String selectedMethod = paymentOptions.first;

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Confirmar compra'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Precio: \$${price.toStringAsFixed(0)}'),
                const SizedBox(height: 12),
                const Text(
                  'Selecciona método de pago:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ...paymentOptions.map((m) {
                  return RadioListTile<String>(
                    value: m,
                    groupValue: selectedMethod,
                    title: Text(m),
                    onChanged: (v) => setState(() => selectedMethod = v!),
                  );
                }).toList(),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);

                  // 🔄 Mostrar "Procesando..."
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder:
                        (_) => Dialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text(
                                  'Procesando pago...',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                  );

                  await Future.delayed(const Duration(seconds: 2));
                  Navigator.pop(context); // cerrar "procesando"

                  // Guardar en Firestore
                  await FirebaseFirestore.instance.collection('reservas').add({
                    'eventoId': eventId,
                    'userId': user.uid,
                    'estado': 'pago confirmado',
                    'price': price,
                    'paymentMethod': selectedMethod,
                    'timestamp': FieldValue.serverTimestamp(),
                  });

                  _showCustomDialog(
                    context,
                    title: "Pago exitoso ✅",
                    message:
                        "Tu compra se ha confirmado con $selectedMethod.\n¡Disfruta el evento!",
                    icon: Icons.celebration_rounded,
                    color: Colors.green,
                    buttonText: "Genial",
                  );
                },
                child: const Text('Pagar'),
              ),
            ],
          );
        },
      );
    },
  );
}
