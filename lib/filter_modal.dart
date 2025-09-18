import 'package:flutter/material.dart';
import 'dart:ui';

class FilterModal {
  static void show({
    required BuildContext context,
    required String currentLocalidad,
    required String currentEntrada,
    required String currentTipo,
    required Function(String localidad, String entrada, String tipo) onApply,
  }) {
    // Variables temporales
    String tempLocalidad = currentLocalidad;
    String tempEntrada = currentEntrada;
    String tempTipo = currentTipo;

    // Opciones
    final localidades = [
      'Todos',
      'Norte',
      'Occidente',
      'Oriente',
      'Sur',
      'Noroccidente',
      'Nororiente',
      'Suroccidente',
      'Suroriente',
    ];

    final entradas = ["Todos", "Gratis", "De pago"]; // 👈 Orden corregido

    final tipos = [
      "Todos",
      "Gastrobar",
      "Discotecas",
      "Cultural",
      "Deportivo",
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                ),
                padding: EdgeInsets.fromLTRB(
                  25,
                  30,
                  25,
                  MediaQuery.of(context).viewInsets.bottom + 30,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Encabezado
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filtrar Eventos',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.black54),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Localidad
                    _buildModernFilterSection(
                      title: "Localidad",
                      options: localidades,
                      currentSelection: tempLocalidad,
                      onSelect: (value) {
                        setModalState(() {
                          tempLocalidad = value;
                        });
                      },
                    ),
                    const SizedBox(height: 25),

                    // Tipo de entrada
                    _buildModernFilterSection(
                      title: "Tipo de entrada",
                      options: entradas,
                      currentSelection: tempEntrada,
                      onSelect: (value) {
                        setModalState(() {
                          tempEntrada = value;
                        });
                      },
                    ),
                    const SizedBox(height: 25),

                    // Tipo de evento
                    _buildModernFilterSection(
                      title: "Tipo de Evento",
                      options: tipos,
                      currentSelection: tempTipo,
                      onSelect: (value) {
                        setModalState(() {
                          tempTipo = value;
                        });
                      },
                    ),
                    const SizedBox(height: 30),

                    // Botones
                    Row(
                      children: [
                        // Reset
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setModalState(() {
                                tempLocalidad = "Todos";
                                tempEntrada = "Todos";
                                tempTipo = "Todos";
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              side: const BorderSide(color: Colors.black),
                            ),
                            child: const Text(
                              'Reiniciar',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        // Aplicar
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              onApply(tempLocalidad, tempEntrada, tempTipo);
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Aplicar Filtros',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 🔹 Método auxiliar
  static Widget _buildModernFilterSection({
    required String title,
    required List<String> options,
    required String currentSelection,
    required Function(String) onSelect,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options[index];
              bool isSelected = currentSelection == option;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(
                    option,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) => onSelect(option),
                  selectedColor: Colors.black,
                  backgroundColor: Colors.grey[200],
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
