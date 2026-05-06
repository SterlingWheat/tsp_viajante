import 'package:flutter/material.dart';
import 'package:tsp_viajante2/widgets/menu_lateral.dart';

// Pantalla "Acerca de": explica el proyecto y el algoritmo genético
class Acerca extends StatelessWidget {
  const Acerca({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acerca del Proyecto'), //Título de la barra de navegación
        backgroundColor: Colors.deepPurple.shade700,
        foregroundColor: Colors.white,
      ),
      drawer: const MenuLateral(), //Menú lateral para navegar entre pantallas
      body: SingleChildScrollView( //Permite desplazarse si el contenido es muy largo
        padding: const EdgeInsets.all(20), //Espacio alrededor del contenido de 20px
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,//Alinea el contenido a la izquierda
          children: [
            _seccion( //llama a la funcion _seccion
              context,
              icono: Icons.route,//Icono de ruta 
              titulo: 'Problema del Viajante (TSP)',
              texto:
                  'El TSP busca el camino más corto que recorre todos los nodos '
                  'del grafo usando las aristas disponibles. '
                  'Es un problema NP-Difícil, es decir, no existe un algoritmo exacto eficiente '
                  'para instancias grandes. Los algoritmos genéticos ofrecen soluciones aproximadas de calidad.',
            ),
            const SizedBox(height: 20), //Espacio entre secciones de 20px
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
              child: ElevatedButton.icon( //Botón con icono
                onPressed: () => Navigator.pushNamed(context, '/editor'), //Navega a la pantalla del editor al presionar el boton
                icon: const Icon(Icons.account_tree), //Icono del boton
                label: const Text('Ir al Editor'),//Texto
                style: ElevatedButton.styleFrom(//Estilo del boton 
                  backgroundColor: Colors.deepPurple.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14), //Espacio interno del boton
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),//Bordes redondeados
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _seccion(BuildContext context, {required IconData icono, required String titulo, required String texto}) { //Recibe el contexto, el icono, el título y el texto de la sección
    return Container(
      padding: const EdgeInsets.all(16), //Espacio interno de 16px para que el contenido no quede pegado a los bordes
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,//Fondo lila claro para diferenciar las secciones
        borderRadius: BorderRadius.circular(16), //Bordes redondeados del recuadro contenedor
        border: Border.all(color: Colors.deepPurple.shade200), //Borde lila suave y delgado
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,//Alinea el contenido a la izquierda dentro de cada sección
        children: [
          Row(children: [
            Icon(icono, color: Colors.deepPurple.shade700, size: 22), //Icono color lila y tamaño de 22px
            const SizedBox(width: 8), //Espacio entre el icono y el título de 8px
            Expanded( //El título ocupa el espacio restante para evitar desbordamientos
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
