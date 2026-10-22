# Projeto Final 02: Análise de Compras Públicas (PNCP)

Este repositório contém a solução desenvolvida para o **Projeto Final 02**, focado no processamento, tratamento, modelagem dimensional e análise analítica de dados de compras públicas extraídos do Portal Nacional de Contratações Públicas (**PNCP**).

---

## Sumário

1. Visão Geral e Objetivos
2. Técnicas e Tecnologias Utilizadas
3. Dicionário de Inconsistências Tratadas
4. Arquitetura e Fluxo ETL
5. Modelo Dimensional (Star Schema)
6. Gestão do Projeto e Sprints
7. Estrutura do Repositório
8. Instruções de Execução
9. Consultas Analíticas (SQL)

---

## Visão Geral e Objetivos

O objetivo principal deste projeto é transformar dados brutos de licitações e compras governamentais em uma base estruturada e higienizada, permitindo auditabilidade, cálculo de economia gerada e análise de desempenho de contratações públicas.

### Principais Entregas:
* **Tratamento e Sanitização de Dados:** Remoção de anomalias, tratamento de nulos, padronização de CNPJ/CPF e limpeza de caracteres especiais.
* **Modelagem Dimensional (Star Schema):** Estruturação de 1 Tabela Fato (`fato_item_contratado`) e 4 Tabelas Dimensão (`dim_orgao`, `dim_fornecedor`, `dim_modalidade`, `dim_localidade`).
* **Validação de Regras de Auditoria:** Aplicação do critério de comparabilidade com paridade total ao gabarito do Anexo 8.
* **Carga em Banco de Dados Relacional:** Ingestão automatizada no PostgreSQL.

---

## Técnicas e Tecnologias Utilizadas

Para garantir performance, rastreabilidade e boas práticas de engenharia de dados, foram empregadas as seguintes ferramentas e conceitos:

* **Linguagem de Programação:** Python 3.10+
* **Manipulação e Análise de Dados:** `Pandas` e `NumPy`
* **Banco de Dados Relacional:** `PostgreSQL`
* **Conectividade e ORM:** `SQLAlchemy` e `psycopg2-binary`
* **Modelagem Dimensional:** Modelagem Star Schema (Tabela Fato, Tabelas Dimensão, Surrogate Keys - SKs)
* **Design Patterns & Boas Práticas:** Estrutura modular em scripts Python (`config`, `limpeza`, `montar_tabelas`, `carregar`)
* **Gestão Ágil de Projeto:** Metodologia Scrum/Kanban utilizando o `Trello`
* **Controle de Versão:** `Git` e `GitHub`

---

## Dicionário de Inconsistências Tratadas

Durante o processo de limpeza e higienização dos dados brutos (`itens.csv`, `resultados.csv`, `compras.csv`), foram identificadas e corrigidas as seguintes anomalias de dados:

**Identificação de Pessoa (`ni_fornecedor`, `cnpj_orgao`)** - Presença de pontuações (`.`, `-`, `/`), espaços e máscaras irregulares de CPF/CNPJ. Aplicação de regex para manter apenas números (`\D`) e formatação/preenchimento de zeros à esquerda (14 dígitos para PJ e 11 para PF).
**Duplicidade por Nomes (`nome_orgao`, `nome_fornecedor`)** - Maíusculas e minúsculas, espaços múltiplos e acentuação incorreta gerando registros duplicados. Padronização via `unidecode`, remoção de pontuações, conversão para MAIÚSCULAS e eliminação de espaços.
**Registros Multiplicados em Merges (`numero_controle_pncp` + `numero_item`)** - Múltiplos resultados de propostas e histórico de cancelamento por item geravam multiplicação de linhas no JOIN. Descarte de resultados cancelados (`data_cancelamento` preenchida) e deduplicação estrita (`drop_duplicates`) mantendo a chave única do item.
**Valores Financeiros e Quantidades** - Caracteres de moeda (`R$`), vírgulas como separador decimal e valores nulos ou zerados. Conversão para tipo float numérico, substituição de vírgula por ponto e recálculo do valor total multiplicando a quantidade pelo valor unitário quando o total estava ausente.
**Outliers e Erros de Digitação Financeira** - Itens com divergência entre valor estimado e homologado. Filtro do indicador de `comparavel` mantendo apenas itens na faixa de razão $0,10 - 10,0$ e descarte de modalidades como Credenciamento.
**Mapeamento de Datas e Tempo de Ciclo (`dias_ciclo`)** - Inconsistências em formatos de data e presenças de *timestamps* sem padronização. Conversão unificada para `YYYY-MM-DD` e cálculo de `dias_ciclo = data_homologacao - data_publicacao`. |

