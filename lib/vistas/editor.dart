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
const int MODO_NINGUNO   = -1;
const int MODO_AGREGAR   = 1;
const int MODO_EDITAR    = 2;
const int MODO_ELIMINAR  = 3;
const int MODO_CONECTAR  = 4;
const int MODO_MOVER     = 5;
const int MODO_CURVA     = 6;
const int MODO_INICIO    = 7; // Define el nodo de inicio del TSP

// Colores disponibles para los nodos
const Map<String, Color> coloresNodo = {
  'Rojo':    Colors.red,
  'Naranja': Colors.orange,
  'Verde':   Colors.green,
  'Amarillo':Colors.amber,
  'Azul':    Colors.blue,
  'Morado':  Colors.purple,
};

// Editor principal del grafo
class Editor extends StatefulWidget {
  const Editor({super.key});

  @override
  State<Editor> createState() => _EditorState();
}

class _EditorState extends State<Editor> with TickerProviderStateMixin {
  // ── Estado del editor ──
  int modo = MODO_NINGUNO;
  final LogicaGrafo grafo = LogicaGrafo();
  int posPub       = -1;  // Índice del nodo que se está moviendo
  int posAristaPub = -1;  // Índice de la arista que se está curvando
  ModeloNodo? nodoOrigenConexion; // Primer nodo seleccionado para conectar

