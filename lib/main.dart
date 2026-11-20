import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'painel_cidade.dart';
import 'repositorio_perfil.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const url = String.fromEnvironment('SUPABASE_URL');
  const chave = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  if (url.isEmpty && chave.isEmpty) {
    runApp(const CidadeInteligente());
    return;
  }
  if (url.isEmpty || chave.isEmpty) {
    runApp(const CidadeInteligente(erroConfiguracao: true));
    return;
  }
  try {
    await Supabase.initialize(url: url, publishableKey: chave);
    runApp(CidadeInteligente(cliente: Supabase.instance.client));
  } catch (_) {
    runApp(const CidadeInteligente(erroConfiguracao: true));
  }
}

class CidadeInteligente extends StatelessWidget {
  const CidadeInteligente({
    super.key,
    this.cliente,
    this.erroConfiguracao = false,
  });

  final SupabaseClient? cliente;
  final bool erroConfiguracao;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cidade Inteligente',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1557A6)),
      ),
      home: erroConfiguracao
          ? const Scaffold(
              body: Center(
                child: Text(
                  'Confira a URL e a chave publicável do Supabase e reinicie o app.',
                ),
              ),
            )
          : _Sessao(cliente: cliente),
    );
  }
}

class _Sessao extends StatelessWidget {
  const _Sessao({required this.cliente});

  final SupabaseClient? cliente;

  @override
  Widget build(BuildContext context) {
    final cliente = this.cliente;
    if (cliente == null) return const TelaLogin();
    return StreamBuilder<AuthState>(
      stream: cliente.auth.onAuthStateChange,
      builder: (context, _) {
        final usuario = cliente.auth.currentSession?.user;
        if (usuario == null) return TelaLogin(cliente: cliente);
        final nome = usuario.userMetadata?['nome'];
        return PainelCidade(
          key: ValueKey(usuario.id),
          usuario: nome is String && nome.trim().isNotEmpty
              ? nome
              : usuario.email?.split('@').first ?? 'Usuário',
          repositorio: RepositorioPerfil(cliente, usuario.id),
          aoSair: () async {
            final avisos = ScaffoldMessenger.of(context);
            try {
              await cliente.auth.signOut();
            } catch (_) {
              if (avisos.mounted) {
                avisos.showSnackBar(
                  const SnackBar(
                    content: Text('Não foi possível sair. Tente novamente.'),
                  ),
                );
              }
            }
          },
        );
      },
    );
  }
}

class TelaLogin extends StatefulWidget {
  const TelaLogin({super.key, this.cliente});

  final SupabaseClient? cliente;

  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
  bool cadastro = false;
  bool mostrarSenha = false;
  bool enviando = false;

  final nome = TextEditingController();
  final email = TextEditingController();
  final senha = TextEditingController();
  final rolagem = ScrollController();

  @override
  void dispose() {
    nome.dispose();
    email.dispose();
    senha.dispose();
    rolagem.dispose();
    super.dispose();
  }

