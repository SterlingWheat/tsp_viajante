import 'package:flutter/material.dart';
import 'package:tsp_viajante2/widgets/menu_lateral.dart';

// Pantalla "Acerca de": explica el proyecto y el algoritmo genético
class Acerca extends StatelessWidget {
  const Acerca({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acerca del Proyecto'),
        backgroundColor: Colors.deepPurple.shade700,
        foregroundColor: Colors.white,
      ),
      drawer: const MenuLateral(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _seccion(
              context,
              icono: Icons.route,
              titulo: 'Problema del Viajante (TSP)',
              texto:
                  'El TSP busca el camino más corto que recorre todos los nodos '
                  'del grafo usando las aristas disponibles. '
                  'Es un problema NP-Difícil, es decir, no existe un algoritmo exacto eficiente '
                  'para instancias grandes. Los algoritmos genéticos ofrecen soluciones aproximadas de calidad.',
            ),
            const SizedBox(height: 20),
            _seccion(
              context,
              icono: Icons.science,
              titulo: 'Algoritmo Genético',
              texto:
                  '1. Población inicial: rutas aleatorias.\n'
                  '2. Fitness: costo total (suma de pesos de aristas).\n'
                  '3. Selección: los mejores 50% sobreviven.\n'
                  '4. Cruce OX1: combina segmentos de dos padres.\n'
                  '5. Mutación: intercambia dos ciudades al azar.\n'
                  '6. Elitismo: los 2 mejores pasan intactos.\n'
                  '7. Se repite durante 600 generaciones.',
            ),
            const SizedBox(height: 20),
            _seccion(
              context,
              icono: Icons.touch_app,
              titulo: 'Cómo usar el editor',
              texto:
                  '➕ Añadir: toca el canvas para crear un nodo.\n'
                  '✏️ Editar: toca un nodo o arista para modificarlos.\n'
                  '❌ Eliminar: toca un nodo o arista para borrarlo.\n'
                  '🔗 Conectar: toca dos nodos para unirlos con una arista.\n'
                  '✋ Mover: arrastra nodos para reposicionarlos.\n'
                  '〰️ Curva: arrastra una arista para ajustar su curvatura.\n\n'
                  'Una vez creado el grafo, presiona el botón 🧬 para ejecutar el algoritmo genético '
                  'y ver la animación del viajante.',
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/editor'),
                icon: const Icon(Icons.account_tree),
                label: const Text('Ir al Editor'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _seccion(BuildContext context, {required IconData icono, required String titulo, required String texto}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.deepPurple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icono, color: Colors.deepPurple.shade700, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(titulo,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.deepPurple.shade700)),
            ),
          ]),
          const SizedBox(height: 10),
          Text(texto, style: const TextStyle(fontSize: 14, height: 1.6)),
        ],
      ),
    );
  }
}
