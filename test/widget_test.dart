import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cidade_inteligente/main.dart';

/// Abre a aplicação exatamente como ela é iniciada no projeto.
Future<void> abrirAplicativo(WidgetTester tester) async {
  await tester.pumpWidget(const CidadeInteligente());
  await tester.pumpAndSettle();
}

void main() {
  group('Caracterização da tela de login e cadastro', () {
    testWidgets('exibe a tela de login inicialmente', (tester) async {
      await abrirAplicativo(tester);

      expect(find.text('Cidade Inteligente'), findsOneWidget);
      expect(find.text('Bem-vindo de volta!'), findsOneWidget);
      expect(find.text('Entrar'), findsOneWidget);
      expect(find.text('Cadastre-se'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('mostra aviso quando e-mail e senha estão vazios',
        (tester) async {
      await abrirAplicativo(tester);

      await tester.tap(find.text('Entrar'));
      await tester.pump();

      expect(find.text('Preencha o e-mail e a senha.'), findsOneWidget);
    });

    testWidgets('mostra mensagem demonstrativa ao preencher login',
        (tester) async {
      await abrirAplicativo(tester);

      await tester.enterText(find.byType(TextField).at(0), 'teste@email.com');
      await tester.enterText(find.byType(TextField).at(1), 'senha123');
      await tester.tap(find.text('Entrar'));
      await tester.pump();

      expect(find.text('Tela de login funcionando!'), findsOneWidget);
    });

    testWidgets('permite alternar da tela de login para cadastro',
        (tester) async {
      await abrirAplicativo(tester);

      await tester.tap(find.text('Cadastre-se'));
      await tester.pumpAndSettle();

      expect(find.text('Crie sua conta para começar'), findsOneWidget);
      expect(find.text('Nome completo'), findsOneWidget);
      expect(find.text('Criar minha conta'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(3));
    });

    testWidgets('exige nome completo no cadastro', (tester) async {
      await abrirAplicativo(tester);

      await tester.tap(find.text('Cadastre-se'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(1), 'teste@email.com');
      await tester.enterText(find.byType(TextField).at(2), 'senha123');
      await tester.tap(find.text('Criar minha conta'));
      await tester.pump();

      expect(find.text('Digite seu nome completo.'), findsOneWidget);
    });

    testWidgets('mostra mensagem demonstrativa após preencher cadastro',
        (tester) async {
      await abrirAplicativo(tester);

      await tester.tap(find.text('Cadastre-se'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'Pessoa Teste');
      await tester.enterText(find.byType(TextField).at(1), 'teste@email.com');
      await tester.enterText(find.byType(TextField).at(2), 'senha123');
      await tester.tap(find.text('Criar minha conta'));
      await tester.pump();

      expect(find.text('Cadastro demonstrativo realizado!'), findsOneWidget);
    });

    testWidgets('alterna a visibilidade da senha', (tester) async {
      await abrirAplicativo(tester);

      final campoSenha = find.byType(TextField).at(1);
      expect(tester.widget<TextField>(campoSenha).obscureText, isTrue);

      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pump();

      expect(tester.widget<TextField>(campoSenha).obscureText, isFalse);
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });

    testWidgets('permite voltar do cadastro para o login', (tester) async {
      await abrirAplicativo(tester);

      await tester.tap(find.text('Cadastre-se'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fazer login'));
      await tester.pumpAndSettle();

      expect(find.text('Bem-vindo de volta!'), findsOneWidget);
      expect(find.text('Entrar'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));
    });
  });
}