  void alternarTela() {
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).clearSnackBars();
    senha.clear();
    setState(() {
      cadastro = !cadastro;
      mostrarSenha = false;
    });
    if (rolagem.hasClients) rolagem.jumpTo(0);
  }

  InputDecoration campo(String texto, IconData icone) {
    return InputDecoration(
      labelText: texto,
      prefixIcon: Icon(icone, color: const Color(0xFF1557A6)),
      filled: true,
      fillColor: const Color(0xFFF5F8FC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE0E7F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF1557A6), width: 1.5),
      ),
    );
  }

  Future<void> enviar() async {
    if (enviando) return;
    if (email.text.trim().isEmpty || senha.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha o e-mail e a senha.')),
      );
      return;
    }

    if (cadastro && nome.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite seu nome completo.')),
      );
      return;
    }

    final endereco = email.text.trim();
    final usuario = cadastro ? nome.text.trim() : endereco.split('@').first;
    final cliente = widget.cliente;
    if (cliente != null) {
      if (cadastro && usuario.runes.length > 120) {
        _avisar('Use até 120 caracteres no nome.');
        return;
      }
      await _autenticar(cliente, endereco, usuario);
      return;
    }
    final navegador = Navigator.of(context);
    ScaffoldMessenger.of(context).clearSnackBars();
    navegador.pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => PainelCidade(
          usuario: usuario,
          aoSair: () => navegador.pushReplacement(
            MaterialPageRoute<void>(builder: (_) => const TelaLogin()),
          ),
        ),
      ),
    );
  }

  Future<void> _autenticar(
    SupabaseClient cliente,
    String endereco,
    String usuario,
  ) async {
    setState(() => enviando = true);
    try {
      if (cadastro) {
        final resposta = await cliente.auth.signUp(
          email: endereco,
          password: senha.text,
          data: {'nome': usuario},
        );
        if (mounted && resposta.session == null) {
          alternarTela();
          _avisar(
            'Confira seu e-mail para confirmar a conta. Depois, faça login.',
          );
        }
      } else {
        await cliente.auth.signInWithPassword(
          email: endereco,
          password: senha.text,
        );
      }
    } on AuthException catch (erro) {
      if (mounted) {
        _avisar(switch (erro.code) {
          'invalid_credentials' => 'E-mail ou senha inválidos.',
          'email_not_confirmed' =>
            'Confirme o endereço de e-mail para continuar.',
          'weak_password' =>
            'Escolha uma senha que atenda às regras do projeto.',
          'user_already_exists' => 'Já existe uma conta com esse e-mail.',
          'email_address_invalid' ||
          'validation_failed' => 'Confira o e-mail e a senha.',
          _ => 'Não foi possível autenticar. Confira seus dados e tente novamente.',
        });
      }
    } catch (_) {
      if (mounted) _avisar('Serviço indisponível. Tente novamente.');
    } finally {
      if (mounted) setState(() => enviando = false);
    }
  }

  void _avisar(String mensagem) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEAF3FF), Color(0xFFF7F9FC), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              controller: rolagem,
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Card(
                  elevation: 8,
                  shadowColor: const Color(0x331557A6),
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 82,
                          height: 82,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE7F0FF),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(
                            Icons.location_city_rounded,
                            size: 48,
                            color: Color(0xFF1557A6),
                          ),
                        ),

                        const SizedBox(height: 20),

                        const Text(
                          'Cidade Inteligente',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF17365D),
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          cadastro
                              ? 'Crie sua conta para começar'
                              : 'Bem-vindo de volta!',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF718096),
                          ),
                        ),
                        if (widget.cliente == null)
                          const Text('Modo demonstrativo'),

                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: enviando ? null : alternarTela,
                          icon: Icon(
                            cadastro ? Icons.arrow_back : Icons.person_add_alt,
                          ),
                          label: Text(cadastro ? 'Fazer login' : 'Cadastre-se'),
                        ),
                        const SizedBox(height: 12),

                        if (cadastro) ...[
                          TextField(
                            controller: nome,
                            decoration: campo(
                              'Nome completo',
                              Icons.person_outline,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        TextField(
                          controller: email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: campo('E-mail', Icons.email_outlined),
                        ),

                        const SizedBox(height: 16),

                        TextField(
                          controller: senha,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => enviar(),
                          obscureText: !mostrarSenha,
                          decoration: campo('Senha', Icons.lock_outline)
                              .copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    mostrarSenha
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      mostrarSenha = !mostrarSenha;
                                    });
                                  },
                                ),
                              ),
                        ),

                        const SizedBox(height: 26),

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: enviando ? null : enviar,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1557A6),
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              enviando
                                  ? 'Aguarde…'
                                  : cadastro
                                  ? 'Criar minha conta'
                                  : 'Entrar',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shield_outlined,
                              size: 16,
                              color: Color(0xFF718096),
                            ),
                            SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Cidade mais conectada, vida melhor',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF718096),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