  // ── Estado de la animación ──
  AnimationController? _animCtrl;
  List<ModeloNodo> _rutaTSP   = [];
  Offset?          _posBola;
  List<Offset>     _trazoRuta = [];
  bool _animacionLista = false;
  String _textoRuta    = '';
  double _costoTotal   = 0; // Costo total de la ruta óptima encontrada

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
        title: const Text('Editor de Grafos'),
        backgroundColor: Colors.deepPurple.shade700,
        foregroundColor: Colors.white,
        actions: [
          // Botón TSP en la esquina superior derecha (requisito de rúbrica)
          // Se desactiva mientras la animación está corriendo
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Tooltip(
              message: 'Resolver TSP con AG',
              child: ElevatedButton.icon(
                onPressed: _animacionLista ? null : _resolverTSP,
                icon: const Text('🧬', style: TextStyle(fontSize: 18)),
                label: const Text('Resolver', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _animacionLista
                      ? Colors.grey.shade500
                      : Colors.amber.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
          Expanded(
            child: Stack(
              children: [
                // Fondo gris claro
                Container(color: Colors.grey.shade100),

                // CustomPainter: dibuja nodos, aristas, trazo y bola
                CustomPaint(
                  painter: DibujaGrafo(
                    grafo.vNodo, grafo.vArista, _posBola, _trazoRuta, grafo.nodoInicio),
                  child: Container(),
                ),

                // GestureDetector para interacción con el canvas
                // Se ignoran todos los gestos mientras la animación está activa
                if (!_animacionLista)
                GestureDetector(
                  onPanDown:   _onPanDown,
                  onPanUpdate: _onPanUpdate,
                  onPanEnd:    _onPanEnd,
                ),

                // Indicador del modo activo (arriba a la izquierda)
                if (modo != MODO_NINGUNO)
                  Positioned(
                    top: 8, left: 8,
                    child: _chipModo(),
                  ),

                // Ruta óptima en texto (cuando la animación termina)
                if (_textoRuta.isNotEmpty)
                  Positioned(
                    bottom: 16, left: 12, right: 12,
                    child: _tarjetaRuta(),
                  ),
              ],
            ),
          ),

          // ── Controles de reproducción ──
          if (_animacionLista) _barraReproduccion(),

          // ── Barra de herramientas inferior ──
          _barraHerramientas(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  GESTOS DEL CANVAS
  // ─────────────────────────────────────────────────────────────

  void _onPanDown(DragDownDetails d) {
    double x = d.localPosition.dx;
    double y = d.localPosition.dy;

    if (modo == MODO_AGREGAR) {
      _dialogoCrearNodo(x, y);

    } else if (modo == MODO_ELIMINAR) {
      int posN = grafo.buscaNodo(x, y);
      if (posN >= 0) {
        setState(() {
          grafo.eliminarNodo(posN);
          _detenerAnimacion();
        });
      } else {
        int posA = grafo.buscaArista(x, y);
        if (posA >= 0) {
          setState(() {
            grafo.eliminarArista(posA);
            _detenerAnimacion();
          });
        }
      }

    } else if (modo == MODO_EDITAR) {
      int posN = grafo.buscaNodo(x, y);
      if (posN >= 0) {
        _dialogoEditarNodo(grafo.vNodo[posN]);
      } else {
        int posA = grafo.buscaArista(x, y);
        if (posA >= 0) {
          _dialogoEditarArista(grafo.vArista[posA]);
        }
      }

    } else if (modo == MODO_MOVER) {
      int posN = grafo.buscaNodo(x, y);
      if (posN >= 0) setState(() => posPub = posN);

    } else if (modo == MODO_CONECTAR) {
      int posN = grafo.buscaNodo(x, y);
      if (posN >= 0) {
        if (nodoOrigenConexion == null) {
          setState(() => nodoOrigenConexion = grafo.vNodo[posN]);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Nodo origen seleccionado. Ahora toca el destino.'),
            duration: Duration(seconds: 2),
          ));
        } else {
          if (nodoOrigenConexion != grafo.vNodo[posN]) {
            _dialogoCrearArista(nodoOrigenConexion!, grafo.vNodo[posN]);
          }
          setState(() => nodoOrigenConexion = null);
        }
      }

    } else if (modo == MODO_CURVA) {
      int posA = grafo.buscaArista(x, y);
      if (posA >= 0) setState(() => posAristaPub = posA);

    } else if (modo == MODO_INICIO) {
      int posN = grafo.buscaNodo(x, y);
      if (posN >= 0) {
        setState(() => grafo.definirNodoInicio(grafo.vNodo[posN]));
        // Confirmar al usuario qué nodo quedó seleccionado
        String msg = grafo.nodoInicio != null
            ? '★ "${grafo.nodoInicio!.mensaje}" marcado como nodo de inicio'
            : 'Nodo de inicio eliminado';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: grafo.nodoInicio != null
              ? Colors.amber.shade700
              : Colors.grey.shade700,
          duration: const Duration(seconds: 2),
        ));
      }
    }
  }

  void _onPanUpdate(DragUpdateDetails d) {
    double x = d.localPosition.dx;
    double y = d.localPosition.dy;

    setState(() {
      if (modo == MODO_MOVER && posPub >= 0) {
        grafo.vNodo[posPub].x = x;
        grafo.vNodo[posPub].y = y;
      } else if (modo == MODO_CURVA && posAristaPub >= 0) {
        // Calcula curvatura según la distancia del dedo al centro de la arista
        ModeloArista ar = grafo.vArista[posAristaPub];
        double midX = (ar.origen.x + ar.destino.x) / 2;
        double midY = (ar.origen.y + ar.destino.y) / 2;
        double dx   = x - midX;
        double dy   = y - midY;
        double curv = sqrt(dx * dx + dy * dy);
        ar.curvatura = (dy < 0) ? -curv : curv;
      }
    });
  }

  void _onPanEnd(DragEndDetails d) {
    setState(() {
      posPub       = -1;
      posAristaPub = -1;
    });
  }

  // ─────────────────────────────────────────────────────────────
  //  DIÁLOGOS
  // ─────────────────────────────────────────────────────────────

  // Diálogo para crear un nodo: nombre + color
  Future<void> _dialogoCrearNodo(double x, double y) async {
    TextEditingController tecNombre = TextEditingController();
    Color colorElegido = Colors.purple;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setDialogState) {
            return AlertDialog(
              title: const Text('Nuevo Nodo'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: tecNombre,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      hintText: 'Vacío = nombre automático',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Color del nodo:', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 8),
                  // Selector de colores
                  Wrap(
                    spacing: 8,
                    children: coloresNodo.entries.map((entry) {
                      bool seleccionado = colorElegido == entry.value;
                      return GestureDetector(
                        onTap: () => setDialogState(() => colorElegido = entry.value),
                        child: Tooltip(
                          message: entry.key,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: entry.value,
                              border: seleccionado
                                  ? Border.all(color: Colors.black, width: 3)
                                  : Border.all(color: Colors.transparent),
                              boxShadow: seleccionado
                                  ? [BoxShadow(color: entry.value.withOpacity(0.5), blurRadius: 8)]
                                  : [],
                            ),
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
                      grafo.agregarNodo(tecNombre.text, x, y, colorElegido);
                    });
                  },
                  child: const Text('Crear'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Diálogo para crear una arista: solo ingresa el peso (debe ser > 0)
  Future<void> _dialogoCrearArista(ModeloNodo origen, ModeloNodo destino) async {
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
          title: Text('Arista: ${origen.mensaje} → ${destino.mensaje}'),
          content: TextField(
            controller: tecPeso,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Peso (número positivo)',
              hintText: 'Ej: 10',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                int peso = int.tryParse(tecPeso.text.trim()) ?? 0;
                if (peso <= 0) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('El peso debe ser un número positivo')),
                  );
                  return;
                }
                Navigator.pop(ctx);
                setState(() {
                  grafo.agregarArista(origen, destino, peso);
                });
              },
              child: const Text('Conectar'),
            ),
          ],
        );
      },
    );
  }

  // Diálogo para editar nombre y color de un nodo
  Future<void> _dialogoEditarNodo(ModeloNodo nodo) async {
    TextEditingController tec = TextEditingController(text: nodo.mensaje);
    Color colorElegido = nodo.color;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx2, setDs) {
          return AlertDialog(
            title: const Text('Editar Nodo'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: tec,
                  decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 14),
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
                    if (tec.text.trim().isNotEmpty) nodo.mensaje = tec.text.trim();
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
    TextEditingController tec = TextEditingController(text: ar.peso.toString());
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
                int peso = int.tryParse(tec.text.trim()) ?? ar.peso;
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
    if (grafo.vNodo.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Necesitas al menos 2 nodos para calcular la ruta.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validación obligatoria: debe haber un nodo de inicio definido
    if (grafo.nodoInicio == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Debes marcar un nodo de inicio antes de resolver.\nUsa el botón ★ de la barra inferior.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    _detenerAnimacion();

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
      _rutaTSP     = mejorRuta;
      _costoTotal  = costo;
      grafo.resaltarRutaTSP(mejorRuta);
      _animacionLista = true;
      _trazoRuta      = [];
      _posBola        = null;

      // Texto de la ruta con ciclo cerrado visible
      List<String> nombres = mejorRuta.map((n) => n.mensaje).toList();
      _textoRuta = '🛣 ${nombres.join(' → ')}';
    });

    _iniciarAnimacion();
  }

  // Inicia la animación del viajante recorriendo la ruta
  void _iniciarAnimacion() {
    if (_rutaTSP.length < 2) return;

    _animCtrl?.dispose();

    int tramos = _rutaTSP.length - 1;
    _animCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: tramos * 1000),
    );

    // Animación progresiva: valor va de 0 a "tramos"
    Animation<double> anim = Tween<double>(begin: 0, end: tramos.toDouble())
        .animate(_animCtrl!);

    anim.addListener(() {
      setState(() {
        double val = anim.value;
        int idx    = val.floor().clamp(0, tramos - 1);
        double t   = (val - idx).clamp(0.0, 1.0);

        ModeloNodo n1 = _rutaTSP[idx];
        ModeloNodo n2 = _rutaTSP[idx + 1 > tramos ? tramos : idx + 1];

        // Obtener curvatura real de la arista (si existe)
        double curv = 0;
        int idxAr = grafo.vArista.indexWhere((a) =>
            (a.origen == n1 && a.destino == n2) ||
            (a.origen == n2 && a.destino == n1));
        if (idxAr >= 0) {
          curv = (grafo.vArista[idxAr].origen == n1)
              ? grafo.vArista[idxAr].curvatura
              : -grafo.vArista[idxAr].curvatura;
        }

        Offset p1   = Offset(n1.x, n1.y);
        Offset p2   = Offset(n2.x, n2.y);
        Offset ctrl = Matematicas.calcularPuntoControl(p1, p2, curv);

        // Posición actual de la bola
        _posBola = Matematicas.obtenerPuntoEnCurva(p1, p2, ctrl, t);

        // Agregar punto al trazo (pintado progresivo)
        _trazoRuta.add(_posBola!);
      });
    });

    _animCtrl!.forward();
  }

  // Detiene y limpia la animación
  void _detenerAnimacion() {
    _animCtrl?.stop();
    setState(() {
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade700.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(nombres[modo] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13)),
    );
  }

  // Tarjeta que muestra la ruta óptima en texto y el costo total
  Widget _tarjetaRuta() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade800.withOpacity(0.92),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _textoRuta,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '💰 Costo total: ${_costoTotal.toStringAsFixed(0)}',
            style: TextStyle(
              color: Colors.amber.shade300,
              fontSize: 14,
              fontWeight: FontWeight.bold,
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
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Play / Continuar
          IconButton(
            tooltip: 'Play',
            onPressed: () {
              if (_animCtrl != null && !_animCtrl!.isAnimating) {
                if (_animCtrl!.isCompleted) {
                  // Reiniciar trazo y reproducir de nuevo
                  setState(() => _trazoRuta = []);
                  _animCtrl!.forward(from: 0);
                } else {
                  _animCtrl!.forward();
                }
              }
            },
            icon: const Icon(Icons.play_arrow, color: Colors.white, size: 30),
          ),
          // Pausa
          IconButton(
            tooltip: 'Pausa',
            onPressed: () => _animCtrl?.stop(),
            icon: const Icon(Icons.pause, color: Colors.white, size: 30),
          ),
          // Reset
          IconButton(
            tooltip: 'Reiniciar animación',
            onPressed: () {
              setState(() => _trazoRuta = []);
              _animCtrl?.stop();
              _animCtrl?.forward(from: 0);
            },
            icon: const Icon(Icons.replay, color: Colors.white, size: 30),
          ),
          // Cerrar animación
          IconButton(
            tooltip: 'Cerrar',
            onPressed: _detenerAnimacion,
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
      modo = (modo == nuevoModo) ? MODO_NINGUNO : nuevoModo;
      nodoOrigenConexion = null;
    });
  }
}
