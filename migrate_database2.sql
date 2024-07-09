DROP DATABASE IF EXISTS VAREJO_DW2;

CREATE DATABASE VAREJO_DW2;

USE VAREJO_DW2;

-- Tabela Dimensional de Tempo
CREATE TABLE dim_tempo (
    tempo_id INT PRIMARY KEY AUTO_INCREMENT,
    data DATE,
    ano INT,
    mes INT,
    dia INT
);

-- Tabela Dimensional de Localidade
CREATE TABLE dim_localidade (
    localidade_id INT PRIMARY KEY AUTO_INCREMENT,
    uf VARCHAR(2),
    cidade VARCHAR(255),
    endereco VARCHAR(255)
);

CREATE TABLE dim_tipo (
    tipo_id INT PRIMARY KEY AUTO_INCREMENT,
    tipo VARCHAR(255)
);

CREATE TABLE dim_categoria (
    categoria_id INT PRIMARY KEY AUTO_INCREMENT,
    categoria VARCHAR(255)
);

-- Tabela Dimensional de Produto
CREATE TABLE dim_produto (
    produto_id INT PRIMARY KEY AUTO_INCREMENT,
    tipo_id INT,
    categoria_id INT,
    descricao VARCHAR(255),
    tb012_cod_produto INT,
    FOREIGN KEY (tipo_id) REFERENCES dim_tipo(tipo_id),
    FOREIGN KEY (categoria_id) REFERENCES dim_categoria(categoria_id)
);

-- Tabela Dimensional de Funcionário
CREATE TABLE dim_funcionario (
    funcionario_id INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(255)
);

-- Tabela Dimensional de Cliente
CREATE TABLE dim_cliente (
    cliente_id INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(255),
    cpf VARCHAR(17)
);

-- Tabela Fato de Vendas
CREATE TABLE fact_vendas (
    localidade_id INT,
    produto_id INT,
    tipo_id INT,
    categoria_id INT,
    funcionario_id INT,
    cliente_id INT,
    quantidade INT,
    valor_unitario NUMERIC(12, 2),
    valor_total NUMERIC(12, 2),
    ano INT,
    mes INT,
    dia INT,
    FOREIGN KEY (localidade_id) REFERENCES dim_localidade(localidade_id),
    FOREIGN KEY (produto_id) REFERENCES dim_produto(produto_id),
    FOREIGN KEY (funcionario_id) REFERENCES dim_funcionario(funcionario_id),
    FOREIGN KEY (cliente_id) REFERENCES dim_cliente(cliente_id),
    FOREIGN KEY (tipo_id) REFERENCES dim_tipo(tipo_id),
    FOREIGN KEY (categoria_id) REFERENCES dim_categoria(categoria_id)
);

-- Tabela Fato de Atendimentos
CREATE TABLE fact_atendimentos (
    tempo_id INT,
    localidade_id INT,
    funcionario_id INT,
    quantidade_atendimentos INT,
    FOREIGN KEY (tempo_id) REFERENCES dim_tempo(tempo_id),
    FOREIGN KEY (localidade_id) REFERENCES dim_localidade(localidade_id),
    FOREIGN KEY (funcionario_id) REFERENCES dim_funcionario(funcionario_id)
);

-- MIGRATING DATABASE
USE VAREJO_DW2;

-- Inserir dados na tabela dim_tempo
INSERT INTO
    dim_tempo (data, ano, mes, dia)
SELECT
    DISTINCT data,
    YEAR(data),
    MONTH(data),
    DAY(data)
FROM
    (
        SELECT
            tb005_data_contratacao AS data
        FROM
            VAREJO_RELACIONAL.tb005_funcionarios
        UNION
        SELECT
            tb005_data_demissao AS data
        FROM
            VAREJO_RELACIONAL.tb005_funcionarios
        UNION
        SELECT
            tb010_012_data AS data
        FROM
            VAREJO_RELACIONAL.tb010_012_vendas
        UNION
        SELECT
            tb012_017_data AS data
        FROM
            VAREJO_RELACIONAL.tb012_017_compras
    ) AS datas;

