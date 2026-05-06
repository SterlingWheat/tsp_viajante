import 'package:flutter/material.dart';

// Widget reutilizable para los botones de modo del editor
// Se ilumina en verde cuando el modo está activo
class BotonModo extends StatelessWidget {
  final int modoId; //Identificador único del modo que representa este botón
  final int modoActual; //El modo actualmente activo en el editor
  final IconData icono; //El ícono que representa este botón
  final String etiqueta; //Texto descriptivo para el tooltip
  final VoidCallback alPresionar; //Función a ejecutar cuando se presiona el botón

  const BotonModo({
    super.key,
    required this.modoId,
    required this.modoActual,
    required this.icono,
    required this.etiqueta,
    required this.alPresionar,
  });

  @override
  Widget build(BuildContext context) {
    bool activo = modoId == modoActual; //Determina si este botón representa el modo actualmente activo
    return Tooltip( //Muestra un tooltip con la etiqueta al mantener presionado el botón
      message: etiqueta,
      child: GestureDetector(//envolvemos en un sensor tactil
        onTap: alPresionar,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: activo ? Colors.green.shade700 : Colors.deepPurple.shade700,
            boxShadow: [
              BoxShadow(
                color: activo ? Colors.green.shade300 : Colors.black26,
                blurRadius: activo ? 8 : 3, //Que tan difusa es la sombra
                spreadRadius: activo ? 2 : 0,//Que tan grande es la sombra
              )
            ],
          ),
          child: Icon(icono, color: Colors.white, size: 22), //Coloca el icono dentro del boton
        ),
      ),
    );
  }
}
