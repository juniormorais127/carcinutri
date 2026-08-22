import 'package:flutter/material.dart';

/// Campo de entrada com rótulo e unidade opcional.
/// [texto] define o teclado: texto livre (ex.: marca) ou numérico decimal.
class CampoCalculo extends StatelessWidget {
  final TextEditingController controller;
  final String rotulo;
  final String? unidade;
  final bool texto;

  const CampoCalculo({
    super.key,
    required this.controller,
    required this.rotulo,
    this.unidade,
    this.texto = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: texto
          ? TextInputType.text
          : const TextInputType.numberWithOptions(
              decimal: true,
              signed: false,
            ),
      decoration: InputDecoration(
        labelText: rotulo,
        suffixText: unidade,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
