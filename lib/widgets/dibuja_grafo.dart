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
  final List<ModeloNodo> vNodo; // Lista de nodos a dibujar
  final List<ModeloArista> vArista; // Lista de aristas a dibujar
  final Offset? posBola;           // Posición actual de la bola
  final List<Offset> trazoRuta;    // Puntos de la ruta ya recorrida
  final ModeloNodo? nodoInicio;    // Nodo marcado como inicio del TSP

  DibujaGrafo(this.vNodo, this.vArista, this.posBola, this.trazoRuta, this.nodoInicio);

  @override
  void paint(Canvas canvas, Size size) { //Dibuja el grafo completo en el canvas
    _dibujarAristas(canvas);
    _dibujarTrazoRuta(canvas);
    _dibujarNodos(canvas);
    _dibujarBola(canvas);
  }

  // Dibuja todas las aristas con su curva de Bézier y el peso al centro
  void _dibujarAristas(Canvas canvas) {
    for (var ar in vArista) { //Pinta cada arista
      Paint pincel = Paint()
        ..color      = ar.color
        ..strokeWidth = ar.grosor
        ..style      = PaintingStyle.stroke //Pinta solo el contorno de la curva
        ..strokeCap  = StrokeCap.round; //Termina la curva con un borde redondeado

      Offset p1 = Offset(ar.origen.x, ar.origen.y); //Punto de inicio de la arista
      Offset p2 = Offset(ar.destino.x, ar.destino.y); //Punto de fin de la arista
      Offset c  = Matematicas.calcularPuntoControl(p1, p2, ar.curvatura); //Calcula el punto de control para la curva 

      Path path = Path();
      path.moveTo(p1.dx, p1.dy); //Mueve el cursor al punto de inicio
      path.quadraticBezierTo(c.dx, c.dy, p2.dx, p2.dy); //Dibuja la curva
      canvas.drawPath(path, pincel); //Pinta la curva en el canvas

      // Peso de la arista al 50% de la curva
      Offset mid = Matematicas.obtenerPuntoEnCurva(p1, p2, c, 0.5); //agarra la mitad de la arista
      _dibujarTexto(canvas, ar.peso.toStringAsFixed(2), mid, Colors.red.shade700, 15);//pone el peso de la arista en la mitad
    }
  }

  // Dibuja el trazo acumulado de la ruta del viajante (línea gruesa azul)
  void _dibujarTrazoRuta(Canvas canvas) {
    if (trazoRuta.length < 2) return; //Si no hay al menos 2 puntos, no se puede dibujar una línea
    Paint pincel = Paint()
      ..color      = const Color.fromARGB(255, 27, 184, 32) //Color para la ruta recorrida
      ..strokeWidth = 5.0 //Grosor de la linea del trazo
      ..style      = PaintingStyle.stroke //Pinta solo el contorno
      ..strokeCap  = StrokeCap.round //Termina la línea con bordes redondeados
      ..strokeJoin = StrokeJoin.round; //Une las líneas con bordes redondeados para un trazo más suave

    Path path = Path();
    path.moveTo(trazoRuta.first.dx, trazoRuta.first.dy); //Coloca el inicio en el primer nodo del trazo
    for (int i = 1; i < trazoRuta.length; i++) { //Dibuja líneas entre cada punto del trazo acumulado
      path.lineTo(trazoRuta[i].dx, trazoRuta[i].dy);
    }
    canvas.drawPath(path, pincel); //Dibuja en pantalla
  }

  // Dibuja los nodos como círculos con sombra y nombre centrado
  void _dibujarNodos(Canvas canvas) {
    for (var nodo in vNodo) { //itera en cada nodo del grafo
      // Sombra suave
      Paint sombra = Paint()
        ..color     = Colors.black26 
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4); //difumina los bordes de la figuta con intensidad de 4
      canvas.drawCircle(Offset(nodo.x + 2, nodo.y + 2), nodo.radio, sombra); //Dibuja una sombrea dezplazada 2px a la derecha

      // Relleno del nodo
      Paint relleno = Paint()
        ..color = nodo.color
        ..style = PaintingStyle.fill; //pinta el interior del nodo con su color asignado
      canvas.drawCircle(Offset(nodo.x, nodo.y), nodo.radio, relleno);

      // Aro dorado si es el nodo de inicio
      if (nodo == nodoInicio) { //Si el nodo actual es el nodo de inicio
        Paint aroDorado = Paint()
          ..color      = Colors.amber.shade400 //Color dorado
          ..style      = PaintingStyle.stroke //Solo el borde
          ..strokeWidth = 4.0;//Grosor del aro dorado
        canvas.drawCircle(Offset(nodo.x, nodo.y), nodo.radio + 5, aroDorado); //un radio 5px mayor al original
        // Etiqueta "★ Inicio" encima del nodo
        _dibujarTexto(
          canvas,
          '★ Inicio',
          Offset(nodo.x, nodo.y - nodo.radio - 14), //Posición justo encima del nodo
          Colors.amber.shade700,
          11,
          fondo: Colors.white,
        );
      }

      // Borde blanco del nodo
      Paint borde = Paint()
        ..color      = Colors.white
        ..style      = PaintingStyle.stroke
        ..strokeWidth = 2.5; //Grosor del borde blanco
      canvas.drawCircle(Offset(nodo.x, nodo.y), nodo.radio, borde);

      // Nombre centrado
      _dibujarTexto(canvas, nodo.mensaje, Offset(nodo.x, nodo.y), Colors.white, 13);
    }
  }

  // Dibuja la bola amarilla del viajante con borde naranja
  void _dibujarBola(Canvas canvas) {
    if (posBola == null) return; //Si no hay posición para la bola, no se dibuja nada

    // Sombra de la bola
    Paint sombra = Paint()
      ..color      = Colors.orange.withOpacity(0.4) //Con 40 de opacidad
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);//Que tenga bordes difusos
    canvas.drawCircle(posBola!, 14, sombra);//Dibuja la bola con radio 14

    // Relleno con gradiente radial
    Paint relleno = Paint()
      ..shader = RadialGradient( //Utilizar un degradado
        colors: [Colors.yellow.shade200, Colors.orange.shade600],
      ).createShader(Rect.fromCircle(center: posBola!, radius: 13)) //Define el area donde se rellenara la bola
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
    TextPainter tp = TextPainter( //Utiliza TextPainter para dibujar texto en el canvas
      text: TextSpan(
        text: texto, //Contenido del texto a dibujar
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.bold, //Texto en negrita
          backgroundColor: fondo ?? (color == Colors.white ? Colors.transparent : Colors.white70),
        ),
      ),
      textDirection: TextDirection.ltr, //Texto de izquierda a derecha
    );
    tp.layout(); //Calcula el tamaño del texto para poder centrarlo correctamente
    tp.paint(canvas, Offset(centro.dx - tp.width / 2, centro.dy - tp.height / 2)); //Dibuja el texto centrado en la posicion dada
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
