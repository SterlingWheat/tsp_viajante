import 'dart:math';
import 'package:tsp_viajante2/modelos/modelo_nodo.dart';
import 'package:tsp_viajante2/modelos/modelo_arista.dart';

// ─────────────────────────────────────────────────────────────
//  ALGORITMO GENÉTICO PARA EL PROBLEMA DEL VIAJANTE (TSP)
// ─────────────────────────────────────────────────────────────
//
//  El AG simula la evolución natural para encontrar el recorrido
//  más corto que visita todos los nodos usando las aristas del grafo.
//
//  Pasos del ciclo evolutivo:
//    1. Población inicial → rutas aleatorias con nodo inicio FIJO en pos 0
//    2. Evaluación       → costo total incluyendo regreso al inicio (ciclo)
//    3. Selección        → elegir los mejores individuos
//    4. Cruce (OX1)      → combina segmentos conservando nodo inicio en pos 0
//    5. Mutación         → intercambia dos posiciones (nunca la 0)
//    6. Elitismo         → conservar los dos mejores sin modificar
//    7. Repetir hasta completar las generaciones configuradas
//
class TSPGenetico {
  final List<ModeloNodo> nodos;
  final List<ModeloArista> aristas; // Aristas reales del grafo
  final int indiceInicio;           // Índice del nodo de inicio fijo
  final int tamanoPoblacion;
  final int generaciones;
  final double probMutacion;

  TSPGenetico(
    this.nodos,
    this.aristas, {
    this.indiceInicio    = 0,
    this.tamanoPoblacion = 120,
    this.generaciones    = 600,
    this.probMutacion    = 0.12,
  });

  // Retorna el peso real de la arista entre dos nodos, o null si no existe.
  // Nunca inventa costos: solo usa aristas del grafo real.
  double? _pesoAristaReal(ModeloNodo a, ModeloNodo b) {
    for (var ar in aristas) {
      if ((ar.origen == a && ar.destino == b) ||
          (ar.origen == b && ar.destino == a)) {
        return ar.peso.toDouble();
      }
    }
    return null; // arista inexistente en el grafo
  }

  // Calcula el fitness de una ruta (suma de pesos del ciclo completo).
  // Si CUALQUIER transición usa una arista que no existe → retorna infinity.
  // Esto garantiza que rutas inválidas nunca sean elegidas como solución.
  double _calcularFitness(List<int> ruta) {
    double total = 0;

    // Evaluar cada transición consecutiva de la ruta
    for (int i = 0; i < ruta.length - 1; i++) {
      double? peso = _pesoAristaReal(nodos[ruta[i]], nodos[ruta[i + 1]]);
      if (peso == null) return double.infinity; // arista inexistente → ruta inválida
      total += peso;
    }

    // Cerrar el ciclo: último nodo → nodo de inicio
    double? pesoCierre = _pesoAristaReal(nodos[ruta.last], nodos[ruta.first]);
    if (pesoCierre == null) return double.infinity; // cierre sin arista → inválida
    total += pesoCierre;

    return total;
  }

  // Genera la población inicial con rutas aleatorias.
  // El nodo de inicio SIEMPRE ocupa la posición 0 de cada individuo.
  List<List<int>> _generarPoblacion() {
    // Índices de todos los nodos excepto el de inicio
    List<int> resto = List.generate(nodos.length, (i) => i)
        .where((i) => i != indiceInicio)
        .toList();

    return List.generate(tamanoPoblacion, (_) {
      List<int> shuffled = List.from(resto)..shuffle();
      return [indiceInicio, ...shuffled]; // inicio siempre primero
    });
  }

