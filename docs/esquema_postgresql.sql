-- Execute uma vez no banco PostgreSQL em que o PostGIS está habilitado.
BEGIN;

CREATE SCHEMA IF NOT EXISTS cidade_inteligente;
SET LOCAL search_path = cidade_inteligente, extensions, public;

CREATE TABLE cidade_inteligente.usuarios (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome text NOT NULL CHECK (btrim(nome) <> ''),
    email text NOT NULL CHECK (btrim(email) <> ''),
    senha_hash text NOT NULL,
    tipo text NOT NULL DEFAULT 'cidadao'
        CHECK (tipo IN ('cidadao', 'gestor', 'administrador')),
    cidade text,
    ponto_cidade geometry(Point, 4326),
    criado_em timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX usuarios_email_unico ON cidade_inteligente.usuarios (lower(btrim(email)));

CREATE TABLE cidade_inteligente.classificacoes_risco (
    id smallint PRIMARY KEY,
    nivel text NOT NULL UNIQUE,
    CHECK ((id, nivel) IN ((1, 'baixo'), (2, 'medio'), (3, 'alto'), (4, 'muito_alto')))
);

INSERT INTO cidade_inteligente.classificacoes_risco (id, nivel)
VALUES (1, 'baixo'), (2, 'medio'), (3, 'alto'), (4, 'muito_alto');

CREATE TABLE cidade_inteligente.areas_risco (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome text NOT NULL CHECK (btrim(nome) <> ''),
    descricao text,
    endereco_referencia text,
    municipio text NOT NULL CHECK (btrim(municipio) <> ''),
    geometria geometry(MultiPolygon, 4326) NOT NULL,
    classificacao_id smallint REFERENCES cidade_inteligente.classificacoes_risco (id),
    status text NOT NULL DEFAULT 'rascunho'
        CHECK (status IN ('rascunho', 'publicada', 'arquivada')),
    criado_por bigint NOT NULL REFERENCES cidade_inteligente.usuarios (id),
    criado_em timestamptz NOT NULL DEFAULT now(),
    CHECK (NOT ST_IsEmpty(geometria) AND ST_IsValid(geometria)),
    CHECK (status <> 'publicada' OR classificacao_id IS NOT NULL)
);

CREATE INDEX areas_risco_geometria_idx ON cidade_inteligente.areas_risco USING gist (geometria);
CREATE INDEX areas_risco_classificacao_idx ON cidade_inteligente.areas_risco (classificacao_id);

CREATE TABLE cidade_inteligente.informacoes_risco (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    area_id bigint NOT NULL REFERENCES cidade_inteligente.areas_risco (id),
    tipo_perigo text NOT NULL CHECK (btrim(tipo_perigo) <> ''),
    descricao text NOT NULL CHECK (btrim(descricao) <> '')
);

CREATE TABLE cidade_inteligente.orientacoes (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    area_id bigint REFERENCES cidade_inteligente.areas_risco (id),
    titulo text NOT NULL CHECK (btrim(titulo) <> ''),
    texto text NOT NULL CHECK (btrim(texto) <> '')
);

CREATE TABLE cidade_inteligente.ocorrencias_chuva (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    area_id bigint NOT NULL REFERENCES cidade_inteligente.areas_risco (id),
    ocorreu_em timestamptz NOT NULL,
    intensidade text,
    precipitacao_mm numeric(8, 2) CHECK (precipitacao_mm >= 0),
    descricao text
);

CREATE TABLE cidade_inteligente.alertas (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    area_id bigint NOT NULL REFERENCES cidade_inteligente.areas_risco (id),
    classificacao_id smallint NOT NULL REFERENCES cidade_inteligente.classificacoes_risco (id),
    mensagem text NOT NULL CHECK (btrim(mensagem) <> ''),
    emitido_em timestamptz NOT NULL DEFAULT now(),
    encerra_em timestamptz,
    CHECK (encerra_em IS NULL OR encerra_em > emitido_em)
);

CREATE TABLE cidade_inteligente.auditoria_areas_risco (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    area_id bigint NOT NULL REFERENCES cidade_inteligente.areas_risco (id),
    usuario_id bigint NOT NULL REFERENCES cidade_inteligente.usuarios (id),
    operacao text NOT NULL
        CHECK (operacao IN ('cadastro', 'atualizacao', 'publicacao', 'arquivamento')),
    registrado_em timestamptz NOT NULL DEFAULT now(),
    dados_anteriores jsonb,
    dados_novos jsonb
);

CREATE INDEX auditoria_areas_risco_area_data_idx
    ON cidade_inteligente.auditoria_areas_risco (area_id, registrado_em DESC);

ALTER TABLE cidade_inteligente.usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE cidade_inteligente.classificacoes_risco ENABLE ROW LEVEL SECURITY;
ALTER TABLE cidade_inteligente.areas_risco ENABLE ROW LEVEL SECURITY;
ALTER TABLE cidade_inteligente.informacoes_risco ENABLE ROW LEVEL SECURITY;
ALTER TABLE cidade_inteligente.orientacoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE cidade_inteligente.ocorrencias_chuva ENABLE ROW LEVEL SECURITY;
ALTER TABLE cidade_inteligente.alertas ENABLE ROW LEVEL SECURITY;
ALTER TABLE cidade_inteligente.auditoria_areas_risco ENABLE ROW LEVEL SECURITY;

COMMIT;

SELECT tablename, rowsecurity AS rls_ativo
FROM pg_catalog.pg_tables
WHERE schemaname = 'cidade_inteligente'
ORDER BY tablename;
