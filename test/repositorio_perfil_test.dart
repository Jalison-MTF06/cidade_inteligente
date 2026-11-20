import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:cidade_inteligente/repositorio_perfil.dart';

void main() {
  test(
    'recupera a cidade do perfil e salva o nome para a mesma conta',
    () async {
      const id = 'f5b88c3c-a95a-4e63-8cb2-70463588e204';
      final requisicoes = <http.Request>[];
      final transporte = MockClient((requisicao) async {
        requisicoes.add(requisicao);
        return switch (requisicao.method) {
          'GET' => http.Response(
            jsonEncode([
              {
                'nome': 'Pessoa Teste',
                'cidade': 'Recife',
                'latitude': -8.05,
                'longitude': -34.88,
              },
            ]),
            200,
            headers: {'content-type': 'application/json'},
          ),
          'POST' => http.Response('', 201),
          _ => http.Response('', 405),
        };
      });
      final cliente = SupabaseClient(
        'https://exemplo.invalid',
        'chave-publicavel-de-teste',
        httpClient: transporte,
      );
      addTearDown(cliente.dispose);
      final repositorio = RepositorioPerfil(cliente, id);

      final perfil = (await repositorio.carregar())!;
      expect(perfil.nome, 'Pessoa Teste');
      expect(perfil.cidade?.nome, 'Recife');
      expect(perfil.cidade?.ponto.latitude, -8.05);
      expect(requisicoes.first.url.path, '/rest/v1/perfis');
      expect(requisicoes.first.url.queryParameters['id'], 'eq.$id');

      await repositorio.salvar('Novo nome', perfil.cidade);
      expect(requisicoes.last.url.path, '/rest/v1/perfis');
      expect(jsonDecode(requisicoes.last.body), {
        'id': id,
        'nome': 'Novo nome',
        'cidade': 'Recife',
        'latitude': -8.05,
        'longitude': -34.88,
      });
      expect(
        requisicoes.last.headers['prefer'],
        contains('resolution=merge-duplicates'),
      );
    },
  );
}
