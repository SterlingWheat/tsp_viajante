import 'package:flutter/material.dart';
import 'package:tsp_viajante2/modelos/modelo_nodo.dart';
import 'package:tsp_viajante2/modelos/modelo_arista.dart';
import 'package:tsp_viajante2/logica/matematicas.dart';

// CustomPainter que dibuja todo el grafo:
//   • Aristas (curvas de Bézier con su peso)
//   • Nodos (círculos con nombre)
//   • Nodo de inicio destacado con aro dorado
//   • Ruta pintada progresivamente (trazo acumulado)
//   • Bola del viajante animada
class DibujaGrafo extends CustomPainter {
  final List<ModeloNodo> vNodo;
  final List<ModeloArista> vArista;
  final Offset? posBola;           // Posición actual de la bola
  final List<Offset> trazoRuta;    // Puntos de la ruta ya recorrida
  final ModeloNodo? nodoInicio;    // Nodo marcado como inicio del TSP

  DibujaGrafo(this.vNodo, this.vArista, this.posBola, this.trazoRuta, this.nodoInicio);

  @override
  void paint(Canvas canvas, Size size) {
    _dibujarAristas(canvas);
    _dibujarTrazoRuta(canvas);
    _dibujarNodos(canvas);
    _dibujarBola(canvas);
  }

  // Dibuja todas las aristas con su curva de Bézier y el peso al centro
  void _dibujarAristas(Canvas canvas) {
    for (var ar in vArista) {
      Paint pincel = Paint()
        ..color      = ar.color
        ..strokeWidth = ar.grosor
        ..style      = PaintingStyle.stroke
        ..strokeCap  = StrokeCap.round;

      Offset p1 = Offset(ar.origen.x, ar.origen.y);
      Offset p2 = Offset(ar.destino.x, ar.destino.y);
      Offset c  = Matematicas.calcularPuntoControl(p1, p2, ar.curvatura);

      Path path = Path();
      path.moveTo(p1.dx, p1.dy);
      path.quadraticBezierTo(c.dx, c.dy, p2.dx, p2.dy);
      canvas.drawPath(path, pincel);

      // Peso de la arista al 50% de la curva
      Offset mid = Matematicas.obtenerPuntoEnCurva(p1, p2, c, 0.5);
      _dibujarTexto(canvas, ar.peso.toString(), mid, Colors.red.shade700, 15);
    }
  }

  // Dibuja el trazo acumulado de la ruta del viajante (línea gruesa azul)
  void _dibujarTrazoRuta(Canvas canvas) {
    if (trazoRuta.length < 2) return;
    Paint pincel = Paint()
      ..color      = Colors.blue.shade700
      ..strokeWidth = 5.0
      ..style      = PaintingStyle.stroke
      ..strokeCap  = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    Path path = Path();
    path.moveTo(trazoRuta.first.dx, trazoRuta.first.dy);
    for (int i = 1; i < trazoRuta.length; i++) {
      path.lineTo(trazoRuta[i].dx, trazoRuta[i].dy);
    }
    canvas.drawPath(path, pincel);
  }

  // Dibuja los nodos como círculos con sombra y nombre centrado
  void _dibujarNodos(Canvas canvas) {
    for (var nodo in vNodo) {
      // Sombra suave
      Paint sombra = Paint()
        ..color     = Colors.black26
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(nodo.x + 2, nodo.y + 2), nodo.radio, sombra);

      // Relleno del nodo
      Paint relleno = Paint()
        ..color = nodo.color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(nodo.x, nodo.y), nodo.radio, relleno);

      // Aro dorado si es el nodo de inicio
      if (nodo == nodoInicio) {
        Paint aroDorado = Paint()
          ..color      = Colors.amber.shade400
          ..style      = PaintingStyle.stroke
          ..strokeWidth = 4.0;
        canvas.drawCircle(Offset(nodo.x, nodo.y), nodo.radio + 5, aroDorado);
        // Etiqueta "★ Inicio" encima del nodo
        _dibujarTexto(
          canvas,
          '★ Inicio',
          Offset(nodo.x, nodo.y - nodo.radio - 14),
          Colors.amber.shade700,
          11,
          fondo: Colors.white,
        );
      }

      // Borde blanco
      Paint borde = Paint()
        ..color      = Colors.white
        ..style      = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawCircle(Offset(nodo.x, nodo.y), nodo.radio, borde);

      // Nombre centrado
      _dibujarTexto(canvas, nodo.mensaje, Offset(nodo.x, nodo.y), Colors.white, 13);
    }
  }

  // Dibuja la bola amarilla del viajante con borde naranja
  void _dibujarBola(Canvas canvas) {
    if (posBola == null) return;

    // Sombra de la bola
    Paint sombra = Paint()
      ..color      = Colors.orange.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(posBola!, 14, sombra);

    // Relleno con gradiente radial
    Paint relleno = Paint()
      ..shader = RadialGradient(
        colors: [Colors.yellow.shade200, Colors.orange.shade600],
      ).createShader(Rect.fromCircle(center: posBola!, radius: 13))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(posBola!, 13, relleno);

    // Borde
    Paint borde = Paint()
      ..color      = Colors.deepOrange.shade900
      ..style      = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(posBola!, 13, borde);
  }

  // Helper: dibuja texto centrado en una posición
  void _dibujarTexto(Canvas canvas, String texto, Offset centro, Color color, double fontSize, {Color? fondo}) {
    TextPainter tp = TextPainter(
      text: TextSpan(
        text: texto,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          backgroundColor: fondo ?? (color == Colors.white ? Colors.transparent : Colors.white70),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(centro.dx - tp.width / 2, centro.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
