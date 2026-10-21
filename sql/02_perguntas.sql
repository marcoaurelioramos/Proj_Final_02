-- =============================================================================
-- PROJETO AVALIATIVO - MÓDULO 2 (PNCP 2025)
-- Arquivo: sql/02_perguntas.sql
-- Descrição: Consultas Analíticas para Resposta às Perguntas de Negócio
-- =============================================================================

-- =============================================================================
-- PERGUNTA 1: Panorama Geral de Contratações e Economia por Modalidade
-- Objetivo: Analisar o volume financeiro estimado, homologado, economia e deságio (%)
-- =============================================================================
SELECT 
    dmod.nome_modalidade,
    COUNT(fitem.id_fato) AS total_itens_homologados,
    SUM(fitem.valor_total_estimado) AS total_estimado_brl,
    SUM(fitem.valor_total_homologado) AS total_homologado_brl,
    SUM(fitem.valor_total_estimado - fitem.valor_total_homologado) AS economia_brl,
    ROUND(
        (SUM(fitem.valor_total_estimado - fitem.valor_total_homologado) / NULLIF(SUM(fitem.valor_total_estimado), 0)) * 100, 
        2
    ) AS pct_desagio
FROM fato_item_contratado fitem
JOIN dim_modalidade dmod ON fitem.sk_modalidade = dmod.sk_modalidade
WHERE fitem.comparavel = 1
GROUP BY dmod.nome_modalidade
ORDER BY total_homologado_brl DESC;


-- =============================================================================
-- PERGUNTA 2: Volume Homologado e Economia por Região e Estado (UF)
-- Objetivo: Mapear a distribuição geográfica dos gastos públicos e o percentual de deságio
-- =============================================================================
SELECT 
    dloc.uf_sigla AS uf,
    dloc.regiao,
    COUNT(fitem.id_fato) AS qtd_itens,
    SUM(fitem.valor_total_homologado) AS valor_total_homologado,
    ROUND(
        (SUM(fitem.valor_total_estimado - fitem.valor_total_homologado) / NULLIF(SUM(fitem.valor_total_estimado), 0)) * 100, 
        2
    ) AS pct_desagio_medio
FROM fato_item_contratado fitem
JOIN dim_localidade dloc ON fitem.sk_localidade = dloc.sk_localidade
WHERE fitem.comparavel = 1
GROUP BY dloc.uf_sigla, dloc.regiao
ORDER BY valor_total_homologado DESC;


-- =============================================================================
-- PERGUNTA 3: Top 10 Fornecedores por Volume Financeiro Homologado
-- Objetivo: Identificar os maiores recebedores de recursos públicos nas contratações
-- =============================================================================
SELECT 
    dfor.ni_fornecedor,
    dfor.nome_fornecedor AS razao_social,
    dfor.tipo_pessoa,
    COUNT(fitem.id_fato) AS total_itens_vencidos,
    SUM(fitem.valor_total_homologado) AS total_homologado
FROM fato_item_contratado fitem
JOIN dim_fornecedor dfor ON fitem.sk_fornecedor = dfor.sk_fornecedor
GROUP BY dfor.ni_fornecedor, dfor.nome_fornecedor, dfor.tipo_pessoa
ORDER BY total_homologado DESC
LIMIT 10;


-- =============================================================================
-- PERGUNTA 4: Tempo Médio de Ciclo (em Dias) por Órgão Comprador
-- Objetivo: Mensurar a eficiência processual dos órgãos com no mínimo 5 itens contratados
-- =============================================================================
SELECT 
    dorg.nome_orgao,
    COUNT(fitem.id_fato) AS total_itens,
    ROUND(AVG(fitem.dias_ciclo), 1) AS media_dias_ciclo,
    MIN(fitem.dias_ciclo) AS min_dias_ciclo,
    MAX(fitem.dias_ciclo) AS max_dias_ciclo
FROM fato_item_contratado fitem
JOIN dim_orgao dorg ON fitem.sk_orgao = dorg.sk_orgao
WHERE fitem.dias_ciclo IS NOT NULL
GROUP BY dorg.nome_orgao
HAVING COUNT(fitem.id_fato) >= 5
ORDER BY media_dias_ciclo ASC;


-- =============================================================================
-- PERGUNTA 5: Análise por Perfil do Gasto (Bens, Serviços, Obras)
-- Objetivo: Avaliar a alocação de recursos e economia obtida por tipo/perfil de gasto
-- =============================================================================
SELECT 
    fitem.perfil_gasto,
    COUNT(fitem.id_fato) AS qtd_itens,
    SUM(fitem.valor_total_estimado) AS total_estimado,
    SUM(fitem.valor_total_homologado) AS total_homologado,
    ROUND(
        (SUM(fitem.valor_total_estimado - fitem.valor_total_homologado) / NULLIF(SUM(fitem.valor_total_estimado), 0)) * 100, 
        2
    ) AS pct_desagio
FROM fato_item_contratado fitem
WHERE fitem.comparavel = 1
GROUP BY fitem.perfil_gasto
ORDER BY total_homologado DESC;