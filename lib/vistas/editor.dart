import 'dart:math';
import 'package:flutter/material.dart';
import 'package:tsp_viajante2/logica/logica_grafo.dart';
import 'package:tsp_viajante2/logica/matematicas.dart';
import 'package:tsp_viajante2/logica/tsp_genetico.dart';
import 'package:tsp_viajante2/modelos/modelo_nodo.dart';
import 'package:tsp_viajante2/modelos/modelo_arista.dart';
import 'package:tsp_viajante2/widgets/boton_modo.dart';
import 'package:tsp_viajante2/widgets/dibuja_grafo.dart';
import 'package:tsp_viajante2/widgets/menu_lateral.dart';

// ─── CONSTANTES DE MODO ───────────────────────────────────────
//Id de los botones de modo
const int MODO_NINGUNO   = -1; // Sin modo activo (estado por defecto)
const int MODO_AGREGAR   = 1; 
const int MODO_EDITAR    = 2; 
const int MODO_ELIMINAR  = 3;
const int MODO_CONECTAR  = 4;
const int MODO_MOVER     = 5;
const int MODO_CURVA     = 6;
const int MODO_INICIO    = 7; // Define el nodo de inicio del TSP

// Colores disponibles para los nodos
const Map<String, Color> coloresNodo = {//Define una estructura de clave-valor donde la clave es el nombre del color y el valor es el objeto Color
  'Rojo':    Colors.red,
  'Naranja': Colors.orange,
  'Verde':   Colors.green,
  'Amarillo':Colors.amber,
  'Azul':    Colors.blue,
  'Morado':  Colors.purple,
  //'Cyan':    Colors.cyan,
};

// Editor principal del grafo
class Editor extends StatefulWidget {
  const Editor({super.key});

  @override
  State<Editor> createState() => _EditorState();
}

class _EditorState extends State<Editor> with TickerProviderStateMixin {
  // ── Estado del editor ──
  int modo = MODO_NINGUNO; //modo ninguno activo al iniciar
  final LogicaGrafo grafo = LogicaGrafo(); // Instancia de la lógica del grafo
  int posPub       = -1;  // indice del nodo que se está moviendo
  int posAristaPub = -1;  // indice de la arista que se está curvando
  ModeloNodo? nodoOrigenConexion; // Primer nodo seleccionado para conectar

  // ── Estado de la animación ──
  AnimationController? _animCtrl; // Controlador de la animación del viajante
  List<ModeloNodo> _rutaTSP   = []; // Ruta optima encontrada por el AG 
  Offset?          _posBola; // Posición actual de la bola viajante en la animacion
  List<Offset>     _trazoRuta = []; // Puntos por donde ha pasado la bola para pintar el trazo
  bool _animacionLista = false; //Indica si la animacion esta corriendo
  String _textoRuta    = ''; //Texto que muestra la ruta optima encontrada
  double _costoTotal   = 0; // Costo total de la ruta optima encontrada