  // Cruce de Orden OX1 adaptado: opera solo sobre las posiciones 1..n-1
  // para no desplazar el nodo de inicio de la posición 0.
  List<int> _cruzar(List<int> padre1, List<int> padre2) {
    int n = padre1.length;
    if (n <= 2) return List.from(padre1);

    // Rangos de cruce solo en el segmento [1, n-1]
    int ini = 1 + Random().nextInt(n - 1);
    int fin = 1 + Random().nextInt(n - 1);
    if (ini > fin) { int tmp = ini; ini = fin; fin = tmp; }

    List<int> hijo = List.filled(n, -1);
    hijo[0] = indiceInicio; // El inicio siempre es fijo

    // Copia el segmento del padre1
    for (int i = ini; i <= fin; i++) hijo[i] = padre1[i];

    // Llena los huecos con los genes del padre2 en orden (saltando pos 0)
    int posHijo   = (fin % (n - 1)) + 1; // siguiente pos dentro de [1, n-1]
    int posPadre2 = (fin % (n - 1)) + 1;

    while (hijo.contains(-1)) {
      if (padre2[posPadre2] != indiceInicio && !hijo.contains(padre2[posPadre2])) {
        hijo[posHijo] = padre2[posPadre2];
        posHijo = (posHijo % (n - 1)) + 1;
      }
      posPadre2 = (posPadre2 % (n - 1)) + 1;
    }
    return hijo;
  }

  // Mutación por intercambio: swapea dos posiciones al azar (nunca la 0)
  void _mutar(List<int> individuo) {
    if (individuo.length <= 2) return;
    if (Random().nextDouble() < probMutacion) {
      // Generamos índices en [1, length-1] para no tocar la posición 0
      int i = 1 + Random().nextInt(individuo.length - 1);
      int j = 1 + Random().nextInt(individuo.length - 1);
      int tmp        = individuo[i];
      individuo[i]   = individuo[j];
      individuo[j]   = tmp;
    }
  }

  // Ejecuta el algoritmo y retorna la mejor ruta como lista de nodos.
  // La lista retornada INCLUYE el nodo de inicio al final para cerrar el ciclo.
  List<ModeloNodo> ejecutar() {
    if (nodos.length < 2) return nodos;

    List<List<int>> poblacion    = _generarPoblacion();
    List<int> mejorRutaGlobal    = List.from(poblacion.first);
    double    mejorFitnessGlobal = _calcularFitness(mejorRutaGlobal);

    for (int gen = 0; gen < generaciones; gen++) {
      // Ordenar de menor a mayor costo (mejor = menor)
      poblacion.sort((a, b) => _calcularFitness(a).compareTo(_calcularFitness(b)));

      // Actualizar el mejor global
      double fitnessActual = _calcularFitness(poblacion.first);
      if (fitnessActual < mejorFitnessGlobal) {
        mejorFitnessGlobal = fitnessActual;
        mejorRutaGlobal    = List.from(poblacion.first);
      }

      // Elitismo: los 2 mejores pasan sin cambios
      List<List<int>> nuevaPoblacion = [poblacion[0], poblacion[1]];

      // Llena el resto con cruces y mutaciones de los mejores 50%
      int mitad = tamanoPoblacion ~/ 2;
      while (nuevaPoblacion.length < tamanoPoblacion) {
        List<int> padre1 = poblacion[Random().nextInt(mitad)];
        List<int> padre2 = poblacion[Random().nextInt(mitad)];
        List<int> hijo   = _cruzar(padre1, padre2);
        _mutar(hijo);
        nuevaPoblacion.add(hijo);
      }
      poblacion = nuevaPoblacion;
    }

    // Convertir índices en nodos y cerrar el ciclo añadiendo el inicio al final
    List<ModeloNodo> rutaNodos = mejorRutaGlobal.map((i) => nodos[i]).toList();
    rutaNodos.add(nodos[indiceInicio]); // cierra el ciclo
    return rutaNodos;
  }

  // Calcula el costo real de la ruta para mostrarlo en la UI.
  // Usa exclusivamente los pesos de aristas existentes.
  // Devuelve double.infinity si algún tramo no tiene arista (ruta inválida).
  double calcularCostoRuta(List<ModeloNodo> ruta) {
    double total = 0;
    for (int i = 0; i < ruta.length - 1; i++) {
      double? peso = _pesoAristaReal(ruta[i], ruta[i + 1]);
      if (peso == null) return double.infinity;
      total += peso;
    }
    return total;
  }
}
