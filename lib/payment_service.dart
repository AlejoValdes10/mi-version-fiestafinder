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

  final parentContext = context;
  double price = 0.0;
  final esGratis = (event['esGratis'] == true);

  // 🔹 Intentar traer el nombre del usuario
  String nombreUsuario = "Usuario desconocido";
  try {
    final userDoc =
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .get();
    if (userDoc.exists && userDoc.data()!.containsKey('nombre')) {
      nombreUsuario = userDoc['nombre'];
    }
  } catch (_) {}

  // 🔹 Calcular precio
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

  // ✅ Evento gratis (solo 1 por persona)
  if (price == 0) {
    // Verificar si ya tiene reserva
    final existing =
        await FirebaseFirestore.instance
            .collection('reservas')
            .where('eventoId', isEqualTo: eventId)
            .where('userId', isEqualTo: user.uid)
            .get();

    if (existing.docs.isNotEmpty) {
      _showCustomDialog(
        parentContext,
        title: "Ya registrado",
        message: "Ya tienes una reserva para este evento.",
        icon: Icons.info,
        color: Colors.blue,
      );
      return;
    }

    await FirebaseFirestore.instance.collection('reservas').add({
      'eventoId': eventId,
      'userId': user.uid,
      'nombreUsuario': nombreUsuario,
      'estado': 'confirmado',
      'price': 0,
      'paymentMethod': 'Gratis',
      'cantidad': 1,
      'tipo': 'reserva', // 🔹 marcar como reserva
      'timestamp': FieldValue.serverTimestamp(),
    });

    _showCustomDialog(
      parentContext,
      title: "Registro exitoso 🎉",
      message: "Te has registrado correctamente a este evento (gratis).",
      icon: Icons.check_circle_rounded,
      color: Colors.green,
      buttonText: "Perfecto",
    );
    return;
  }

  // ✅ Evento de pago
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
  int cantidad = 1; // 🔹 Por defecto 1 entrada

  showDialog(
    context: parentContext,
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
                Text('Precio unitario: \$${price.toStringAsFixed(0)}'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text(
                      "Cantidad:",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 10),
                    DropdownButton<int>(
                      value: cantidad,
                      items: List.generate(
                        5,
                        (i) => DropdownMenuItem(
                          value: i + 1,
                          child: Text("${i + 1}"),
                        ),
                      ),
                      onChanged: (v) => setState(() => cantidad = v!),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Total: \$${(price * cantidad).toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
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

                  showDialog(
                    context: parentContext,
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
                                  "Procesando pago...",
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                  );

                  try {
                    await Future.delayed(const Duration(seconds: 2));

                    // 🔹 Guardar compra también en 'reservas'
                    await FirebaseFirestore.instance.collection('reservas').add(
                      {
                        'eventoId': eventId,
                        'userId': user.uid,
                        'nombreUsuario': nombreUsuario,
                        'estado': 'pago confirmado',
                        'price': price * cantidad,
                        'cantidad': cantidad,
                        'paymentMethod': selectedMethod,
                        'tipo': 'compra', // 🔹 marcar como compra
                        'timestamp': FieldValue.serverTimestamp(),
                      },
                    );

                    if (Navigator.of(
                      parentContext,
                      rootNavigator: true,
                    ).canPop()) {
                      Navigator.of(parentContext, rootNavigator: true).pop();
                    }

                    Future.microtask(() {
                      _showCustomDialog(
                        parentContext,
                        title: "Pago exitoso ✅",
                        message:
                            "Has comprado $cantidad entradas con $selectedMethod.\n¡Disfruta el evento!",
                        icon: Icons.celebration_rounded,
                        color: Colors.green,
                        buttonText: "Genial",
                      );
                    });
                  } catch (e) {
                    if (Navigator.of(
                      parentContext,
                      rootNavigator: true,
                    ).canPop()) {
                      Navigator.of(parentContext, rootNavigator: true).pop();
                    }

                    Future.microtask(() {
                      _showCustomDialog(
                        parentContext,
                        title: "Error ❌",
                        message: "Ocurrió un problema al procesar el pago:\n$e",
                        icon: Icons.error_rounded,
                        color: Colors.red,
                        buttonText: "Cerrar",
                      );
                    });
                  }
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