-- Inserir dados na tabela dim_localidade
INSERT INTO
    dim_localidade (uf, cidade, endereco)
SELECT
    DISTINCT e.tb001_sigla_uf AS uf,
    c.tb002_nome_cidade AS cidade,
    CONCAT(
        e.tb003_nome_rua,
        ' ',
        e.tb003_numero_rua,
        ' ',
        ifnull(e.tb003_complemento, ', sem complemento')
    ) AS endereco
FROM
    VAREJO_RELACIONAL.tb003_enderecos e
    JOIN VAREJO_RELACIONAL.tb002_cidades c ON e.tb002_cod_cidade = c.tb002_cod_cidade;

INSERT INTO
    dim_tipo (tipo)
VALUES
    ('Alimento'),
    ('Eletrodoméstico'),
    ('Vestuário');

INSERT INTO
    dim_categoria (categoria)
SELECT
    c.tb013_descricao
FROM
    VAREJO_RELACIONAL.tb013_categorias c;

-- Inserir dados na tabela dim_produto
INSERT INTO
    dim_produto (
        tipo_id,
        categoria_id,
        descricao,
        tb012_cod_produto
    )
SELECT
    t.tipo_id,
    cat.categoria_id,
    CONCAT(
        p.tb012_descricao,
        ' ',
        a.tb014_detalhamento,
        ' ',
        IFNULL(a.tb014_unidade_medida, 'n/a'),
        ' ',
        IFNULL(a.tb014_num_lote, 'n/a'),
        ' ',
        IFNULL(a.tb014_data_vencimento, 'n/a')
    ) AS descricao,
    p.tb012_cod_produto
FROM
    VAREJO_RELACIONAL.tb014_prd_alimentos a
    JOIN dim_tipo t ON t.tipo = 'Alimento'
    JOIN VAREJO_RELACIONAL.tb012_produtos p ON a.tb012_cod_produto = p.tb012_cod_produto
    JOIN VAREJO_RELACIONAL.tb013_categorias c ON p.tb013_cod_categoria = c.tb013_cod_categoria
    JOIN dim_categoria cat ON c.tb013_descricao = cat.categoria
UNION
SELECT
    t.tipo_id,
    cat.categoria_id,
    CONCAT(
        p.tb012_descricao,
        ' ',
        e.tb015_detalhamento,
        ' ',
        IFNULL(e.tb015_tensao, 'n/a'),
        ' ',
        IFNULL(e.tb015_nivel_consumo_procel, 'n/a')
    ) AS descricao,
    p.tb012_cod_produto
FROM
    VAREJO_RELACIONAL.tb015_prd_eletros e
    JOIN dim_tipo t ON t.tipo = 'Eletrodoméstico'
    JOIN VAREJO_RELACIONAL.tb012_produtos p ON e.tb012_cod_produto = p.tb012_cod_produto
    JOIN VAREJO_RELACIONAL.tb013_categorias c ON p.tb013_cod_categoria = c.tb013_cod_categoria
    JOIN dim_categoria cat ON c.tb013_descricao = cat.categoria
UNION
SELECT
    t.tipo_id,
    cat.categoria_id,
    CONCAT(
        p.tb012_descricao,
        ' ',
        v.tb016_detalhamento,
        ' ',
        v.tb016_sexo,
        ' ',
        IFNULL(v.tb016_tamanho, 'n/a'),
        ' ',
        IFNULL(v.tb016_numeracao, 'n/a')
    ) AS descricao,
    p.tb012_cod_produto
FROM
    VAREJO_RELACIONAL.tb016_prd_vestuarios v
    JOIN dim_tipo t ON t.tipo = 'Vestuário'
    JOIN VAREJO_RELACIONAL.tb012_produtos p ON v.tb012_cod_produto = p.tb012_cod_produto
    JOIN VAREJO_RELACIONAL.tb013_categorias c ON p.tb013_cod_categoria = c.tb013_cod_categoria
    JOIN dim_categoria cat ON c.tb013_descricao = cat.categoria;

