USE VAREJO_DW;

-- 1. Quantidade de vendas agrupada por tipo e categoria
SELECT
    dp.tipo,
    dp.categoria,
    SUM(fv.quantidade) AS quantidade_vendas
FROM
    fact_vendas fv
    JOIN dim_produto dp ON fv.produto_id = dp.produto_id
GROUP BY
    dp.tipo,
    dp.categoria;

-- 2. Valor das vendas por funcionário, permitindo uma visão hierárquica por tempo
SELECT
    df.nome,
    dt.ano,
    dt.mes,
    SUM(fv.valor_total) AS valor_vendas
FROM
    fact_vendas fv
    JOIN dim_funcionario df ON fv.funcionario_id = df.funcionario_id
    JOIN dim_tempo dt ON fv.tempo_id = dt.tempo_id
GROUP BY
    df.nome,
    dt.ano,
    dt.mes
ORDER BY
    df.nome,
    dt.ano,
    dt.mes;

-- 3. Volume das vendas por funcionário, permitindo uma visão por localidade
SELECT
    df.nome,
    dl.uf,
    dl.cidade,
    SUM(fv.quantidade) AS volume_vendas
FROM
    fact_vendas fv
    JOIN dim_funcionario df ON fv.funcionario_id = df.funcionario_id
    JOIN dim_localidade dl ON fv.localidade_id = dl.localidade_id
GROUP BY
    df.nome,
    dl.uf,
    dl.cidade
ORDER BY
    df.nome;

-- 4. Quantidade de atendimentos realizados por funcionário e localidade
SELECT
    df.nome,
    dl.uf,
    dl.cidade,
    SUM(fa.quantidade_atendimentos) AS quantidade_atendimentos
FROM
    fact_atendimentos fa
    JOIN dim_funcionario df ON fa.funcionario_id = df.funcionario_id
    JOIN dim_localidade dl ON fa.localidade_id = dl.localidade_id
GROUP BY
    df.nome,
    dl.uf,
    dl.cidade;

-- 5. Valor das últimas (3) vendas realizadas por cliente
SELECT
    dc.nome,
    fv.valor_total,
    dt.data
FROM
    (
        SELECT
            fv.cliente_id,
            fv.valor_total,
            fv.tempo_id,
            ROW_NUMBER() OVER (
                PARTITION BY fv.cliente_id
                ORDER BY
                    dt.data DESC
            ) AS rn
        FROM
            fact_vendas fv
            JOIN dim_tempo dt ON fv.tempo_id = dt.tempo_id
    ) fv
    JOIN dim_cliente dc ON fv.cliente_id = dc.cliente_id
    JOIN dim_tempo dt ON fv.tempo_id = dt.tempo_id
WHERE
    fv.rn <= 3
ORDER BY
    dc.nome,
    dt.data DESC;

-- 6. Clientes que mais compraram na loja virtual com valor acumulado por período
SELECT
    dc.nome,
    dt.ano,
    dt.mes,
    SUM(fv.valor_total) AS valor_acumulado
FROM
    fact_vendas fv
    JOIN dim_cliente dc ON fv.cliente_id = dc.cliente_id
    JOIN dim_tempo dt ON fv.tempo_id = dt.tempo_id
GROUP BY
    dc.nome,
    dt.ano,
    dt.mes
ORDER BY
    valor_acumulado DESC;