---

## Arquitetura e Fluxo ETL

O pipeline de dados foi desenvolvido modularmente em Python utilizando a biblioteca **Pandas**:

1. **Extração (`data/raw/`):** Leitura dos arquivos CSV brutos (`compras.csv`, `itens.csv`, `resultados.csv`).
2. **Transformação (`src/limpeza.py` e `src/montar_tabelas.py`):**
   * Limpeza e padronização de textos e documentos.
   * Conversão de valores monetários e numéricos.
   * Cálculo de campos derivados: tempo de ciclo (`dias_ciclo`), perfil de gasto e indicadores de comparabilidade.
   * Deduplicação rigorosa baseada na chave unívoca do PNCP.
3. **Carga (`src/carregar.py`):** Conexão via SQLAlchemy/psycopg2 para inserção dos dados estruturados no banco PostgreSQL (`data/processed/`).

---

## Modelo Dimensional (Star Schema)

A modelagem dimensional foi projetada no formato **Estrela (*Star Schema*)**, garantindo alta performance em consultas analíticas e simplificação do modelo de dados.

### Diagrama da Modelagem Dimensional

[Diagrama da Modelagem Dimensional](docs/img/Esquema_Relacionamentos.jpg)

### Estrutura das Tabelas:

* **`fato_item_contratado`**: Armazena os eventos de compras, quantidades, valores estimados e homologados, indicador de comparabilidade, métricas de economia e as chaves substitutas.
* **`dim_orgao`**: Dados dos órgãos compradores, CNPJ limpo e esferas de poder (363 registros).
* **`dim_fornecedor`**: Informações dos fornecedores vencedores (CPF/CNPJ, razão social, porte e tipo de pessoa - 2.652 registros).
* **`dim_modalidade`**: Modalidades de contratação pública (7 registros).
* **`dim_localidade`**: Unidades federativas e agrupamento por regiões geográficas do Brasil (27 registros).

---

## Gestão do Projeto e Sprints

O projeto foi gerenciado utilizando a metodologia ágil **Scrum/Kanban** no Trello, dividido em sprints focadas em entregas incrementais.

### Quadro de Acompanhamento (Trello)

[Quadro de Sprints no Trello](docs/img/sprints.png)

---

## Estrutura do Repositório

```
Proj_Final_02/
─ data/
   ─ raw/                 # Arquivos CSV brutos recebidos
   ─ processed/           # Arquivos CSV tratados e gerados pelo ETL
─ docs/
   ─ img/                 # Diagramas, esquemas e imagens da documentação
       ─ Esquema_Relacionamentos.jpg
       ─ sprints.png
─ sql/
   ─ 01_esquema.sql       # Script de criação das tabelas no PostgreSQL
   ─ 02_perguntas.sql     # Script com as consultas SQL analíticas
─ src/
   ─ __init__.py
   ─ config.py            # Configurações de caminhos e conexão DB
   ─ limpeza.py           # Funções auxiliares de higienização de dados
   ─ montar_tabelas.py    # Pipeline ETL de transformação dos dados
   ─ carregar.py          # Script de carga e validação no PostgreSQL
─ .gitignore
─ README.md                # Documentação principal do projeto
─ requirements.txt         # Dependências do projeto Python
```

---

## Instruções de Execução

### 1. Pré-requisitos
* Python 3.10+
* PostgreSQL instalado e em execução
* DBeaver ou pgAdmin (opcional)

### 2. Instalação das Dependências
```bash
pip install -r requirements.txt
```

### 3. Execução do Pipeline ETL

**1: Processamento e Tratamento dos Dados**
```bash
py -m src.montar_tabelas
```

**2: Carga no Banco de Dados PostgreSQL e Validação**
```bash
py -m src.carregar
```

---

## Consultas Analíticas (SQL)

Após a execução da carga, o script `sql/02_perguntas.sql` pode ser executado no PostgreSQL para responder às questões estratégicas da controladoria, cobrindo:

1. Total de compras homologadas por modalidade.
2. Economia gerada (R$) por região do país.
3. Top fornecedores com maior volume financeiro homologado.
4. Tempo médio de ciclo das contratações públicas por perfil de gasto.

---