-- Inserir dados na tabela dim_funcionario
INSERT INTO
    dim_funcionario (nome)
SELECT
    f.tb005_nome_completo AS nome
FROM
    VAREJO_RELACIONAL.tb005_funcionarios f;

-- Inserir dados na tabela dim_cliente
INSERT INTO
    dim_cliente (nome, cpf)
SELECT
    c.tb010_nome AS nome,
    c.tb010_CPF AS cpf
FROM
    VAREJO_RELACIONAL.tb010_clientes c;

INSERT INTO
    fact_vendas (
        localidade_id,
        produto_id,
        funcionario_id,
        cliente_id,
        quantidade,
        valor_unitario,
        valor_total,
        ano,
        mes,
        dia
    )
SELECT
    l.localidade_id,
    p.produto_id,
    v.tb005_matricula,
    c.cliente_id,
    v.tb010_012_quantidade AS quantidade,
    v.tb010_012_valor_unitario AS valor_unitario,
    v.tb010_012_quantidade * v.tb010_012_valor_unitario AS valor_total,
    YEAR(v.tb010_012_data),
    MONTH(v.tb010_012_data),
    DAY(v.tb010_012_data)
FROM
    VAREJO_RELACIONAL.tb010_012_vendas v
    JOIN (
        SELECT
            DISTINCT dp.tb012_cod_produto,
            MIN(dp.produto_id) AS produto_id
        FROM
            dim_produto dp
        GROUP BY
            dp.tb012_cod_produto
    ) p ON p.tb012_cod_produto = v.tb012_cod_produto
    JOIN VAREJO_RELACIONAL.tb005_funcionarios f2 ON v.tb005_matricula = f2.tb005_matricula
    JOIN VAREJO_RELACIONAL.tb004_lojas l ON f2.tb004_cod_loja = l.tb004_cod_loja
    JOIN VAREJO_RELACIONAL.tb003_enderecos e ON l.tb003_cod_endereco = e.tb003_cod_endereco
    JOIN dim_localidade l ON l.endereco = CONCAT(
        e.tb003_nome_rua,
        ' ',
        e.tb003_numero_rua,
        ' ',
        IFNULL(e.tb003_complemento, ', sem complemento')
    )
    JOIN dim_cliente c ON v.tb010_cpf = c.cpf;

-- Inserir dados na tabela fact_atendimentos
INSERT INTO
    fact_atendimentos (
        tempo_id,
        localidade_id,
        funcionario_id,
        quantidade_atendimentos
    )
SELECT
    t.tempo_id,
    dl.localidade_id,
    f.tb005_matricula,
    COUNT(*) AS quantidade_atendimentos
FROM
    VAREJO_RELACIONAL.tb005_funcionarios f
    JOIN VAREJO_RELACIONAL.tb004_lojas l ON f.tb004_cod_loja = l.tb004_cod_loja
    JOIN VAREJO_RELACIONAL.tb003_enderecos e ON l.tb003_cod_endereco = e.tb003_cod_endereco
    JOIN dim_localidade dl ON dl.endereco = CONCAT(
        e.tb003_nome_rua,
        ' ',
        e.tb003_numero_rua,
        ' ',
        IFNULL(e.tb003_complemento, ', sem complemento')
    )
    JOIN dim_tempo t ON t.data BETWEEN f.tb005_data_contratacao
    AND IFNULL(f.tb005_data_demissao, '2024-01-01 00:00:00')
GROUP BY
    t.tempo_id,
    dl.localidade_id,
    f.tb005_matricula;

-- Inserts para consultas
INSERT INTO
    fact_vendas (
        cliente_id,
        valor_total,
        localidade_id,
        produto_id,
        funcionario_id,
        quantidade,
        valor_unitario,
        ano,
        mes,
        dia,
        tipo_id,
        categoria_id
    )
