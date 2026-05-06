import 'package:flutter/material.dart';

// Pantalla de bienvenida: primera pantalla que ve el usuario
class Bienvenida extends StatefulWidget {
  const Bienvenida({super.key});

  @override
  State<Bienvenida> createState() => _BienvenidaState();
}

class _BienvenidaState extends State<Bienvenida> with SingleTickerProviderStateMixin {
  //declaramos variables para manejar una animación
  late AnimationController _ctrl; //Controla el tiempo de la animación
  late Animation<double> _fadeAnim; //Animación de opacidad
  late Animation<double> _scaleAnim;//Animación de escala (zoom)

  @override
  void initState() {
    super.initState();//Inicializamos las animaciones
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200)); //Duracion de 1.2 segundos
    _fadeAnim  = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);//empieza lentamente y luego acelera
    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate( //hace que empieze empiece pequeño y luego crezca a su tamaño normal
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),//efecto de rebote al aparecer
    );
    _ctrl.forward();//Iniciamos la animación al cargar la pantalla
  }

  @override
  void dispose() { //libera memoria y detiene la animacion
    _ctrl.dispose();//Detiene la animación y libera recursos
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
        child: Stack( //Permite superponer widgets, como los círculos decorativos y el contenido central
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
              child: FadeTransition(//Aplica la animación de opacidad al contenido
                opacity: _fadeAnim,
                child: ScaleTransition(//Aplica la animación de escala al contenido
                  scale: _scaleAnim,
                  child: Padding(//Agrega espacio horizontal alrededor del contenido
                    padding: const EdgeInsets.symmetric(horizontal: 32),//Espacio a los lados para que no quede pegado a los bordes
                    child: Column(
                      mainAxisSize: MainAxisSize.min,//El contenido se ajusta a su tamaño mínimo necesario
                      children: [
                        // Ícono principal
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.amber.shade600,
                            boxShadow: [
                              BoxShadow(color: Colors.amber.withOpacity(0.4), blurRadius: 20, spreadRadius: 4),//Sombra amarilla suave alrededor del ícono
                            ],
                          ),
                          child: const Icon(Icons.travel_explore, size: 60, color: Colors.white),//Icono de viajante
                        ),
                        const SizedBox(height: 28),//Espacio entre el ícono y el título de 28px

                        // Título
                        const Text(
                          'TSP Viajante',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.bold,//Texto en negrita
                            letterSpacing: 1.5, //Espacio entre letras de 1.5px
                          ),
                        ),
                        const SizedBox(height: 10), //Espacio entre el título y el subtítulo de 10px

                        // Subtítulo
                        Text(
                          'Resuelve el Problema del Viajante\ncon Algoritmos Genéticos',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 15,
                            height: 1.5, //Espacio entre líneas de 1.5px
                          ),
                        ),
                        const SizedBox(height: 50), //Espacio entre el subtítulo y los botones de 50px

                        // Botón principal
                        SizedBox(
                          width: double.infinity, //El botón ocupa todo el ancho disponible
                          height: 52, //Altura del botón de 52px
                          child: ElevatedButton.icon( //Boton con icono y texto
                            onPressed: () => Navigator.pushNamed(context, '/editor'),//Navega a la pantalla del editor al presionar el boton
                            icon: const Icon(Icons.play_arrow, size: 24),//Icono de "play" para indicar que es el boton de inicio
                            label: const Text('Comenzar', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),//Texto del boton
                            style: ElevatedButton.styleFrom( //Estilo del boton
                              backgroundColor: Colors.amber.shade600, //Fondo amber
                              foregroundColor: Colors.white, //Texto e icono en blanco
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),//Boton con bordes redondeados
                              elevation: 8,//Sombra del boton para darle profundidad
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),//Espacio entre los botones de 16px

                        // Botón secundario
                        SizedBox(
                          width: double.infinity, //El botón ocupa todo el ancho disponible
                          height: 50, //Altura del botón de 50px
                          child: OutlinedButton.icon( //Boton con borde y sin fondo
                            onPressed: () => Navigator.pushNamed(context, '/acerca'), //Navega a la pantalla de "Acerca de" al presionar el boton
                            icon: const Icon(Icons.info_outline, color: Colors.white), //icono de informacion
                            label: const Text('¿Cómo funciona?', style: TextStyle(color: Colors.white, fontSize: 15)), //Texto del boton en blanco
                            style: OutlinedButton.styleFrom( //Estilo del boton
                              side: const BorderSide(color: Colors.white54), //Borde blanco semitransparente
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)), //Boton con bordes redondeados
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

  Widget _circuloFondo(double radio, Color color) { //Recibe el radio y el color
    return Container( //retorna un contenedor circular con el tamaño y color especificados
      width: radio,
      height: radio,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color), //Forma circular y color de fondo
    );
  }
}
