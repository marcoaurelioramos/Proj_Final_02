-- Esquema do banco PNCP Controladoria
-- Baseado nas colunas e nos valores dos CSVs da pasta processed.
-- ni_fornecedor aceita identificadores com até 30 caracteres.
-- comparavel é SMALLINT (0/1), conforme os valores presentes no CSV.

CREATE TABLE IF NOT EXISTS dim_orgao (
    sk_orgao INTEGER PRIMARY KEY,
    cnpj_orgao VARCHAR(14),
    nome_orgao VARCHAR(255) NOT NULL,
    poder VARCHAR(30)
);

CREATE TABLE IF NOT EXISTS dim_fornecedor (
    sk_fornecedor INTEGER PRIMARY KEY,
    ni_fornecedor VARCHAR(30),
    nome_fornecedor VARCHAR(255) NOT NULL,
    tipo_pessoa VARCHAR(20),
    porte VARCHAR(30)
);

CREATE TABLE IF NOT EXISTS dim_modalidade (
    sk_modalidade INTEGER PRIMARY KEY,
    modalidade_id INTEGER,
    nome_modalidade VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS dim_localidade (
    sk_localidade INTEGER PRIMARY KEY,
    uf_sigla VARCHAR(2) NOT NULL,
    uf_nome VARCHAR(50) NOT NULL,
    regiao VARCHAR(30)
);

CREATE TABLE IF NOT EXISTS fato_item_contratado (
    numero_controle_pncp VARCHAR(40) NOT NULL,
    numero_item INTEGER NOT NULL,
    sk_orgao INTEGER NOT NULL,
    sk_fornecedor INTEGER NOT NULL,
    sk_modalidade INTEGER NOT NULL,
    sk_localidade INTEGER NOT NULL,
    data_publicacao DATE,
    data_homologacao DATE,
    descricao_item TEXT,
    perfil_gasto VARCHAR(30),
    quantidade NUMERIC(20,4),
    valor_unitario_estimado NUMERIC(20,4),
    valor_total_estimado NUMERIC(20,4),
    valor_unitario_homologado NUMERIC(20,4),
    valor_total_homologado NUMERIC(20,4),
    comparavel SMALLINT NOT NULL CHECK (comparavel IN (0, 1)),
    economia_valor NUMERIC(20,4),
    dias_ciclo NUMERIC(10,2),
    CONSTRAINT pk_fato_item_contratado
        PRIMARY KEY (numero_controle_pncp, numero_item),
    CONSTRAINT fk_fato_orgao
        FOREIGN KEY (sk_orgao) REFERENCES dim_orgao (sk_orgao),
    CONSTRAINT fk_fato_fornecedor
        FOREIGN KEY (sk_fornecedor) REFERENCES dim_fornecedor (sk_fornecedor),
    CONSTRAINT fk_fato_modalidade
        FOREIGN KEY (sk_modalidade) REFERENCES dim_modalidade (sk_modalidade),
    CONSTRAINT fk_fato_localidade
        FOREIGN KEY (sk_localidade) REFERENCES dim_localidade (sk_localidade)
);
