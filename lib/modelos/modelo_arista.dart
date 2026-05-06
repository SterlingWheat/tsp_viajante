import 'package:flutter/material.dart';
import 'package:tsp_viajante2/modelos/modelo_nodo.dart';

// Modelo que representa una arista (conexión) entre dos nodos
class ModeloArista {
  ModeloNodo origen;
  ModeloNodo destino;
  double peso;         // Peso positivo de la arista
  double curvatura; // Controla la curva de la arista (Bézier)

  // Propiedades visuales para pintar la ruta del TSP
  Color color;
  double grosor;

  ModeloArista(
    this.origen,
    this.destino,
    this.peso, {
    this.curvatura = 0.0,
    this.color = Colors.black54,
    this.grosor = 3.0,
  });
}
