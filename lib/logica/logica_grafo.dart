import 'dart:math';
import 'package:flutter/material.dart';
import 'package:tsp_viajante2/modelos/modelo_nodo.dart';
import 'package:tsp_viajante2/modelos/modelo_arista.dart';
import 'package:tsp_viajante2/logica/matematicas.dart';

// Clase que centraliza la lógica del grafo
class LogicaGrafo {
  List<ModeloNodo> vNodo = [];
  List<ModeloArista> vArista = [];
  int contadorNodos = 1;

  // Nodo definido por el usuario como punto de inicio del TSP
  ModeloNodo? nodoInicio;

  // --- Búsqueda ---

  // Retorna el índice del nodo en la posición (x, y), o -1 si no hay ninguno
  int buscaNodo(double x, double y) {
    for (int i = 0; i < vNodo.length; i++) {
      double dist = sqrt(pow(x - vNodo[i].x, 2) + pow(y - vNodo[i].y, 2));
      if (dist <= vNodo[i].radio) return i;
    }
    return -1;
  }

  // Retorna el índice de la arista más cercana al punto (x, y), o -1
  int buscaArista(double x, double y) {
    for (int i = 0; i < vArista.length; i++) {
      Offset p1 = Offset(vArista[i].origen.x, vArista[i].origen.y);
      Offset p2 = Offset(vArista[i].destino.x, vArista[i].destino.y);
      Offset c  = Matematicas.calcularPuntoControl(p1, p2, vArista[i].curvatura);

      double minDist = double.infinity;
      // Muestreamos la curva en 20 puntos para detectar proximidad
      for (double t = 0.0; t <= 1.0; t += 0.05) {
        Offset pt   = Matematicas.obtenerPuntoEnCurva(p1, p2, c, t);
        double dist = sqrt(pow(x - pt.dx, 2) + pow(y - pt.dy, 2));
        if (dist < minDist) minDist = dist;
      }
      if (minDist <= 20) return i;
    }
    return -1;
  }

  // --- Verificación ---

  // Verifica si ya existe una arista entre dos nodos (sin importar dirección)
  bool existeArista(ModeloNodo a, ModeloNodo b) {
    return vArista.any((ar) =>
        (ar.origen == a && ar.destino == b) ||
        (ar.origen == b && ar.destino == a));
  }

  // --- Modificación ---

  // Agrega un nodo nuevo en la posición dada
  void agregarNodo(String nombre, double x, double y, Color color) {
    String nombreFinal = nombre.trim().isEmpty ? 'Nodo $contadorNodos' : nombre.trim();
    vNodo.add(ModeloNodo(nombreFinal, x, y, 28, color));
    contadorNodos++;
  }

  // Agrega una arista con peso positivo entre dos nodos
  // Retorna false si ya existe la arista o el peso no es positivo
  bool agregarArista(ModeloNodo origen, ModeloNodo destino, int peso) {
    if (existeArista(origen, destino)) return false;
    if (peso <= 0) return false;
    vArista.add(ModeloArista(origen, destino, peso));
    return true;
  }

  // Establece el nodo de inicio del TSP (toggle: tocarlo de nuevo lo deselecciona)
  void definirNodoInicio(ModeloNodo nodo) {
    nodoInicio = (nodoInicio == nodo) ? null : nodo;
  }

  // Elimina el nodo en el índice dado y todas sus aristas conectadas
  void eliminarNodo(int idx) {
    ModeloNodo nodo = vNodo[idx];
    if (nodoInicio == nodo) nodoInicio = null; // limpia inicio si se borra ese nodo
    vArista.removeWhere((ar) => ar.origen == nodo || ar.destino == nodo);
    vNodo.removeAt(idx);
  }

  // Elimina la arista en el índice dado
  void eliminarArista(int idx) {
    vArista.removeAt(idx);
  }

  // Resetea los colores y grosores de todas las aristas a su estado normal
  void resetearColorAristas() {
    for (var ar in vArista) {
      ar.color = Colors.black54;
      ar.grosor = 3.0;
    }
  }

  // Resalta las aristas que forman la ruta del TSP en color verde (ciclo cerrado)
  void resaltarRutaTSP(List<ModeloNodo> ruta) {
    resetearColorAristas();
    // ruta ya incluye el nodo de inicio al final para cerrar el ciclo
    for (int i = 0; i < ruta.length - 1; i++) {
      ModeloNodo o = ruta[i];
      ModeloNodo d = ruta[i + 1];
      int idx = vArista.indexWhere((ar) =>
          (ar.origen == o && ar.destino == d) ||
          (ar.origen == d && ar.destino == o));
      if (idx >= 0) {
        vArista[idx].color  = Colors.greenAccent.shade700;
        vArista[idx].grosor = 6.0;
      }
    }
  }
}
