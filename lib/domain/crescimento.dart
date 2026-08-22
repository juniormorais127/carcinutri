import 'modelos.dart';

/// Ordena as biometrias por data **ascendente** (cronológica).
///
/// O repositório e o [AppState] entregam mais-recente-primeiro; o gráfico de
/// crescimento precisa da ordem inversa (da primeira amostra até a última).
List<Biometria> biometriasCronologicas(List<Biometria> biometrias) {
  final lista = [...biometrias];
  lista.sort((a, b) => a.data.compareTo(b.data));
  return lista;
}

/// Resumo do crescimento de um ciclo a partir das biometrias.
class ResumoCrescimento {
  final int nAmostras;
  final double pesoInicial;
  final double pesoFinal;
  final double ganhoTotal;
  final int dias;
  final double ganhoDiarioMedio;

  ResumoCrescimento({
    required this.nAmostras,
    required this.pesoInicial,
    required this.pesoFinal,
    required this.ganhoTotal,
    required this.dias,
    required this.ganhoDiarioMedio,
  });
}

/// Calcula o resumo do crescimento; retorna `null` quando não há como falar em
/// "ganho" (lista vazia ou com apenas 1 amostra).
ResumoCrescimento? resumirCrescimento(List<Biometria> biometrias) {
  final lista = biometriasCronologicas(biometrias);
  if (lista.length < 2) return null;

  final pesoInicial = lista.first.pesoMedio;
  final pesoFinal = lista.last.pesoMedio;
  final ganhoTotal = pesoFinal - pesoInicial;
  final dias = lista.last.data.difference(lista.first.data).inDays;

  return ResumoCrescimento(
    nAmostras: lista.length,
    pesoInicial: pesoInicial,
    pesoFinal: pesoFinal,
    ganhoTotal: ganhoTotal,
    dias: dias,
    ganhoDiarioMedio: dias > 0 ? ganhoTotal / dias : 0,
  );
}
