import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'previsao.dart';

typedef DadosPerfil = ({String nome, Cidade? cidade});

class RepositorioPerfil {
  const RepositorioPerfil(this.cliente, this.usuarioId);

  final SupabaseClient cliente;
  final String usuarioId;

  Future<DadosPerfil?> carregar() async {
    final dados = await cliente
        .from('perfis')
        .select('nome, cidade, latitude, longitude')
        .eq('id', usuarioId)
        .maybeSingle();
    if (dados == null) return null;
    final cidade = dados['cidade'] as String?;
    return (
      nome: dados['nome'] as String,
      cidade: cidade == null
          ? null
          : (
              nome: cidade,
              ponto: LatLng(
                (dados['latitude'] as num).toDouble(),
                (dados['longitude'] as num).toDouble(),
              ),
            ),
    );
  }

  Future<void> salvar(String nome, Cidade? cidade) async {
    await cliente.from('perfis').upsert({
      'id': usuarioId,
      'nome': nome,
      'cidade': cidade?.nome,
      'latitude': cidade?.ponto.latitude,
      'longitude': cidade?.ponto.longitude,
    });
  }
}