  @override
  void dispose() {
    _animCtrl?.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  //  BUILD PRINCIPAL
  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editor de Grafos'), //Titulo de la app
        backgroundColor: Colors.deepPurple.shade700,
        foregroundColor: Colors.white,
        actions: [ // Lista de widgets en la barra superior derecha
          // Botón TSP en la esquina superior derecha 
          // Se desactiva mientras la animación está corriendo
          Padding(
            padding: const EdgeInsets.only(right: 8),//Separa el botón del borde derecho
            child: Tooltip( //Muestra un mensaje al mantener presionado el botón
              message: 'Resolver TSP con AG',
              child: ElevatedButton.icon(
                onPressed: _animacionLista ? null : _resolverTSP,//Al presionar el botón se llama a la función _resolverTSP, pero solo si no hay una animación corriendo
                icon: const Text('🧬', style: TextStyle(fontSize: 18)), //icono del boton
                label: const Text('Resolver', style: TextStyle(fontWeight: FontWeight.bold)), //texto del boton
                style: ElevatedButton.styleFrom( //Estilo del botón
                  backgroundColor: _animacionLista //Si la animacion esta corriendo
                      ? Colors.grey.shade500
                      : Colors.amber.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), //Bordes redondeados
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: const MenuLateral(),
      body: Column(
        children: [
          // ── Canvas del grafo ──
          Expanded( //El canvas ocupa todo el espacio disponible
            child: Stack(
              children: [
                // Fondo gris claro
                Container(color: Colors.grey.shade100),//Fondo del canvas

                // CustomPainter: dibuja nodos, aristas, trazo y bola
                CustomPaint(
                  painter: DibujaGrafo(
                    grafo.vNodo, grafo.vArista, _posBola, _trazoRuta, grafo.nodoInicio),
                  child: Container(),
                ),

                // GestureDetector para interacción con el canvas
                // Se ignoran todos los gestos mientras la animación está activa
                if (!_animacionLista) //Si la animacion no esta corriendo 
                GestureDetector(
                  onPanDown:   _onPanDown, //Se habilita la funcion _onPanDown
                  onPanUpdate: _onPanUpdate, //Se habilita la funcion _onPanUpdate
                  onPanEnd:    _onPanEnd, //Se habilita la funcion _onPanEnd
                ),

                // Indicador del modo activo (arriba a la izquierda)
                if (modo != MODO_NINGUNO) //Si hay un modo activo
                  Positioned( //Posiciona el widget en la esquina superior izquierda
                    top: 8, left: 8, //Separa el indicador del borde superior e izquierdo
                    child: _chipModo(), //Muestra el modo activo en un chip
                  ),

                // Ruta óptima en texto (cuando la animación termina)
                if (_textoRuta.isNotEmpty) //Si hay una ruta para mostrar
                  Positioned(
                    bottom: 16, left: 12, right: 12, //Separa el texto del borde inferior y lateral
                    child: _tarjetaRuta(), //Muestra la ruta optima encontrada en una tarjeta
                  ),
              ],
            ),
          ),

          // ── Controles de reproducción ──
          if (_animacionLista) _barraReproduccion(), //Si la animacion esta corriendo, muestra la barra de reproduccion

          // ── Barra de herramientas inferior ──
          _barraHerramientas(), //Muestra la barra de herramientas para cambiar de modo
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  GESTOS DEL CANVAS
  // ─────────────────────────────────────────────────────────────

  void _onPanDown(DragDownDetails d) { //Se llama cuando el usuario toca el canvas
    double x = d.localPosition.dx; //Obtiene la posición x del toque
    double y = d.localPosition.dy; //Obtiene la posición y del toque

    if (modo == MODO_AGREGAR) { //Si el modo es agregar
      _dialogoCrearNodo(x, y); //Muestra un diálogo para crear un nuevo nodo en la posición tocada

    } else if (modo == MODO_ELIMINAR) { //Si el modo es eliminar
      int posN = grafo.buscaNodo(x, y); //Busca si se toco un nodo y obtiene su indice
      if (posN >= 0) { //Si se toco un nodo
        setState(() {
          grafo.eliminarNodo(posN); //Elimina el nodo de la logica del grafo
          _detenerAnimacion();//Detiene cualquier animacion en curso
        });
      } else {
        int posA = grafo.buscaArista(x, y);//Busca si se toco una arista y obtiene su indice
        if (posA >= 0) { //Si se toco una arista
          setState(() {
            grafo.eliminarArista(posA); //Elimina la arista de la logica del grafo
            _detenerAnimacion();//Detiene cualquier animacion en curso
          });
        }
      }

    } else if (modo == MODO_EDITAR) { //Si el modo es editar
      int posN = grafo.buscaNodo(x, y); //Busca si se toco un nodo y obtiene su indice
      if (posN >= 0) { //Si se toco un nodo
        _dialogoEditarNodo(grafo.vNodo[posN]); //Muestra un diálogo para editar el nodo tocado
      } else {
        int posA = grafo.buscaArista(x, y); //Busca si se toco una arista y obtiene su indice
        if (posA >= 0) {  //Si se toco una arista
          _dialogoEditarArista(grafo.vArista[posA]); //Muestra un diálogo para editar la arista tocada
        }
      }

    } else if (modo == MODO_MOVER) { //Si el modo es mover
      int posN = grafo.buscaNodo(x, y); //Busca si se toco un nodo y obtiene su indice
      if (posN >= 0) setState(() => posPub = posN); //Si se toco un nodo, guarda su indice en posPub para moverlo en la función _onPanUpdate

    } else if (modo == MODO_CONECTAR) { //Si el modo es conectar
      int posN = grafo.buscaNodo(x, y); //Busca si se toco un nodo y obtiene su indice
      if (posN >= 0) { //Si se toco un nodo
        if (nodoOrigenConexion == null) { //Si no hay un nodo origen seleccionado, selecciona el nodo tocado como origen
          setState(() => nodoOrigenConexion = grafo.vNodo[posN]); //Guarda el nodo origen seleccionado para conectar
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Nodo origen seleccionado. Ahora toca el destino.'),//Manda un mensaje
            duration: Duration(seconds: 2),
          ));
        } else {
          if (nodoOrigenConexion != grafo.vNodo[posN]) { //Si es el segundo nodo muestra dialogo crear arista
            _dialogoCrearArista(nodoOrigenConexion!, grafo.vNodo[posN]);//Pasamos el nodo origen seleccionado y el nodo destino tocado para crear la arista
          }
          setState(() => nodoOrigenConexion = null); //Limpia la selección del nodo origen para la próxima conexión
        }
      }

    } else if (modo == MODO_CURVA) { //Si el modo es curva
      int posA = grafo.buscaArista(x, y); //Busca si se toco una arista y obtiene su indice
      if (posA >= 0) setState(() => posAristaPub = posA); //guarda el indice en PosAristaPub para curvarla en la función _onPanUpdate

    } else if (modo == MODO_INICIO) { //Si el modo es inicio
      int posN = grafo.buscaNodo(x, y); //Busca si se toco un nodo y obtiene su indice
      if (posN >= 0) { //Si se toco un nodo
        setState(() => grafo.definirNodoInicio(grafo.vNodo[posN])); //Define el nodo de inicio
        // Confirmar al usuario qué nodo quedó seleccionado
        String msg = grafo.nodoInicio != null //Si el nodo de inicio no es nulo
            ? '★ "${grafo.nodoInicio!.mensaje}" marcado como nodo de inicio' //Nodo de inicio seleccionado
            : 'Nodo de inicio eliminado'; //Mensaje si se deselecciona el nodo de inicio
        ScaffoldMessenger.of(context).showSnackBar(SnackBar( //Muestra el mensaje en un SnackBar
          content: Text(msg),
          backgroundColor: grafo.nodoInicio != null
              ? Colors.amber.shade700
              : Colors.grey.shade700,
          duration: const Duration(seconds: 2),
        ));
      }
    }
  }

  void _onPanUpdate(DragUpdateDetails d) { //Se llama cuando el usuario mueve el dedo por el canvas después de tocarlo
    double x = d.localPosition.dx;
    double y = d.localPosition.dy;

    setState(() {
      if (modo == MODO_MOVER && posPub >= 0) { //Si el modo es mover y se ha seleccionado un nodo para mover (posPub >= 0)
        grafo.vNodo[posPub].x = x; //Actualiza la posición x del nodo seleccionado al mover el dedo
        grafo.vNodo[posPub].y = y; //Actualiza la posición y del nodo seleccionado al mover el dedo
      } else if (modo == MODO_CURVA && posAristaPub >= 0) { //Si el modo es curva y se ha seleccionado una arista para curvar (posAristaPub >= 0)
        // Calcula curvatura según la distancia del dedo al centro de la arista
        ModeloArista ar = grafo.vArista[posAristaPub]; //Obtiene la arista seleccionada para curvar
        double midX = (ar.origen.x + ar.destino.x) / 2; //Calcula la posición x del punto medio entre el nodo origen y destino de la arista
        double midY = (ar.origen.y + ar.destino.y) / 2; //Calcula la posición y del punto medio entre el nodo origen y destino de la arista
        double dx   = x - midX; //Calcula la distancia horizontal entre el dedo y el punto medio de la arista
        double dy   = y - midY; //Calcula la distancia vertical entre el dedo y el punto medio de la arista
        double curv = sqrt(dx * dx + dy * dy); //Calcula la distancia total entre el dedo y el punto medio de la arista
        ar.curvatura = (dy < 0) ? -curv : curv; //Asigna la curvatura a la arista, si el dedo esta arriba del punto medio, la curvatura es negativa, si esta abajo es positiva
      }
    });
  }

  void _onPanEnd(DragEndDetails d) { //Se llama cuando el usuario levanta el dedo del canvas después de moverlo 
    setState(() {
      posPub       = -1; //Resetea posPub para indicar que ya no se esta moviendo ningún nodo
      posAristaPub = -1; //Resetea posAristaPub para indicar que ya no se esta curvando ninguna arista
    });
  }

  // ─────────────────────────────────────────────────────────────
  //  DIÁLOGOS
  // ─────────────────────────────────────────────────────────────

  // Diálogo para crear un nodo: nombre + color
  Future<void> _dialogoCrearNodo(double x, double y) async { //recibe la posicion donde se toco para crear el nodo ahi
    TextEditingController tecNombre = TextEditingController(); //Controlador para el campo de texto del nombre del nodo
    Color colorElegido = Colors.red; //Color por defecto en rojo

    await showDialog( //Muestra un diálogo para ingresar el nombre y seleccionar el color del nuevo nodo
      context: context,
      builder: (ctx) { //builder del diálogo, recibe un contexto para construir el widget del diálogo
        return StatefulBuilder( //Actualiza el estado del dialogo para reflejar la selección de color en tiempo real
          builder: (ctx2, setDialogState) {//builder del StatefulBuilder, recibe un contexto y una función para actualizar el estado del diálogo
            return AlertDialog( //Widget del diálogo
              title: const Text('Nuevo Nodo'), //Título del diálogo
              content: Column(
                mainAxisSize: MainAxisSize.min, //El contenido del diálogo se ajusta al tamaño mínimo necesario
                children: [
                  TextField(
                    controller: tecNombre, //Campo de texto para ingresar el nombre del nodo
                    decoration: const InputDecoration(
                      labelText: 'Nombre', //Nombre del campo de texto
                      hintText: 'Vacío = nombre automático', 
                      border: OutlineInputBorder(),//Dibuja un borde del campo de texto
                    ),
                  ),
                  const SizedBox(height: 16), //Separación entre el campo de texto y el selector de colores
                  const Align(
                    alignment: Alignment.centerLeft, //Alinea el texto a la izquierda
                    child: Text('Color del nodo:', style: TextStyle(fontWeight: FontWeight.w600)), //Texto
                  ),
                  const SizedBox(height: 8), //Separación entre el texto y el selector de colores
                  // Selector de colores
                  Wrap(
                    spacing: 8, //Espacio entre los círculos de colores
                    children: coloresNodo.entries.map((entry) { //Itera sobre los colores disponibles
                      bool seleccionado = colorElegido == entry.value; //Ver si se selecciono un color
                      return GestureDetector(
                        onTap: () => setDialogState(() => colorElegido = entry.value),  //Al tocar un color, actualiza el estado del diálogo para reflejar la selección
                        child: Tooltip(
                          message: entry.key,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 36, height: 36, //Círculo de color para seleccionar el color del nodo
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: entry.value, //Color del círculo según el color disponible
                              border: seleccionado
                                  ? Border.all(color: Colors.black, width: 3) //Si el color esta seleccionado, dibuja un borde
                                  : Border.all(color: Colors.transparent), //Si no esta seleccionado, el borde es transparente
                              boxShadow: seleccionado
                                  ? [BoxShadow(color: entry.value.withOpacity(0.5), blurRadius: 8)] //Agrega una sombra al círculo si esta seleccionado
                                  : [], //Si no esta seleccionado, no hay sombra
                            ),
                          ),
                        ),
                      );
                    }).toList(), //Convierte el iterable de colores en una lista de widgets para mostrar en el Wrap
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),//Botón para cancelar la creación del nodo, cierra el diálogo sin hacer cambios
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() {
                      grafo.agregarNodo(tecNombre.text, x, y, colorElegido); //Agrega el nuevo nodo a la el arreglo de nodos
                    });
                  },
                  child: const Text('Crear'), //Botón para crear el nodo y cierra el diálogo
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Diálogo para crear una arista: solo ingresa el peso (debe ser > 0)
  Future<void> _dialogoCrearArista(ModeloNodo origen, ModeloNodo destino) async {//recibe ambos nodos para crear la arista entre ellos
    // Verificar si ya existe la arista
    if (grafo.existeArista(origen, destino)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Ya existe una arista entre ${origen.mensaje} y ${destino.mensaje}'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    TextEditingController tecPeso = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Arista: ${origen.mensaje} → ${destino.mensaje}'), //remarca el nodo origen y destino
          content: TextField(
            controller: tecPeso,
            keyboardType: TextInputType.number,//Solo acepta números para el peso
            decoration: const InputDecoration(
              labelText: 'Peso (número positivo)',//Nombre del campo de texto
              hintText: 'Ej: 10',
              border: OutlineInputBorder(),//Dibuja un borde del campo de texto
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')), //Botón para cancelar la creación de la arista, cierra el diálogo sin hacer cambios
            ElevatedButton(
              onPressed: () {
                double peso = double.tryParse(tecPeso.text.trim()) ?? 0; //Pone 0 por defecto o el valor ingresado
                if (peso <= 0) { //Si el peso es menor o igual a 0, muestra un mensaje de error y no crea la arista
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('El peso debe ser un número positivo')),
                  );
                  return;
                }
                Navigator.pop(ctx);
                setState(() {
                  grafo.agregarArista(origen, destino, peso); //Agrega la nueva arista a la el arreglo de aristas
                });
              },
              child: const Text('Conectar'), //Botón para crear la arista y cierra el diálogo
            ),
          ],
        );
      },
    );
  }

  // Diálogo para editar nombre y color de un nodo
  Future<void> _dialogoEditarNodo(ModeloNodo nodo) async { //recibe el nodo a editar
    TextEditingController tec = TextEditingController(text: nodo.mensaje); //Controla el campo d texto
    Color colorElegido = nodo.color; //Recupera el color actual

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx2, setDs) { //
          return AlertDialog(
            title: const Text('Editar Nodo'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: tec,//Campo de texto para editar el nombre
                  decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 14), //Separación entre el campo de texto y el selector de colores
                Wrap(
                  spacing: 8,
                  children: coloresNodo.entries.map((e) {
                    return GestureDetector(
                      onTap: () => setDs(() => colorElegido = e.value),
                      child: Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: e.value,
                          border: colorElegido == e.value 
                              ? Border.all(color: Colors.black, width: 3)
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() {
                    if (tec.text.trim().isNotEmpty) nodo.mensaje = tec.text.trim(); //Si el campo de texto no esta vacio
                    nodo.color = colorElegido;
                  });
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        });
      },
    );
  }

  // Diálogo para editar el peso de una arista (solo positivos)
  Future<void> _dialogoEditarArista(ModeloArista ar) async {
    TextEditingController tec = TextEditingController(text: ar.peso.toStringAsFixed(2));//Controla el capo de texto para editar
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Editar Arista: ${ar.origen.mensaje} ↔ ${ar.destino.mensaje}'),
          content: TextField(
            controller: tec,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Peso (positivo)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                double peso = double.tryParse(tec.text.trim()) ?? ar.peso;//Si el valor ingresado no es un número válido, se mantiene el peso actual
                if (peso <= 0) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('El peso debe ser positivo')),
                  );
                  return;
                }
                Navigator.pop(ctx);
                setState(() => ar.peso = peso);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  ALGORITMO GENÉTICO Y ANIMACIÓN
  // ─────────────────────────────────────────────────────────────

  // Ejecuta el TSP con AG y arranca la animación
  void _resolverTSP() {
    // Validación: mínimo 2 nodos
    if (grafo.vNodo.length < 2) { //Si hay menos de 2 nodos, muestra un mensaje de advertencia y no ejecuta el algoritmo
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Necesitas al menos 2 nodos para calcular la ruta.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validación obligatoria: debe haber un nodo de inicio definido
    if (grafo.nodoInicio == null) {//Si no hay un nodo de inicio definido
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Debes marcar un nodo de inicio antes de resolver.\nUsa el botón ★ de la barra inferior.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    //--------------------------------------------
    if (!grafo.esGrafoCompleto()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '❌ No existe una ruta válida que conecte todos los nodos.\n'
            'Revisa que haya aristas suficientes para cerrar el ciclo.',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
      return; // Detiene la ejecución aquí mismo
    }
    //-----------------------------------------

    _detenerAnimacion(); //Detiene cualquier animación en curso antes de ejecutar el algoritmo

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('⚙️ Calculando ruta óptima...'), duration: Duration(seconds: 2)),
    );

    // Obtener el índice del nodo de inicio en la lista del grafo
    int indiceInicio = grafo.vNodo.indexOf(grafo.nodoInicio!);

    // Ejecutar el AG con el nodo de inicio fijo
    TSPGenetico tsp = TSPGenetico(
      grafo.vNodo,
      grafo.vArista,
      indiceInicio: indiceInicio,
    );
    List<ModeloNodo> mejorRuta = tsp.ejecutar();
    // mejorRuta ya incluye el nodo de inicio al final (ciclo cerrado)

    // Calcular el costo total real de la ruta
    double costo = tsp.calcularCostoRuta(mejorRuta);

    // Si el costo es infinito, el grafo no tiene ninguna ruta válida completa
    // (faltan aristas para poder cerrar el ciclo pasando por todos los nodos)
    if (costo == double.infinity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '❌ No existe una ruta válida que conecte todos los nodos.\n'
            'Revisa que haya aristas suficientes para cerrar el ciclo.',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() {
      _rutaTSP     = mejorRuta; //Guarda la ruta óptima encontrada para la animación
      _costoTotal  = costo; //Guarda el costo total de la ruta óptima encontrada para mostrarlo en la tarjeta
      grafo.resaltarRutaTSP(mejorRuta); // Resalta las aristas de la ruta óptima en el grafo
      _animacionLista = true;  //Indica que la animación está lista para comenzar
      _trazoRuta      = []; // Limpia el trazo de la ruta para empezar a dibujarlo desde cero
      _posBola        = null; // Reinicia la posición de la bola para que empiece desde el nodo de inicio

      // Texto de la ruta con ciclo cerrado visible
      List<String> nombres = mejorRuta.map((n) => n.mensaje).toList(); //Convierte los nodos a sus nombres
      _textoRuta = '🛣 ${nombres.join(' → ')}'; // Crea el texto de la ruta con los nombres de los nodos
    });

    _iniciarAnimacion(); //Inicia la animacion del viajante
  }

  // Inicia la animación del viajante recorriendo la ruta
  void _iniciarAnimacion() {
    if (_rutaTSP.length < 2) return; //Si la ruta tiene menos de 2 nodos, no se puede animar

    _animCtrl?.dispose();//Si ya hay un controlador de animación existente, lo desecha para crear uno nuevo

    int tramos = _rutaTSP.length - 1;//el numero de tramos es igual al numero de nodos -1
    _animCtrl = AnimationController( //Controlador de la animacion
      vsync: this,
      duration: Duration(milliseconds: tramos * 1000),//el numero de tramos por 1 segundo
    );

    // Animación progresiva: valor va de 0 a "tramos"
    Animation<double> anim = Tween<double>(begin: 0, end: tramos.toDouble()) //Crea una animacion que va de 0 al numero de tramas
        .animate(_animCtrl!); //Asocia la animacion al controlador

    anim.addListener(() { //Cada vez que la animacion actualice su valor, se ejecuta este listener
      setState(() {
        double val = anim.value;//Valor actual de la animacion, va de 0 a tramos
        int idx    = val.floor().clamp(0, tramos - 1); //Indice del tramo actual, se asegura de no salir del rango de la lista de nodos
        double t   = (val - idx).clamp(0.0, 1.0); //progreso dentro del tramo actual, va de 0 a 1

        ModeloNodo n1 = _rutaTSP[idx];//Nodo de origen del tramo actual
        ModeloNodo n2 = _rutaTSP[idx + 1 > tramos ? tramos : idx + 1];//Nodo de destino del tramo actual, se asegura de no salir del rango de la lista de nodos

        // Obtener curvatura real de la arista (si existe)
        double curv = 0; //Curvatura por defecto es 0
        int idxAr = grafo.vArista.indexWhere((a) => //Busca la arista que conecta n1 y n2, sin importar el orden
            (a.origen == n1 && a.destino == n2) ||
            (a.origen == n2 && a.destino == n1));
        if (idxAr >= 0) { //Si se encuentra la arista, obtiene su curvatura real
          // Si n1 es el origen de la arista, la curvatura es positiva, si n1 es el destino, la curvatura es negativa 
          curv = (grafo.vArista[idxAr].origen == n1) //
              ? grafo.vArista[idxAr].curvatura
              : -grafo.vArista[idxAr].curvatura;
        }

        Offset p1   = Offset(n1.x, n1.y); //Posición del nodo de origen del tramo actual
        Offset p2   = Offset(n2.x, n2.y); //Posición del nodo de destino del tramo actual
        Offset ctrl = Matematicas.calcularPuntoControl(p1, p2, curv); //Calcuña el punto de control para la curva

        // Posición actual de la bola
        _posBola = Matematicas.obtenerPuntoEnCurva(p1, p2, ctrl, t); //Calcula la posición de la bola en la curva según el progreso t dentro del tramo actual

        // agrega la posición actual de la bola al trazo de la ruta para dibujar el recorrido
        _trazoRuta.add(_posBola!);//
      });
    });

    _animCtrl!.forward(); //Inicia la animación
  }

  // Detiene y limpia la animación
  void _detenerAnimacion() {
    _animCtrl?.stop(); //Detiene la animación si está corriendo
    setState(() {
      // Limpia todo lo relacionado con la animación para volver al estado normal del editor
      _posBola        = null;
      _trazoRuta      = [];
      _animacionLista = false;
      _textoRuta      = '';
      _costoTotal     = 0;
      grafo.resetearColorAristas();
      _rutaTSP = [];
    });
  }

  // ─────────────────────────────────────────────────────────────
  //  WIDGETS INTERNOS
  // ─────────────────────────────────────────────────────────────

  // Chip que muestra el modo activo
  Widget _chipModo() {
    //Diccionario para mostrar el nombre del modo activo
    Map<int, String> nombres = {
      MODO_AGREGAR:  '➕ Añadir nodo',
      MODO_EDITAR:   '✏️ Editar',
      MODO_ELIMINAR: '❌ Eliminar',
      MODO_CONECTAR: '🔗 Conectar${nodoOrigenConexion != null ? " (toca destino)" : ""}',
      MODO_MOVER:    '✋ Mover',
      MODO_CURVA:    '〰️ Curva',
      MODO_INICIO:   '★ Marcar nodo de inicio',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), //Relleno interno del chip para hacerlo más grande y legible
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade700.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(nombres[modo] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13)),//Muestra el nombre del modo activo según el diccionario, si no se encuentra el modo, muestra una cadena vacía
    );
  }

  // Tarjeta que muestra la ruta óptima en texto y el costo total
  Widget _tarjetaRuta() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), //Relleno interno de la tarjeta para hacerla más grande y legible
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade800.withOpacity(0.92),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,//Alinea el texto a la izquierda dentro de la tarjeta
        mainAxisSize: MainAxisSize.min,//La tarjeta se ajusta al tamaño mínimo necesario para su contenido
        children: [
          Text(
            _textoRuta, //trae el texto de la ruta óptima encontrada para mostrarlo en la tarjeta
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
            maxLines: 3, //Limita el texto a un máximo de 3 líneas para evitar que la tarjeta se haga demasiado grande
            overflow: TextOverflow.ellipsis, //Si el texto es demasiado largo, muestra puntos suspensivos al final para indicar que hay más texto oculto
          ),
          const SizedBox(height: 4),
          Text(
            '💰 Costo total: ${_costoTotal.toStringAsFixed(2)}',
            style: TextStyle(
              color: Colors.amber.shade300,
              fontSize: 14,
              fontWeight: FontWeight.bold, //Texto el negrita
            ),
          ),
        ],
      ),
    );
  }

  // Barra con controles Play / Pausa / Reset
  Widget _barraReproduccion() {
    return Container(
      color: Colors.deepPurple.shade900,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4), //deja espacio alrededor del contenido dentro del widget
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Play / Continuar
          IconButton(
            tooltip: 'Play',
            onPressed: () {
              if (_animCtrl != null && !_animCtrl!.isAnimating) { 
                if (_animCtrl!.isCompleted) { //Si la animacion esta compelta
                  // Reiniciar trazo y reproducir de nuevo
                  setState(() => _trazoRuta = []);
                  _animCtrl!.forward(from: 0); //Que reproduzca desde el inicio
                } else {
                  _animCtrl!.forward();//Que reproduzca donde que quedo
                }
              }
            },
            icon: const Icon(Icons.play_arrow, color: Colors.white, size: 30),
          ),
          // Pausa
          IconButton(
            tooltip: 'Pausa',
            onPressed: () => _animCtrl?.stop(), //Pausa la animacion
            icon: const Icon(Icons.pause, color: Colors.white, size: 30),
          ),
          // Reset
          IconButton(
            tooltip: 'Reiniciar animación',
            onPressed: () {
              setState(() => _trazoRuta = []);
              _animCtrl?.stop(); //Pausa la animacion
              _animCtrl?.forward(from: 0); //reinicia la animacion
            },
            icon: const Icon(Icons.replay, color: Colors.white, size: 30),
          ),
          // Cerrar animación
          IconButton(
            tooltip: 'Cerrar',
            onPressed: _detenerAnimacion, //detiene la animacion
            icon: const Icon(Icons.close, color: Colors.white70, size: 26),
          ),
        ],
      ),
    );
  }

  // Barra inferior de herramientas (modos)
  // Se bloquea completamente mientras _animacionLista == true
  Widget _barraHerramientas() {
    // Mientras la animación corre, los botones se muestran apagados e inactivos
    final bool bloqueada = _animacionLista;

    return SafeArea(
      top: false,
      child: Container(
        color: bloqueada
            ? Colors.deepPurple.shade900   // tono más oscuro = señal visual de bloqueo
            : Colors.deepPurple.shade800,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
        child: Opacity(
          opacity: bloqueada ? 0.35 : 1.0, // apaga visualmente todos los botones
          child: AbsorbPointer(
            absorbing: bloqueada,           // bloquea todos los toques
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  BotonModo(modoId: MODO_AGREGAR,  modoActual: modo, icono: Icons.add,          etiqueta: 'Añadir nodo',    alPresionar: () => _cambiarModo(MODO_AGREGAR)),
                  const SizedBox(width: 10),
                  BotonModo(modoId: MODO_EDITAR,   modoActual: modo, icono: Icons.edit,         etiqueta: 'Editar',         alPresionar: () => _cambiarModo(MODO_EDITAR)),
                  const SizedBox(width: 10),
                  BotonModo(modoId: MODO_ELIMINAR, modoActual: modo, icono: Icons.delete,       etiqueta: 'Eliminar',       alPresionar: () => _cambiarModo(MODO_ELIMINAR)),
                  const SizedBox(width: 10),
                  BotonModo(modoId: MODO_CONECTAR, modoActual: modo, icono: Icons.linear_scale, etiqueta: 'Conectar',       alPresionar: () => _cambiarModo(MODO_CONECTAR)),
                  const SizedBox(width: 10),
                  BotonModo(modoId: MODO_MOVER,    modoActual: modo, icono: Icons.open_with,    etiqueta: 'Mover nodo',     alPresionar: () => _cambiarModo(MODO_MOVER)),
                  const SizedBox(width: 10),
                  BotonModo(modoId: MODO_CURVA,    modoActual: modo, icono: Icons.gesture,      etiqueta: 'Ajustar curva',  alPresionar: () => _cambiarModo(MODO_CURVA)),
                  const SizedBox(width: 10),
                  BotonModo(modoId: MODO_INICIO,   modoActual: modo, icono: Icons.flag,         etiqueta: 'Nodo de inicio', alPresionar: () => _cambiarModo(MODO_INICIO)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _cambiarModo(int nuevoModo) {
    setState(() {
      modo = (modo == nuevoModo) ? MODO_NINGUNO : nuevoModo; //Si el modo actual es igual al seleccionado, que se desmarque si no, no
      nodoOrigenConexion = null;
    });
  }
}
