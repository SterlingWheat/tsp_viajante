import 'package:flutter/material.dart';

// Menú lateral (Drawer)
// Permite navegar entre pantallas
class MenuLateral extends StatelessWidget {
  const MenuLateral({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer( //Widget de Flutter para crear un menú lateral deslizable
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade900, Colors.deepPurple.shade300],
            begin: Alignment.topLeft, //El degradado comienza en la esquina superior izquierda
            end: Alignment.bottomRight, //El degradado termina en la esquina inferior derecha
          ),
        ),
        child: Column( //Organiza los elementos del menú en una columna
          children: [
            // Cabecera con info del usuario
            UserAccountsDrawerHeader( //Widget para mostrar informacion 
              decoration: BoxDecoration(color: Colors.deepPurple.shade900), //Fondo de la cabecera
              accountName: const Text(
                'TSP Viajante', //Nombre del titulo del menu
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              accountEmail: const Text('Algoritmos Genéticos'), //Subtitulo del menu
              currentAccountPicture: CircleAvatar( //Avatar circular para el icono del menu
                backgroundColor: Colors.amber,//Fondo del avatar
                child: Icon(Icons.travel_explore, size: 40, color: Colors.deepPurple.shade900),//Icono dentro del avatar
              ),
            ),

            // Opción: Editor de grafos
            _opcionMenu(
              context, 
              icono: Icons.account_tree, //Icono
              titulo: 'Editor de Grafos',//Nombre de la opción
              subtitulo: 'Crear y editar tu grafo',//Subtitulo de la opción
              ruta: '/editor',//Ruta a la que navega al seleccionar esta opción
            ),

            // Opción: Acerca de
            _opcionMenu(
              context,
              icono: Icons.info_outline,
              titulo: 'Acerca de',
              subtitulo: 'Información del proyecto',
              ruta: '/acerca',
            ),

            const Divider(color: Colors.white30),//Linea divisoria

            // Volver al inicio
            ListTile(
              leading: const Icon(Icons.home, color: Colors.white),//Icono de la opción
              title: const Text('Inicio', style: TextStyle(color: Colors.white)),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 14), //Icono de flecha
              onTap: () {
                Navigator.pop(context);//Cierra el menú lateral
                Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false); //navega a la ruta de inicio
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helper para construir cada ítem del menú
  Widget _opcionMenu(
    BuildContext context, {
    required IconData icono,
    required String titulo,
    required String subtitulo,
    required String ruta,
  }) {
    return ListTile(
      leading: Icon(icono, color: Colors.white),
      title: Text(titulo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)), //Grosor 600 para resaltar el título
      subtitle: Text(subtitulo, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 14),//Icono de flecha
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, ruta);
      },
    );
  }
}
