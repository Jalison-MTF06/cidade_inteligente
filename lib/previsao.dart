import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

typedef Cidade = ({String nome, LatLng ponto});

Future<Object?> _consultar(http.Client cliente, Uri uri) async {
  final resposta = await cliente.get(uri).timeout(const Duration(seconds: 15));
  if (resposta.statusCode != 200) {
    throw const FormatException('Consulta indisponível');
  }
  return jsonDecode(utf8.decode(resposta.bodyBytes));
}

Future<List<Cidade>> buscarCidades(http.Client cliente, String nome) async {
  final dados = await _consultar(
    cliente,
    Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
      'name': nome,
      'language': 'pt',
      'countryCode': 'BR',
      'count': '10',
    }),
  ) as Map<String, dynamic>;
  final resultados = dados['results'] as List<dynamic>? ?? [];
  return [
    for (final local in resultados)
      if (local['country_code'] == 'BR' &&
          (local['feature_code'] as String? ?? '').startsWith('PPL'))
        (
          nome: [
            local['name'] as String,
            if (local['admin2'] case final String municipio
                when municipio != local['name'])
              municipio,
            if (local['admin1'] case final String estado) estado,
          ].join(' · '),
          ponto: LatLng(
            (local['latitude'] as num).toDouble(),
            (local['longitude'] as num).toDouble(),
          ),
        ),
  ];
}

Future<({List<int?> probabilidades, DateTime consultadoEm})> consultarChuva(
  http.Client cliente,
  List<LatLng> pontos,
) async {
  final dados = await _consultar(
    cliente,
    Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': pontos.map((ponto) => ponto.latitude).join(','),
      'longitude': pontos.map((ponto) => ponto.longitude).join(','),
      'hourly': 'precipitation_probability',
      'forecast_hours': '4',
      'timeformat': 'unixtime',
    }),
  );
  final locais = dados is List<dynamic> ? dados : [dados];
  final agora = DateTime.now();
  final inicio = agora.millisecondsSinceEpoch ~/ 1000;
  final fim = inicio + 3 * 3600;
  final probabilidades = <int?>[];
  for (final local in locais) {
    final horario = (local as Map<String, dynamic>)['hourly'];
    final tempos = horario['time'] as List<dynamic>;
    final valores = horario['precipitation_probability'] as List<dynamic>;
    int? maior;
    for (final (i, tempo) in tempos.indexed) {
      final valor = valores[i];
      if (tempo is int &&
          tempo > inicio &&
          tempo <= fim &&
          valor is int &&
          valor >= 0 &&
          valor <= 100 &&
          (maior == null || valor > maior)) {
        maior = valor;
      }
    }
    probabilidades.add(maior);
  }
  if (probabilidades.length != pontos.length ||
      probabilidades.every((valor) => valor == null)) {
    throw const FormatException('Previsão incompleta');
  }
  return (probabilidades: probabilidades, consultadoEm: agora);
}
