import 'package:flutter/material.dart';

// Menú lateral (Drawer) igual al visto en clase 29-04
// Permite navegar entre pantallas
class MenuLateral extends StatelessWidget {
  const MenuLateral({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade900, Colors.deepPurple.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // Cabecera con info del usuario
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Colors.deepPurple.shade900),
              accountName: const Text(
                'TSP Viajante',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              accountEmail: const Text('Algoritmos Genéticos'),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.amber,
                child: Icon(Icons.travel_explore, size: 40, color: Colors.deepPurple.shade900),
              ),
            ),

            // Opción: Editor de grafos
            _opcionMenu(
              context,
              icono: Icons.account_tree,
              titulo: 'Editor de Grafos',
              subtitulo: 'Crear y editar tu grafo',
              ruta: '/editor',
            ),

            // Opción: Acerca de
            _opcionMenu(
              context,
              icono: Icons.info_outline,
              titulo: 'Acerca de',
              subtitulo: 'Información del proyecto',
              ruta: '/acerca',
            ),

            const Divider(color: Colors.white30),

            // Volver al inicio
            ListTile(
              leading: const Icon(Icons.home, color: Colors.white),
              title: const Text('Inicio', style: TextStyle(color: Colors.white)),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 14),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
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
      title: Text(titulo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitulo, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 14),
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, ruta);
      },
    );
  }
}
