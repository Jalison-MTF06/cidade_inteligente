
import 'package:flutter/material.dart';

void main() {
  runApp(const CidadeInteligente());
}

class CidadeInteligente extends StatelessWidget {
  const CidadeInteligente({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cidade Inteligente',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1557A6),
        ),
      ),
      home: const TelaLogin(),
    );
  }
}

class TelaLogin extends StatefulWidget {
  const TelaLogin({super.key});

  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
  bool cadastro = false;
  bool mostrarSenha = false;

  final nome = TextEditingController();
  final email = TextEditingController();
  final senha = TextEditingController();

  @override
  void dispose() {
    nome.dispose();
    email.dispose();
    senha.dispose();
    super.dispose();
  }

  void alternarTela() {
    setState(() {
      cadastro = !cadastro;
    });
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
        borderSide: const BorderSide(
          color: Color(0xFF1557A6),
          width: 1.5,
        ),
      ),
    );
  }

  void enviar() {
    if (email.text.trim().isEmpty || senha.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha o e-mail e a senha.'),
        ),
      );
      return;
    }

    if (cadastro && nome.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite seu nome completo.'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          cadastro
              ? 'Cadastro demonstrativo realizado!'
              : 'Tela de login funcionando!',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFEAF3FF),
              Color(0xFFF7F9FC),
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
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

                        const SizedBox(height: 30),

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
                          decoration: campo(
                            'E-mail',
                            Icons.email_outlined,
                          ),
                        ),

                        const SizedBox(height: 16),

                        TextField(
                          controller: senha,
                          obscureText: !mostrarSenha,
                          decoration: campo(
                            'Senha',
                            Icons.lock_outline,
                          ).copyWith(
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
                            onPressed: enviar,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1557A6),
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              cadastro ? 'Criar minha conta' : 'Entrar',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 22),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                cadastro
                                    ? 'Já tem uma conta?'
                                    : 'Ainda não tem uma conta?',
                                style: const TextStyle(
                                  color: Color(0xFF718096),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: alternarTela,
                              child: Text(
                                cadastro ? 'Fazer login' : 'Cadastre-se',
                                style: const TextStyle(
                                  color: Color(0xFF1557A6),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shield_outlined,
                              size: 16,
                              color: Color(0xFF718096),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Cidade mais conectada, vida melhor',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF718096),
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
