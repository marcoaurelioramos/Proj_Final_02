"""
carregar.py - CARGA E AUDITORIA NO POSTGRESQL
=========================================================================
1) Recria o banco e as tabelas (01_criar_banco.sql)
2) Carrega as 4 dimensões
3) Carrega a Fato
4) Valida a Prova Real (Anexo 8)

COMO RODAR: python -m src.carregar
"""

import pandas as pd
from src import banco, config


def ler(nome, **opcoes):
    """Lê um CSV da pasta data/processed."""
    return pd.read_csv(config.PASTA_PROCESSED / f"{nome}.csv", keep_default_na=False, na_values=[""], **opcoes)


def tuplas(tabela, colunas):
    """Transforma o DataFrame em uma lista de tuplas para inserção SQL."""
    dados = tabela[colunas].astype(object)
    dados = dados.where(dados.notna(), None)
    return [tuple(linha) for linha in dados.itertuples(index=False, name=None)]


def inserir(con, tabela, colunas_csv, colunas_banco, dados):
    """Monta o INSERT INTO ... VALUES (%s, %s, ...) e envia em lote."""
    marcadores = ", ".join(["%s"] * len(colunas_banco))
    sql = f"INSERT INTO {tabela} ({', '.join(colunas_banco)}) VALUES ({marcadores})"
    banco.inserir_em_lote(con, sql, tuplas(dados, colunas_csv))
    print(f"   {tabela}: {len(dados)} linhas")


def main():
    # 1) Banco e tabelas
    banco.recriar_banco()
    con = banco.conectar()
    banco.executar_script(con, config.PASTA_SQL / "01_criar_banco.sql")

    # 2) Carga das Dimensões
    print("Carga das Dimensões:")
    dimensoes = [
        ("dim_orgao", ["sk_orgao", "cnpj_orgao", "nome_orgao", "poder"], ["sk_orgao", "cnpj_orgao", "nome_orgao", "poder"]),
        ("dim_fornecedor", ["sk_fornecedor", "ni_fornecedor", "nome_fornecedor", "tipo_pessoa", "porte"], ["sk_fornecedor", "ni_fornecedor", "nome_fornecedor", "tipo_pessoa", "porte"]),
        ("dim_modalidade", ["sk_modalidade", "modalidade_id", "nome_modalidade"], ["sk_modalidade", "modalidade_id", "nome_modalidade"]),
        ("dim_localidade", ["sk_localidade", "uf_sigla", "uf_nome", "regiao"], ["sk_localidade", "uf_sigla", "uf_nome", "regiao"])
    ]

    for nome, colunas_csv, colunas_banco in dimensoes:
        inserir(con, nome, colunas_csv, colunas_banco, ler(nome, dtype=str))

    # 3) Carga da Fato
    print("\nCarga da Fato:")
    fato = ler("fato_item_contratado")
    if "dias_ciclo" in fato.columns:
        fato["dias_ciclo"] = pd.to_numeric(fato["dias_ciclo"], errors="coerce").astype("Int64")

    colunas_fato = [
        "numero_controle_pncp", "numero_item", "sk_orgao", "sk_fornecedor", "sk_modalidade", "sk_localidade",
        "data_publicacao", "data_homologacao", "descricao_item", "perfil_gasto", "quantidade",
        "valor_unitario_estimado", "valor_total_estimado", "valor_unitario_homologado", "valor_total_homologado",
        "comparavel", "economia_valor", "dias_ciclo"
    ]

    inserir(con, "fato_item_contratado", colunas_fato, colunas_fato, fato)
    con.commit()

    # 4) Conferência com a Prova Real (Anexo 8)
    print("\nConferência da Auditoria (Anexo 8):")
    for tabela, esperado in [
        ("fato_item_contratado", 6126),
        ("dim_orgao", 363),
        ("dim_fornecedor", 2652),
        ("dim_modalidade", 7),
        ("dim_localidade", 27)
    ]:
        n = banco.consultar(con, f"SELECT COUNT(*) FROM {tabela}")[0][0]
        print(f"   {tabela}: {n} (esperado {esperado}) -> {'OK' if n == esperado else 'DIVERGENTE'}")

    # Validação detalhada de comparabilidade
    comp_1 = banco.consultar(con, "SELECT COUNT(*) FROM fato_item_contratado WHERE comparavel = 1")[0][0]
    comp_0 = banco.consultar(con, "SELECT COUNT(*) FROM fato_item_contratado WHERE comparavel = 0")[0][0]

    print(f"   comparavel = 1: {comp_1} (esperado 5193) -> {'OK' if comp_1 == 5193 else 'DIVERGENTE'}")
    print(f"   comparavel = 0: {comp_0} (esperado 933) -> {'OK' if comp_0 == 933 else 'DIVERGENTE'}")

    con.close()


if __name__ == "__main__":
    main()