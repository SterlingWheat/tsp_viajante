import 'package:flutter/material.dart';

// Pantalla de bienvenida: primera pantalla que ve el usuario
class Bienvenida extends StatefulWidget {
  const Bienvenida({super.key});

  @override
  State<Bienvenida> createState() => _BienvenidaState();
}

class _BienvenidaState extends State<Bienvenida> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fadeAnim  = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Fondo con gradiente morado
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade900, Colors.purple.shade400, Colors.indigo.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Círculos decorativos de fondo
            Positioned(top: -60, left: -60,
              child: _circuloFondo(200, Colors.white.withOpacity(0.05))),
            Positioned(bottom: -80, right: -80,
              child: _circuloFondo(280, Colors.white.withOpacity(0.05))),
            Positioned(top: 150, right: -40,
              child: _circuloFondo(120, Colors.amber.withOpacity(0.08))),

            // Contenido central animado
            Center(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Ícono principal
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.amber.shade600,
                            boxShadow: [
                              BoxShadow(color: Colors.amber.withOpacity(0.4), blurRadius: 20, spreadRadius: 4),
                            ],
                          ),
                          child: const Icon(Icons.travel_explore, size: 60, color: Colors.white),
                        ),
                        const SizedBox(height: 28),

                        // Título
                        const Text(
                          'TSP Viajante',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Subtítulo
                        Text(
                          'Resuelve el Problema del Viajante\ncon Algoritmos Genéticos',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 50),

                        // Botón principal
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pushNamed(context, '/editor'),
                            icon: const Icon(Icons.play_arrow, size: 24),
                            label: const Text('Comenzar', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber.shade600,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                              elevation: 8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Botón secundario
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pushNamed(context, '/acerca'),
                            icon: const Icon(Icons.info_outline, color: Colors.white),
                            label: const Text('¿Cómo funciona?', style: TextStyle(color: Colors.white, fontSize: 15)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white54),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circuloFondo(double radio, Color color) {
    return Container(
      width: radio,
      height: radio,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
