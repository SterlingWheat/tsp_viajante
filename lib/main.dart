import 'package:flutter/material.dart';
import 'package:tsp_viajante2/home.dart';
import 'package:tsp_viajante2/vistas/bienvenida.dart';
import 'package:tsp_viajante2/vistas/editor.dart';
import 'package:tsp_viajante2/vistas/acerca.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TSP Viajante',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const Bienvenida(),
        '/home': (context) => const Home(),
        '/editor': (context) => const Editor(),
        '/acerca': (context) => const Acerca(),
      },
    );
  }
}
