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
  final List<ModeloNodo> nodos; //Ciudades o puntos a visitar
  final List<ModeloArista> aristas; // Aristas del grafo
  final int indiceInicio;           // Índice del nodo de inicio fijo
  final int tamanoPoblacion; //cuantas rutas aleatorias se evaluarán en cada generación
  final int generaciones; //Numero de ciclos evolutivos
  final double probMutacion; //probabilidad de que un individuo sufra mutación

  TSPGenetico(
    this.nodos,
    this.aristas, {
    this.indiceInicio    = 0, //Indice del nodo de inicio
    this.tamanoPoblacion = 120, //Tamaño de la población en cada generación
    this.generaciones    = 600, //Cuantas generaciones se ejecutará el algoritmo
    this.probMutacion    = 0.12, //Probabilidad de mutación por individuo (12% recomendado para TSP)
  });

  // Retorna el peso real de la arista entre dos nodos, o null si no existe.
  double? _pesoAristaReal(ModeloNodo a, ModeloNodo b) { //dedvuelve el peso de la arista o null si no existe
    for (var ar in aristas) { //Recorre la lista de aristas
      if ((ar.origen == a && ar.destino == b) || //Busca la arista que conecta a y b sin importar el orden
          (ar.origen == b && ar.destino == a)) {
        return ar.peso.toDouble(); //Retorna el peso de la arista como double, lo convierte a double
      }
    }
    return null; // arista inexistente en el grafo
  }

  // Calcula el fitness de una ruta (suma de pesos del ciclo completo).
  // Si CUALQUIER transición usa una arista que no existe → retorna infinity.
  // Esto garantiza que rutas inválidas nunca sean elegidas como solución.
  double _calcularFitness(List<int> ruta) { //Recibe la ruta y devuelve el costo total
    double total = 0; //variable acumuladora del costo total de la ruta

    // Evaluar cada transición consecutiva de la ruta
    for (int i = 0; i < ruta.length - 1; i++) { //Recorre la ruta de nodo en nodo
      double? peso = _pesoAristaReal(nodos[ruta[i]], nodos[ruta[i + 1]]); //busca el peso de la arista entre los nodos consecutivos
      if (peso == null) return double.infinity; // arista inexistente → ruta inválida
      total += peso;
    }

    // Cerrar el ciclo: último nodo → nodo de inicio
    double? pesoCierre = _pesoAristaReal(nodos[ruta.last], nodos[ruta.first]);//Calcula el costo de volver al inicio
    if (pesoCierre == null) return double.infinity; // cierre sin arista → inválida
    total += pesoCierre;

    return total; //retorna el total del ciclo completo de la ruta, incluyendo el regreso al inicio
  }

  // Genera la población inicial con rutas aleatorias.
  // El nodo de inicio SIEMPRE ocupa la posición 0 de cada individuo.
  List<List<int>> _generarPoblacion() { //Metodo para generar la poblacion inicial con rutas aleatorias
    // Índices de todos los nodos excepto el de inicio
    List<int> resto = List.generate(nodos.length, (i) => i) //Genera una lista de índices de nodos
        .where((i) => i != indiceInicio) //filtra para excluir el índice del nodo de inicio
        .toList();//Convierte el resultado a una lista

    return List.generate(tamanoPoblacion, (_) { //Crea una lista de rutas aleatorias con el tamaño de la población, con la funcion anonima (_)
      List<int> shuffled = List.from(resto)..shuffle(); //Crea una copia de la lista de índices de nodos excepto el inicio y la mezcla aleatoriamente
      return [indiceInicio, ...shuffled]; // inicio siempre primero, luego el shuffle de los demás nodos
    });
  }

  // Cruce de Orden OX1 adaptado: opera solo sobre las posiciones 1..n-1
  // para no desplazar el nodo de inicio de la posición 0.
  List<int> _cruzar(List<int> padre1, List<int> padre2) { //Recibe dos padres y devuelve un hijo resultante del cruce
    int n = padre1.length; // número de nodos en la ruta
    if (n <= 2) return List.from(padre1); // Si solo hay 2 nodos, el cruce no tiene sentido, retorna una copia del padre1

    //Elige 2 posiciones aleatorias entre [1, n-1], la posición 0 es fija para el nodo de inicio
    int ini = 1 + Random().nextInt(n - 1);
    int fin = 1 + Random().nextInt(n - 1);
    //asegura que ini < fin para definir un segmento válido
    if (ini > fin) { 
      int tmp = ini; 
      ini = fin; 
      fin = tmp; 
    }

    List<int> hijo = List.filled(n, -1); //Crea una lista de n elementos, todos inicializados en -1 para marcar posiciones vacias
    hijo[0] = indiceInicio; // El inicio siempre es fijo

    // Copia el segmento del padre1
    for (int i = ini; i <= fin; i++) {
      hijo[i] = padre1[i];
    }

    // Llena los huecos con los genes del padre2 en orden (saltando posicion 0)
    int posHijo   = (fin % (n - 1)) + 1; //Empieza desde la posicion siguiente al fin
    int posPadre2 = (fin % (n - 1)) + 1; //Empieza desde la misma posición en el padre2 para mantener el orden relativo

    while (hijo.contains(-1)) { // Mientras haya posiciones vacías en el hijo
      if (padre2[posPadre2] != indiceInicio && !hijo.contains(padre2[posPadre2])) { //si el gen del padre 2 no es el inicio y no está ya en el hijo
        hijo[posHijo] = padre2[posPadre2]; //Inserta el gen en el hijo
        posHijo = (posHijo % (n - 1)) + 1; //Avanza la posicion en el hijo, saltando la posición 0
      }
      posPadre2 = (posPadre2 % (n - 1)) + 1; //Avanza la posición en el padre2, saltando la posición 0
    }
    return hijo; //Retorna el hijo resultante del cruce
  }

  // Mutación por intercambio: swapea dos posiciones al azar (nunca la 0)
  void _mutar(List<int> individuo) { //Recibe una ruta
    if (individuo.length <= 2) return; // Si solo hay 2 nodos, la mutación no tiene sentido, retorna sin hacer nada
    if (Random().nextDouble() < probMutacion) { //Decide aleatoriamente si mutar o no según la probabilidad de mutación
      // Generamos índices en [1, length-1] para no tocar la posición 0
      int i = 1 + Random().nextInt(individuo.length - 1); //Genera una posicion aleatoria
      int j = 1 + Random().nextInt(individuo.length - 1); //Genera otra posicion aleatoria
      //intercambia los genes en las posiciones i y j
      int tmp        = individuo[i];
      individuo[i]   = individuo[j];
      individuo[j]   = tmp;
    }
  }

  // Ejecuta el algoritmo y retorna la mejor ruta como lista de nodos.
  // La lista retornada INCLUYE el nodo de inicio al final para cerrar el ciclo.
  List<ModeloNodo> ejecutar() { //Devuelve le mejor ruta encontrada como una lista de nodos
    if (nodos.length < 2) return nodos; //Si hay menos de 2 nodos, retorna la lista tal cual

    List<List<int>> poblacion    = _generarPoblacion(); //Crea muchas rutas aleatorias para la población inicial
    List<int> mejorRutaGlobal    = List.from(poblacion.first); //Guarda la primera ruta como referencia
    double    mejorFitnessGlobal = _calcularFitness(mejorRutaGlobal); //Calcula su costo

    for (int gen = 0; gen < generaciones; gen++) { //repite el ciclo evolutivo por el número de generaciones
      // Ordenar de menor a mayor costo (mejor = menor)
      poblacion.sort((a, b) => _calcularFitness(a).compareTo(_calcularFitness(b)));//Ordena de menor a mayor segun el costo

      // Actualizar el mejor global
      double fitnessActual = _calcularFitness(poblacion.first); //Toma el mejor individuo de la población actual y calcula su costo
      if (fitnessActual < mejorFitnessGlobal) { //Si el costo es menor que el global
        mejorFitnessGlobal = fitnessActual; //Actualiza el mejor costo global
        mejorRutaGlobal    = List.from(poblacion.first); //actualiza la mejor ruta global con una copia del mejor individuo actual
      }

      //los 2 mejores pasan sin cambios
      List<List<int>> nuevaPoblacion = [poblacion[0], poblacion[1]]; //Se toman las dos mejores rutas y se pasan sin modificaciones

      // Llena el resto con cruces y mutaciones de los mejores 50%
      int mitad = tamanoPoblacion ~/ 2; 
      while (nuevaPoblacion.length < tamanoPoblacion) { //Mientras no se alcance el tamaño de población deseado
        List<int> padre1 = poblacion[Random().nextInt(mitad)];//Se toma una ruta aleatoria del mejor 50%
        List<int> padre2 = poblacion[Random().nextInt(mitad)];//Se toma otra ruta aleatoria del mejor 50%
        List<int> hijo   = _cruzar(padre1, padre2); //Se cruza para generar un hijo
        _mutar(hijo); //Se muta el hijo con la probabilidad definida
        nuevaPoblacion.add(hijo); //Se agrega el hijo a la nueva población
      }
      poblacion = nuevaPoblacion;//Se reemplaza la población actual con la nueva población generada
    }

    // Convertir índices en nodos y cerrar el ciclo añadiendo el inicio al final
    List<ModeloNodo> rutaNodos = mejorRutaGlobal.map((i) => nodos[i]).toList(); //Convierte la mejor ruta global de índices a nodos
    rutaNodos.add(nodos[indiceInicio]); // cierra el ciclo
    return rutaNodos;
  }

  // Calcula el costo real de la ruta para mostrarlo en la UI.
  // Usa exclusivamente los pesos de aristas existentes.
  // Devuelve double.infinity si algún tramo no tiene arista (ruta inválida).
  double calcularCostoRuta(List<ModeloNodo> ruta) {
    double total = 0; //variable acumuladora del costo total de la ruta
    for (int i = 0; i < ruta.length - 1; i++) {
      double? peso = _pesoAristaReal(ruta[i], ruta[i + 1]); //Suma el peso entre nodos consecutivos
      if (peso == null) return double.infinity;
      total += peso;
    }
    return total;
  }
}
