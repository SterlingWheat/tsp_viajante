import 'package:flutter/material.dart';

// Modelo que representa un nodo del grafo
class ModeloNodo {
  String mensaje; // Nombre del nodo
  double x, y;   // Posición en el canvas
  double radio;  // Tamaño del círculo
  Color color;   // Color del nodo

  ModeloNodo(this.mensaje, this.x, this.y, this.radio, this.color);
}
