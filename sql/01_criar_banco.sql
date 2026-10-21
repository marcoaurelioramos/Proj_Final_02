-- =============================================================================
-- PROJETO AVALIATIVO - MÓDULO 2 (PNCP 2025)
-- Arquivo: sql/01_criar_banco.sql
-- =============================================================================

DROP TABLE IF EXISTS fato_item_contratado CASCADE;
DROP TABLE IF EXISTS dim_orgao CASCADE;
DROP TABLE IF EXISTS dim_fornecedor CASCADE;
DROP TABLE IF EXISTS dim_modalidade CASCADE;
DROP TABLE IF EXISTS dim_localidade CASCADE;

CREATE TABLE dim_orgao (
    sk_orgao INT PRIMARY KEY,
    cnpj_orgao VARCHAR(20) NOT NULL,
    nome_orgao VARCHAR(255) NOT NULL,
    poder VARCHAR(50)
);

CREATE TABLE dim_fornecedor (
    sk_fornecedor INT PRIMARY KEY,
    ni_fornecedor VARCHAR(20) NOT NULL,
    nome_fornecedor VARCHAR(255) NOT NULL,
    tipo_pessoa VARCHAR(20),
    porte VARCHAR(50)
);

CREATE TABLE dim_modalidade (
    sk_modalidade INT PRIMARY KEY,
    modalidade_id INT NOT NULL,
    nome_modalidade VARCHAR(100) NOT NULL
);

CREATE TABLE dim_localidade (
    sk_localidade INT PRIMARY KEY,
    uf_sigla VARCHAR(10) NOT NULL,
    uf_nome VARCHAR(100),
    regiao VARCHAR(20) NOT NULL
);

CREATE TABLE fato_item_contratado (
    id_fato BIGSERIAL PRIMARY KEY,
    numero_controle_pncp VARCHAR(100) NOT NULL,
    numero_item INT NOT NULL,
    sk_orgao INT NOT NULL REFERENCES dim_orgao(sk_orgao),
    sk_fornecedor INT NOT NULL REFERENCES dim_fornecedor(sk_fornecedor),
    sk_modalidade INT NOT NULL REFERENCES dim_modalidade(sk_modalidade),
    sk_localidade INT NOT NULL REFERENCES dim_localidade(sk_localidade),
    data_publicacao DATE,
    data_homologacao DATE,
    descricao_item TEXT,
    perfil_gasto VARCHAR(100),
    quantidade NUMERIC(15, 4),
    valor_unitario_estimado NUMERIC(15, 2),
    valor_total_estimado NUMERIC(15, 2),
    valor_unitario_homologado NUMERIC(15, 2),
    valor_total_homologado NUMERIC(15, 2),
    comparavel SMALLINT,
    economia_valor NUMERIC(15, 2),
    dias_ciclo INT
);

CREATE INDEX idx_fato_orgao ON fato_item_contratado(sk_orgao);
CREATE INDEX idx_fato_fornecedor ON fato_item_contratado(sk_fornecedor);
CREATE INDEX idx_fato_modalidade ON fato_item_contratado(sk_modalidade);
CREATE INDEX idx_fato_localidade ON fato_item_contratado(sk_localidade);
CREATE INDEX idx_fato_comparavel ON fato_item_contratado(comparavel);