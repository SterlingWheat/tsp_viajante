import 'dart:math';
import 'package:flutter/material.dart';

// Utilidades matemáticas para curvas de Bézier cuadráticas
class Matematicas {
  // Calcula el punto de control para una curva cuadrática de Bézier
  // La curvatura desplaza el punto de control perpendicularmente a la línea
  static Offset calcularPuntoControl(Offset p1, Offset p2, double curvatura) {
    double dx   = p2.dx - p1.dx;
    double dy   = p2.dy - p1.dy;
    double midX = (p1.dx + p2.dx) / 2;
    double midY = (p1.dy + p2.dy) / 2;

    double longitud = sqrt(dx * dx + dy * dy);
    if (longitud == 0) return Offset(midX, midY);

    // Vector perpendicular normalizado
    double px = -dy / longitud;
    double py =  dx / longitud;

    return Offset(midX + px * curvatura, midY + py * curvatura);
  }

  // Obtiene un punto en la curva cuadrática de Bézier dado t ∈ [0, 1]
  // Fórmula: B(t) = (1-t)²·P1 + 2(1-t)t·C + t²·P2
  static Offset obtenerPuntoEnCurva(Offset p1, Offset p2, Offset c, double t) {
    double x = pow(1 - t, 2) * p1.dx + 2 * (1 - t) * t * c.dx + pow(t, 2) * p2.dx;
    double y = pow(1 - t, 2) * p1.dy + 2 * (1 - t) * t * c.dy + pow(t, 2) * p2.dy;
    return Offset(x, y);
  }
}
