import 'package:flutter/material.dart';

class AppStyles {
  static ButtonStyle get buttonStyle => elevatedButtonStyle;
  // Uso de Color(0xAARRGGBB) para aplicar opacidad más directamente
  static final BoxDecoration containerDecoration = BoxDecoration(
    color: const Color(0xD9FFFFFF), // Opacidad 0.85 equivalente a .withOpacity(0.8)
    borderRadius: BorderRadius.circular(20.0),
    boxShadow: const [
      BoxShadow(
        color: Colors.black26,
        blurRadius: 10.0,
        spreadRadius: 2.0,
        offset: Offset(0, 4),
      ),
    ],
  );

  static const TextStyle titleTextStyle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.5, // Un poco de espacio entre letras
  );

// hola bebes como estan 

  static InputDecoration textFieldDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
      border: const OutlineInputBorder(),
      filled: true,
      fillColor: const Color(0xFFFFFFFF), // Fondo blanco sólido
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: const Color.fromARGB(255, 0, 0, 0), width: 2.0),
      ),
    );
  }

  static ButtonStyle elevatedButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.blue,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
  );
}