SELECT
    NULL AS cliente_id,
    NULL AS valor_total,
    NULL AS localidade_id,
    NULL AS produto_id,
    NULL AS funcionario_id,
    SUM(fv.quantidade) AS quantidade,
    NULL AS valor_unitario,
    NULL AS ano,
    NULL AS mes,
    NULL AS dia,
    dp.tipo_id AS tipo_id,
    dp.categoria_id AS categoria_id
FROM
    fact_vendas fv
    JOIN dim_produto dp ON fv.produto_id = dp.produto_id
GROUP BY
    dp.tipo_id,
    dp.categoria_id;

-- 2. Valor das vendas por funcionário, permitindo uma visão hierárquica por tempo
INSERT INTO
    fact_vendas (
        cliente_id,
        valor_total,
        localidade_id,
        produto_id,
        funcionario_id,
        quantidade,
        valor_unitario,
        ano,
        mes,
        dia
    )
SELECT
    NULL AS cliente_id,
    SUM(fv.valor_total) AS valor_total,
    NULL AS localidade_id,
    NULL AS produto_id,
    df.funcionario_id AS funcionario_id,
    NULL AS quantidade,
    NULL AS valor_unitario,
    fv.ano,
    fv.mes,
    NULL AS dia
FROM
    fact_vendas fv
    JOIN dim_funcionario df ON fv.funcionario_id = df.funcionario_id
GROUP BY
    df.funcionario_id,
    fv.ano,
    fv.mes;

-- 3. Volume das vendas por funcionário, permitindo uma visão por localidade
INSERT INTO
    fact_vendas (
        cliente_id,
        valor_total,
        localidade_id,
        produto_id,
        funcionario_id,
        quantidade,
        valor_unitario,
        ano,
        mes,
        dia
    )
SELECT
    NULL AS cliente_id,
    NULL AS valor_total,
    dl.localidade_id AS localidade_id,
    NULL AS produto_id,
    df.funcionario_id AS funcionario_id,
    SUM(fv.quantidade) AS quantidade,
    NULL AS valor_unitario,
    NULL AS ano,
    NULL AS mes,
    NULL AS dia
FROM
    fact_vendas fv
    JOIN dim_funcionario df ON fv.funcionario_id = df.funcionario_id
    JOIN dim_localidade dl ON fv.localidade_id = dl.localidade_id
GROUP BY
    dl.localidade_id,
    df.funcionario_id;

-- 4. Quantidade de atendimentos realizados por funcionário e localidade
INSERT INTO
    fact_atendimentos (
        funcionario_id,
        localidade_id,
        quantidade_atendimentos,
        tempo_id
    )
SELECT
    df.funcionario_id,
    dl.localidade_id,
    SUM(fa.quantidade_atendimentos) AS quantidade_atendimentos,
    NULL AS tempo_id
FROM
    fact_atendimentos fa
    JOIN dim_funcionario df ON fa.funcionario_id = df.funcionario_id
    JOIN dim_localidade dl ON fa.localidade_id = dl.localidade_id
GROUP BY
    df.funcionario_id,
    dl.localidade_id;

-- 5. Valor das últimas (3) vendas realizadas por cliente
-- Desnecessário
-- 6. Clientes que mais compraram na loja virtual com valor acumulado por período
INSERT INTO
    fact_vendas (
        cliente_id,
        valor_total,
        localidade_id,
        produto_id,
        funcionario_id,
        quantidade,
        valor_unitario,
        ano,
        mes,
        dia
    )
SELECT
    dc.cliente_id,
    SUM(fv.valor_total) AS valor_total,
    NULL AS localidade_id,
    NULL AS produto_id,
    NULL AS funcionario_id,
    NULL AS quantidade,
    NULL AS valor_unitario,
    fv.ano,
    fv.mes,
    NULL AS dia
FROM
    fact_vendas fv
    JOIN dim_cliente dc ON fv.cliente_id = dc.cliente_id
GROUP BY
    dc.cliente_id,
    fv.ano,
    fv.mes;