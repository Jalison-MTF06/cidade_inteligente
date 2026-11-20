import 'dart:async';

import 'package:flutter/material.dart';

import 'mapa_risco.dart';
import 'perfil_usuario.dart';
import 'previsao.dart';
import 'repositorio_perfil.dart';

const _azul = Color(0xFF0A2D54);

class PainelCidade extends StatefulWidget {
  const PainelCidade({
    super.key,
    required this.usuario,
    required this.aoSair,
    this.repositorio,
  });

  final String usuario;
  final VoidCallback aoSair;
  final RepositorioPerfil? repositorio;

  @override
  State<PainelCidade> createState() => _PainelCidadeState();
}

class _PainelCidadeState extends State<PainelCidade> {
  int _pagina = 0;
  late String _nome = widget.usuario;
  Cidade? _cidade;
  bool _carregandoPerfil = false;
  bool _falhaNoPerfil = false;
  bool _salvandoPerfil = false;

  @override
  void initState() {
    super.initState();
    unawaited(_carregarPerfil());
  }

  Future<void> _carregarPerfil() async {
    final repositorio = widget.repositorio;
    if (repositorio == null) return;
    setState(() {
      _carregandoPerfil = true;
      _falhaNoPerfil = false;
    });
    try {
      final dados = await repositorio.carregar();
      if (mounted && dados != null) {
        setState(() {
          _nome = dados.nome;
          _cidade = dados.cidade;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _falhaNoPerfil = true);
    } finally {
      if (mounted) setState(() => _carregandoPerfil = false);
    }
  }

  Future<void> _salvarPerfil(String nome, Cidade? cidade) async {
    setState(() => _salvandoPerfil = true);
    try {
      final repositorio = widget.repositorio;
      if (repositorio != null) await repositorio.salvar(nome, cidade);
      if (!mounted) return;
      setState(() {
        _nome = nome;
        _cidade = cidade;
      });
    } finally {
      if (mounted) setState(() => _salvandoPerfil = false);
    }
  }

  Widget _perfil() {
    if (_carregandoPerfil) {
      return const Center(
        child: CircularProgressIndicator(semanticsLabel: 'Carregando perfil'),
      );
    }
    if (_falhaNoPerfil) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Não foi possível carregar o perfil.'),
            TextButton(
              onPressed: _carregarPerfil,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }
    return PerfilUsuario(
      nome: _nome,
      cidade: _cidade,
      somenteSessao: widget.repositorio == null,
      aoSalvar: _salvarPerfil,
    );
  }

  @override
  Widget build(BuildContext context) {
    final menuLateral = MediaQuery.sizeOf(context).width >= 720;
    final conteudo = switch (_pagina) {
      0 => const Dashboard(),
      1 => const MapaRisco(),
      _ => _perfil(),
    };
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: menuLateral
          ? null
          : AppBar(
              backgroundColor: _azul,
              foregroundColor: Colors.white,
              title: const Text('Cidade Inteligente'),
            ),
      drawer: menuLateral ? null : Drawer(child: _menu(context, fechar: true)),
      body: SafeArea(
        child: Row(
          children: [
            if (menuLateral) SizedBox(width: 200, child: _menu(context)),
            Expanded(child: conteudo),
          ],
        ),
      ),
    );
  }

  Widget _menu(BuildContext context, {bool fechar = false}) {
    const destinos = [
      (Icons.home_rounded, 'Dashboard'),
      (Icons.map_rounded, 'Mapa de Risco'),
      (Icons.person_outline, 'Perfil'),
    ];
    return Material(
      color: _azul,
      child: SafeArea(
        child: Column(
          children: [
            const ListTile(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              leading: Icon(Icons.thunderstorm_rounded, color: Colors.white),
              title: Text(
                'Cidade Inteligente',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),
            for (final (indice, destino) in destinos.indexed)
              ListTile(
                leading: Icon(destino.$1),
                title: Text(destino.$2),
                textColor: Colors.white,
                iconColor: Colors.white,
                selectedColor: Colors.white,
                selectedTileColor: const Color(0xFF1B4B7A),
                selected: _pagina == indice,
                onTap: _salvandoPerfil
                    ? null
                    : () {
                        if (fechar) Navigator.of(context).pop();
                        setState(() => _pagina = indice);
                      },
              ),
            const Flexible(child: SizedBox.expand()),
            ListTile(
              leading: const Icon(Icons.account_circle_outlined),
              title: Text(_nome, maxLines: 1, overflow: TextOverflow.ellipsis),
              textColor: Colors.white,
              iconColor: Colors.white,
              onTap: _salvandoPerfil
                  ? null
                  : () {
                      if (fechar) Navigator.of(context).pop();
                      setState(() => _pagina = 2);
                    },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sair'),
              textColor: Colors.white,
              iconColor: Colors.white,
              onTap: _salvandoPerfil
                  ? null
                  : () {
                      if (fechar) Navigator.of(context).pop();
                      widget.aoSair();
                    },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final hoje = DateTime.now();
    final data =
        '${hoje.day.toString().padLeft(2, '0')}/'
        '${hoje.month.toString().padLeft(2, '0')}/${hoje.year}';
    const indicadores = [
      (
        'Casas em área de risco',
        '1.248',
        Icons.flood_outlined,
        Color(0xFFB42318),
      ),
      (
        'Famílias cadastradas',
        '3.572',
        Icons.groups_outlined,
        Color(0xFF177445),
      ),
      ('Alertas ativos', '23', Icons.notifications_outlined, Color(0xFF946200)),
    ];
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 16,
          runSpacing: 12,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const Text('Visão geral da situação da cidade'),
              ],
            ),
            Chip(
              avatar: const Icon(Icons.calendar_today_outlined, size: 16),
              label: Text(data),
            ),
          ],
        ),
        const SizedBox(height: 28),
        const Text('Indicadores demonstrativos'),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final largura = constraints.maxWidth;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final (titulo, valor, icone, cor) in indicadores)
                  SizedBox(
                    width: largura >= 690 ? (largura - 24) / 3 : largura,
                    child: Card(
                      margin: EdgeInsets.zero,
                      color: const Color(0xFFE8EDF3),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(icone, size: 36, color: _azul),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(titulo),
                                  Text(
                                    valor,
                                    style: TextStyle(
                                      color: cor,
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 32),
        Card(
          color: Colors.white,
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chuvas acumuladas',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Text('Últimos 7 dias · Exemplo em mm'),
                const SizedBox(height: 16),
                const SizedBox(
                  width: double.infinity,
                  height: 170,
                  child: CustomPaint(painter: _GraficoChuva()),
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [Text('6 dias atrás'), Text('Hoje')],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GraficoChuva extends CustomPainter {
  const _GraficoChuva();

  @override
  void paint(Canvas canvas, Size size) {
    const valores = [34, 66, 73, 42, 43, 52, 90];
    const margem = 28.0;
    final grade = Paint()..color = const Color(0xFFE3EAF2);
    for (var mm = 0; mm <= 100; mm += 25) {
      final y = 8 + (size.height - 16) * (1 - mm / 100);
      canvas.drawLine(Offset(margem, y), Offset(size.width, y), grade);
      final rotulo = TextPainter(
        text: TextSpan(
          text: '$mm',
          style: const TextStyle(fontSize: 10, color: Color(0xFF526377)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      rotulo.paint(canvas, Offset(0, y - rotulo.height / 2));
      rotulo.dispose();
    }
    final pontos = [
      for (final (i, mm) in valores.indexed)
        Offset(
          margem + (size.width - margem - 4) * i / 6,
          8 + (size.height - 16) * (1 - mm / 100),
        ),
    ];
    final linha = Paint()
      ..color = const Color(0xFF226BCC)
      ..strokeWidth = 2;
    for (var i = 1; i < pontos.length; i++) {
      canvas.drawLine(pontos[i - 1], pontos[i], linha);
    }
    for (final ponto in pontos) {
      canvas.drawCircle(ponto, 3.5, linha);
    }
  }

  @override
  bool shouldRepaint(covariant _GraficoChuva oldDelegate) => false;
}
