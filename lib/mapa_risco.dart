import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'previsao.dart';

const _cidades = [
  ('Recife', LatLng(-8.0578, -34.8829)),
  ('Olinda', LatLng(-8.0089, -34.8553)),
  ('Paulista', LatLng(-7.9408, -34.8731)),
];

class MapaRisco extends StatefulWidget {
  const MapaRisco({super.key});

  @override
  State<MapaRisco> createState() => _MapaRiscoState();
}

class _MapaRiscoState extends State<MapaRisco> {
  final _cliente = http.Client();
  late final Timer _atualizacaoAutomatica;
  List<int?> _probabilidades = List.filled(_cidades.length, null);
  DateTime? _ultimaConsulta;
  bool _carregando = false;
  bool _falha = false;

  @override
  void initState() {
    super.initState();
    unawaited(_atualizar());
    _atualizacaoAutomatica = Timer.periodic(
      const Duration(minutes: 10),
      (_) => unawaited(_atualizar()),
    );
  }

  @override
  void dispose() {
    _atualizacaoAutomatica.cancel();
    _cliente.close();
    super.dispose();
  }

  Future<void> _atualizar() async {
    if (_carregando) return;
    setState(() => _carregando = true);
    try {
      final previsao = await consultarChuva(
        _cliente,
        _cidades.map((cidade) => cidade.$2).toList(),
      );

      if (!mounted) return;
      setState(() {
        _probabilidades = previsao.probabilidades;
        _ultimaConsulta = previsao.consultadoEm;
        _falha = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _falha = true;
          _probabilidades = List.filled(_cidades.length, null);
          _ultimaConsulta = null;
        });
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Color _cor(int? chance) {
    if (chance == null) return const Color(0xFF667585);
    if (chance >= 70) return const Color(0xFFD14343);
    if (chance >= 40) return const Color(0xFFE3AD13);
    return const Color(0xFF51A453);
  }

  @override
  Widget build(BuildContext context) {
    final hora = _ultimaConsulta;
    final status = _falha
        ? 'Previsão indisponível. Tente atualizar novamente.'
        : hora == null
        ? 'Consultando previsão…'
        : 'Consultado às ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(hora), alwaysUse24HourFormat: true)} · atualização a cada 10 min';
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'MAPA DE RISCO',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const Text('Maior probabilidade horária de chuva nas próximas 3 horas'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: Text(status)),
            IconButton(
              onPressed: _carregando ? null : _atualizar,
              tooltip: 'Atualizar previsão',
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        if (_carregando) const LinearProgressIndicator(),
        const SizedBox(height: 8),
        SizedBox(
          height: 440,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: FlutterMap(
              options: const MapOptions(
                initialCenter: LatLng(-8.000, -34.883),
                initialZoom: 11,
                minZoom: 9,
                maxZoom: 18,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.cidade_inteligente',
                ),
                CircleLayer(
                  circles: [
                    for (final (i, cidade) in _cidades.indexed)
                      CircleMarker(
                        point: cidade.$2,
                        radius: 2300,
                        useRadiusInMeter: true,
                        color: _cor(_probabilidades[i]).withValues(alpha: 0.34),
                        borderColor: _cor(_probabilidades[i]),
                        borderStrokeWidth: 2,
                      ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    for (final (i, cidade) in _cidades.indexed)
                      Marker(
                        point: cidade.$2,
                        width: 120,
                        height: 52,
                        child: Center(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Text(
                                '${cidade.$1}\n${_probabilidades[i] == null ? 'Sem dados' : '${_probabilidades[i]}%'}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SimpleAttributionWidget(
                  source: Text('© OpenStreetMap contributors'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            for (final (chance, legenda) in const <(int?, String)>[
              (0, 'Baixa · 0–39%'),
              (40, 'Moderada · 40–69%'),
              (70, 'Alta · 70–100%'),
              (null, 'Sem dados'),
            ])
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, size: 12, color: _cor(chance)),
                  const SizedBox(width: 6),
                  Text(legenda),
                ],
              ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Áreas aproximadas ao redor dos pontos consultados. A cor indica chance de chuva.',
        ),
        const Text('Previsão fornecida pelo Open-Meteo.'),
      ],
    );
  }
}
