"""banco.py - conexao e utilitarios do PostgreSQL.

Usa Psycopg 3 (pacote `psycopg`) e define WIN1252 explicitamente para a
conexao, conforme validado no ambiente Windows deste projeto.
"""

import re

import psycopg
from psycopg import Error, sql

from src import config


def conectar(database=None):
    """Abre a conexao no banco do projeto (ou em 'database', se informado)."""
    try:
        db_name = database or config.PG_DATABASE
        return psycopg.connect(
            dbname=db_name,
            user=config.PG_CONFIG["user"],
            password=config.PG_CONFIG["password"],
            host=config.PG_CONFIG["host"],
            port=config.PG_CONFIG["port"],
            client_encoding="UTF8",
        )
    except Error as erro:
        raise RuntimeError(
            f"Nao foi possivel conectar ao PostgreSQL em "
            f"{config.PG_CONFIG['host']}:{config.PG_CONFIG['port']}. "
            f"Confira o arquivo .env e se o servico esta no ar. Detalhe: {erro}"
        ) from erro


def recriar_banco():
    """Apaga e recria o banco do projeto conectando ao banco administrativo postgres."""
    con = conectar("postgres")
    try:
        con.autocommit = True
        with con.cursor() as cur:
            nome = sql.Identifier(config.PG_DATABASE)
            # Encerra outras sessoes para permitir o DROP DATABASE.
            cur.execute(
                "SELECT pg_terminate_backend(pid) "
                "FROM pg_stat_activity "
                "WHERE datname = %s AND pid <> pg_backend_pid()",
                (config.PG_DATABASE,),
            )
            cur.execute(sql.SQL("DROP DATABASE IF EXISTS {}").format(nome))
            cur.execute(
                sql.SQL("CREATE DATABASE {} ENCODING 'UTF8' TEMPLATE template0").format(nome)
            )
    finally:
        con.close()


def _separar_comandos(texto):
    """Separa comandos SQL simples por ';' e remove comentarios '--'."""
    sem_comentarios = re.sub(r"--[^\n]*", "", texto)
    return [comando.strip() for comando in sem_comentarios.split(";") if comando.strip()]


def executar_script(conexao, caminho):
    with conexao.cursor() as cursor:
        for comando in _separar_comandos(caminho.read_text(encoding="utf-8")):
            cursor.execute(comando)
    conexao.commit()


def executar(conexao, comando, params=None):
    with conexao.cursor() as cursor:
        cursor.execute(comando, params)
    conexao.commit()


def consultar(conexao, comando, params=None):
    """Executa SELECT e devolve uma lista de tuplas."""
    with conexao.cursor() as cursor:
        cursor.execute(comando, params)
        return cursor.fetchall()


def inserir_em_lote(conexao, sql_insert, linhas):
    """Insere varias linhas usando executemany do Psycopg 3."""
    if not linhas:
        return
    with conexao.cursor() as cursor:
        cursor.executemany(sql_insert, linhas)
    conexao.commit()
