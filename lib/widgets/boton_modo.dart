import 'package:flutter/material.dart';

// Widget reutilizable para los botones de modo del editor
// Se ilumina en verde cuando el modo está activo
class BotonModo extends StatelessWidget {
  final int modoId;
  final int modoActual;
  final IconData icono;
  final String etiqueta;
  final VoidCallback alPresionar;

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
    bool activo = modoId == modoActual;
    return Tooltip(
      message: etiqueta,
      child: GestureDetector(
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
                blurRadius: activo ? 8 : 3,
                spreadRadius: activo ? 2 : 0,
              )
            ],
          ),
          child: Icon(icono, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
