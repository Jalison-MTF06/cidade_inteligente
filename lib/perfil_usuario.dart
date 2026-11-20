import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'previsao.dart';

class PerfilUsuario extends StatefulWidget {
  const PerfilUsuario({
    super.key,
    required this.nome,
    required this.cidade,
    required this.somenteSessao,
    required this.aoSalvar,
  });

  final String nome;
  final Cidade? cidade;
  final bool somenteSessao;
  final Future<void> Function(String, Cidade?) aoSalvar;

  @override
  State<PerfilUsuario> createState() => _PerfilUsuarioState();
}

class _PerfilUsuarioState extends State<PerfilUsuario> {
  final _formulario = GlobalKey<FormState>();
  final _cliente = http.Client();
  final _busca = TextEditingController();
  late final _nome = TextEditingController(text: widget.nome);
  late Cidade? _cidadeSelecionada = widget.cidade;
  late final Timer _timer;
  Future<int>? _previsao;
  List<Cidade> _resultados = [];
  String? _avisoBusca;
  bool _buscando = false;
  bool _salvo = false;
  bool _salvando = false;
  bool _falhaAoSalvar = false;

  @override
  void initState() {
    super.initState();
    _carregarPrevisao();
    _timer = Timer.periodic(
      const Duration(minutes: 10),
      (_) => setState(_carregarPrevisao),
    );
  }

  @override
  void didUpdateWidget(covariant PerfilUsuario oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cidade != widget.cidade) _carregarPrevisao();
  }

  @override
  void dispose() {
    _timer.cancel();
    _nome.dispose();
    _busca.dispose();
    _cliente.close();
    super.dispose();
  }

  void _carregarPrevisao() {
    final cidade = widget.cidade;
    _previsao = cidade == null
        ? null
        : consultarChuva(_cliente, [
            cidade.ponto,
          ]).then((dados) => dados.probabilidades.single!);
  }

  Future<void> _buscar() async {
    if (_buscando) return;
    final termo = _busca.text.trim();
    if (termo.length < 2) {
      setState(() {
        _resultados = [];
        _avisoBusca = 'Digite pelo menos dois caracteres.';
      });
      return;
    }
    setState(() {
      _buscando = true;
      _avisoBusca = null;
      _resultados = [];
    });
    try {
      final resultados = await buscarCidades(_cliente, termo);
      if (!mounted) return;
      setState(() {
        _resultados = resultados;
        if (resultados.isEmpty) _avisoBusca = 'Nenhuma cidade encontrada.';
      });
    } catch (_) {
      if (mounted) {
        setState(() => _avisoBusca = 'Busca indisponível. Tente novamente.');
      }
    } finally {
      if (mounted) setState(() => _buscando = false);
    }
  }

  Future<void> _salvar() async {
    if (_salvando) return;
    if (!_formulario.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _salvando = true;
      _salvo = false;
      _falhaAoSalvar = false;
    });
    try {
      await widget.aoSalvar(_nome.text.trim(), _cidadeSelecionada);
      if (mounted) setState(() => _salvo = true);
    } catch (_) {
      if (mounted) setState(() => _falhaAoSalvar = true);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Meu perfil', style: tema.textTheme.headlineMedium),
        const SizedBox(height: 16),
        _cartaoPrevisao(),
        const SizedBox(height: 16),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formulario,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dados pessoais', style: tema.textTheme.titleLarge),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nome,
                    enabled: !_salvando,
                    onChanged: (_) {
                      if (_salvo) setState(() => _salvo = false);
                    },
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Seu nome',
                      border: OutlineInputBorder(),
                    ),
                    validator: (nome) {
                      final valor = nome?.trim() ?? '';
                      if (valor.isEmpty) return 'Informe seu nome.';
                      if (valor.runes.length > 120) {
                        return 'Use até 120 caracteres.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Cidade onde você mora',
                    style: tema.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _cidadeSelecionada?.nome ?? 'Nenhuma cidade selecionada',
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _busca,
                    enabled: !_buscando && !_salvando,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _buscar(),
                    decoration: InputDecoration(
                      labelText: 'Buscar cidade no Brasil',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        tooltip: 'Buscar cidade',
                        icon: const Icon(Icons.search),
                        onPressed: _buscando || _salvando ? null : _buscar,
                      ),
                    ),
                  ),
                  if (_buscando) const LinearProgressIndicator(),
                  if (_avisoBusca case final String aviso)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(aviso),
                    ),
                  for (final cidade in _resultados)
                    ListTile(
                      leading: const Icon(Icons.location_on_outlined),
                      title: Text(cidade.nome),
                      onTap: _salvando
                          ? null
                          : () {
                              setState(() {
                                _cidadeSelecionada = cidade;
                                _salvo = false;
                                _resultados = [];
                                _busca.clear();
                              });
                            },
                    ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _salvando ? null : _salvar,
                    child: Text(_salvando ? 'Salvando…' : 'Salvar perfil'),
                  ),
                  if (_salvo)
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        widget.somenteSessao
                            ? 'Perfil salvo nesta sessão.'
                            : 'Perfil salvo.',
                      ),
                    ),
                  if (_falhaAoSalvar)
                    const Text('Não foi possível salvar. Tente novamente.'),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text('Previsão do Open-Meteo · localidades do GeoNames'),
      ],
    );
  }

  Widget _cartaoPrevisao() {
    final tema = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      color: tema.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: FutureBuilder<int>(
          key: ValueKey(widget.cidade),
          future: _previsao,
          builder: (context, consulta) {
            final carregando =
                consulta.connectionState == ConnectionState.waiting;
            final chance = consulta.data;
            final descricao = switch (chance) {
              null => '',
              >= 70 => 'Alta',
              >= 40 => 'Moderada',
              _ => 'Baixa',
            };
            final mensagem = widget.cidade == null
                ? 'Selecione e salve sua cidade para consultar a previsão.'
                : carregando
                ? 'Consultando previsão…'
                : chance == null
                ? 'Previsão indisponível. Tente atualizar.'
                : '$descricao · $chance%';
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.thunderstorm_outlined, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Chance de chuva', style: tema.textTheme.titleLarge),
                      if (widget.cidade case final Cidade cidade)
                        Text('${cidade.nome} · Próximas 3 horas'),
                      const SizedBox(height: 4),
                      Text(mensagem, style: tema.textTheme.titleMedium),
                      if (carregando) const LinearProgressIndicator(),
                    ],
                  ),
                ),
                if (widget.cidade != null)
                  IconButton(
                    tooltip: 'Atualizar previsão',
                    icon: const Icon(Icons.refresh),
                    onPressed: carregando
                        ? null
                        : () => setState(_carregarPrevisao),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
