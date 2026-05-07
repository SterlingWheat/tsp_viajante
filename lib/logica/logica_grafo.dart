import 'dart:math';
import 'package:flutter/material.dart';
import 'package:tsp_viajante2/modelos/modelo_nodo.dart';
import 'package:tsp_viajante2/modelos/modelo_arista.dart';
import 'package:tsp_viajante2/logica/matematicas.dart';

// Clase que centraliza la lógica del grafo
class LogicaGrafo { 
  List<ModeloNodo> vNodo = []; //Guarda los nodos del grafo
  List<ModeloArista> vArista = []; //Guarda las aristas del grafo, con sus pesos y curvaturas
  int contadorNodos = 1; //Contador para asignar nombres automáticos a los nodos

  // Nodo definido por el usuario como punto de inicio del TSP
  ModeloNodo? nodoInicio; //Puede ser null si no se ha definido ningún nodo de inicio para el TSP

  //================BÚSQUEDA================
  // Retorna el índice del nodo en la posición (x, y), o -1 si no hay ninguno
  int buscaNodo(double x, double y) { //detecna si se tocó un nodo, devuelve su índice o -1 si no se tocó ninguno
    for (int i = 0; i < vNodo.length; i++) { //Recorre la lista de nodos
      double dist = sqrt(pow(x - vNodo[i].x, 2) + pow(y - vNodo[i].y, 2)); //Calcula la distancia entre el punto tocado y el centro del nodo
      if (dist <= vNodo[i].radio) return i; //Si la distancia es menor o igual al radio del nodo, se considera que se tocó ese nodo
    }
    return -1;
  }

  // Retorna el índice de la arista más cercana al punto (x, y), o -1
  int buscaArista(double x, double y) { //Detecta si hiciste clic cerca de una curva
    for (int i = 0; i < vArista.length; i++) { //Recorre la lista de aristas
      Offset p1 = Offset(vArista[i].origen.x, vArista[i].origen.y); //Convierte el nodo origen a un Offset para cálculos
      Offset p2 = Offset(vArista[i].destino.x, vArista[i].destino.y); //Convierte el nodo destino a un Offset para cálculos
      Offset c  = Matematicas.calcularPuntoControl(p1, p2, vArista[i].curvatura); //Calcula el punto de control

      double minDist = double.infinity;
      // Muestreamos la curva en 20 puntos para detectar proximidad
      for (double t = 0.0; t <= 1.0; t += 0.05) { //Está “muestreando” la curva en 20 puntos
        Offset pt   = Matematicas.obtenerPuntoEnCurva(p1, p2, c, t);
        double dist = sqrt(pow(x - pt.dx, 2) + pow(y - pt.dy, 2));//Calcula la distancia entre el punto tocado y el punto en la curva
        if (dist < minDist) minDist = dist; //Guarda la distancia mínima encontrada
      }
      if (minDist <= 20) return i; //Si la distancia minima en menor a 20px entonces toco la arista
    }
    return -1;
  }

  // --- Verificación ---
  // Verifica si ya existe una arista entre dos nodos (sin importar dirección)
  bool existeArista(ModeloNodo a, ModeloNodo b) { //Pasamos el nodo origen y destino
    return vArista.any((ar) => //Busca si existe alguna arista en la lista de aristas que conecte a y b sin importar el orden
        (ar.origen == a && ar.destino == b) ||
        (ar.origen == b && ar.destino == a));
  }

  // --- Modificación ---

  // Agrega un nodo nuevo en la posición dada
  void agregarNodo(String nombre, double x, double y, Color color) { //Pasamos todos los valores para crear el nodo
    String nombreFinal = nombre.trim().isEmpty ? 'Nodo $contadorNodos' : nombre.trim(); //Si el nombre esta vacio, se asigna un nombre automaticamente
    vNodo.add(ModeloNodo(nombreFinal, x, y, 28, color)); //Añadimos el nuevo nodo a la lista de nodos
    contadorNodos++; //Incrementamos el contador para el siguiente nodo
  }

  // Agrega una arista con peso positivo entre dos nodos
  // Retorna false si ya existe la arista o el peso no es positivo
  bool agregarArista(ModeloNodo origen, ModeloNodo destino, double peso) { //Pasamos el nodo origen, destino y el peso para crear la arista
    if (existeArista(origen, destino)) return false; //Verificamos que no exista la conexion entres los dos nodos
    if (peso <= 0) return false; //Veficamos que no haya pesos negativos o cero
    vArista.add(ModeloArista(origen, destino, peso)); //Añadimos la nueva arista a la lista de aristas
    return true;
  }

  // Establece el nodo de inicio del TSP
  void definirNodoInicio(ModeloNodo nodo) { //Pasamos el nodo que se desea establecer como inicio del TSP
    nodoInicio = (nodoInicio == nodo) ? null : nodo; //Si el nodo ya es el inicio, lo deseleccionamos (null), de lo contrario lo establecemos como inicio
  }

  // Elimina el nodo en el índice dado y todas sus aristas conectadas
  void eliminarNodo(int idx) { //elimina el nodo en la pocicion dada por idx
    ModeloNodo nodo = vNodo[idx]; //toma el nodo de la lista
    if (nodoInicio == nodo) nodoInicio = null; // limpia inicio si se borra ese nodo
    vArista.removeWhere((ar) => ar.origen == nodo || ar.destino == nodo); //Remueva todas las aristas que esten conectadas al nodo
    vNodo.removeAt(idx); //Remueve el nodo de la lista de nodos
  }

  // Elimina la arista en el índice dado
  void eliminarArista(int idx) { //Pasamos la arista que se desea eliminar por su índice
    vArista.removeAt(idx); //Remueve la arista de la lista de aristas usando su índice
  }

  // Resetea los colores y grosores de todas las aristas a su estado normal
  void resetearColorAristas() {
    for (var ar in vArista) { //Recorre todas las aristas
      ar.color = Colors.black54; //resetea el color
      ar.grosor = 3.0; //resetea el grosor
    }
  }

  // Resalta las aristas que forman la ruta del TSP en color verde (ciclo cerrado)
  void resaltarRutaTSP(List<ModeloNodo> ruta) { //Resalta la ruta del TSP
    resetearColorAristas(); //Eviata que rutas anteriores queden resaltadas
    // ruta ya incluye el nodo de inicio al final para cerrar el ciclo
    for (int i = 0; i < ruta.length - 1; i++) { //Recorre la ruta del TSP, pero no incluye el ultimo nodo porque se cierra con el inicio
      ModeloNodo o = ruta[i]; //Toma el nodo origen de la transición actual
      ModeloNodo d = ruta[i + 1]; //Toma el nodo destino de la transición actual
      int idx = vArista.indexWhere((ar) => //Busca en vArista la arista que conecta los nodos o y d y devuelve su índice
          (ar.origen == o && ar.destino == d) ||
          (ar.origen == d && ar.destino == o));
      if (idx >= 0) { //Si se encuentra la arista, la resaltamos
        vArista[idx].color  = Colors.black; //resetea el color
        vArista[idx].grosor = 6.0;
      }
    }
  }

  // --- Validación de Grafo Completo ---
  // Verifica si TODOS los nodos están conectados directamente con TODOS los demás
  bool esGrafoCompleto() {
    int n = vNodo.length;
    if (n < 2) return true; // Con 0 o 1 nodo no hay conexiones que hacer

    // Fórmula matemática para saber cuántas aristas requiere un grafo completo: n * (n - 1) / 2
    int aristasNecesarias = (n * (n - 1)) ~/ 2;

    // Si la cantidad de aristas dibujadas es igual a las necesarias, es válido
    return vArista.length == aristasNecesarias;
  }
}
