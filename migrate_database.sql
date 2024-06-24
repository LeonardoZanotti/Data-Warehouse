DROP DATABASE IF EXISTS VAREJO_DW;

CREATE DATABASE VAREJO_DW;

USE VAREJO_DW;

-- Tabela Dimensional de Tempo
CREATE TABLE dim_tempo (
    tempo_id INT PRIMARY KEY AUTO_INCREMENT,
    data DATE,
    ano INT,
    mes INT,
    dia INT,
    trimestre INT,
    semestre INT
);

-- Tabela Dimensional de Localidade
CREATE TABLE dim_localidade (
    localidade_id INT PRIMARY KEY AUTO_INCREMENT,
    uf VARCHAR(2),
    cidade VARCHAR(255),
    endereco VARCHAR(255)
);

-- Tabela Dimensional de Produto
CREATE TABLE dim_produto (
    produto_id INT PRIMARY KEY AUTO_INCREMENT,
    tipo VARCHAR(255),
    categoria VARCHAR(255),
    descricao VARCHAR(255)
);

-- Tabela Dimensional de Funcionário
CREATE TABLE dim_funcionario (
    funcionario_id INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(255),
    data_nascimento DATE,
    cpf VARCHAR(17),
    rg VARCHAR(15),
    status VARCHAR(20),
    data_contratacao DATE,
    data_demissao DATE,
    loja_id INT
);

-- Tabela Dimensional de Cliente
CREATE TABLE dim_cliente (
    cliente_id INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(255),
    cpf NUMERIC(15),
    fone_residencial VARCHAR(255),
    fone_celular VARCHAR(255)
);


-- Tabela Fato de Vendas
CREATE TABLE fact_vendas (
    venda_id INT PRIMARY KEY AUTO_INCREMENT,
    tempo_id INT,
    localidade_id INT,
    produto_id INT,
    funcionario_id INT,
    cliente_id INT,
    quantidade INT,
    valor_unitario NUMERIC(12,4),
    valor_total NUMERIC(12,4),
    FOREIGN KEY (tempo_id) REFERENCES dim_tempo(tempo_id),
    FOREIGN KEY (localidade_id) REFERENCES dim_localidade(localidade_id),
    FOREIGN KEY (produto_id) REFERENCES dim_produto(produto_id),
    FOREIGN KEY (funcionario_id) REFERENCES dim_funcionario(funcionario_id),
    FOREIGN KEY (cliente_id) REFERENCES dim_cliente(cliente_id)
);

-- Tabela Fato de Atendimentos
CREATE TABLE fact_atendimentos (
    atendimento_id INT PRIMARY KEY AUTO_INCREMENT,
    tempo_id INT,
    localidade_id INT,
    funcionario_id INT,
    quantidade_atendimentos INT,
    FOREIGN KEY (tempo_id) REFERENCES dim_tempo(tempo_id),
    FOREIGN KEY (localidade_id) REFERENCES dim_localidade(localidade_id),
    FOREIGN KEY (funcionario_id) REFERENCES dim_funcionario(funcionario_id)
);



-- MIGRATING DATABASE
USE VAREJO_DW;

-- Inserir dados na tabela dim_tempo
INSERT INTO dim_tempo (data, ano, mes, dia, trimestre, semestre)
SELECT DISTINCT
    data,
    YEAR(data),
    MONTH(data),
    DAY(data),
    QUARTER(data),
    IF(MONTH(data) <= 6, 1, 2)
FROM (
    SELECT tb005_data_contratacao AS data FROM VAREJO_RELACIONAL.tb005_funcionarios
    UNION
    SELECT tb005_data_demissao AS data FROM VAREJO_RELACIONAL.tb005_funcionarios
    UNION
    SELECT tb010_012_data AS data FROM VAREJO_RELACIONAL.tb010_012_vendas
    UNION
    SELECT tb012_017_data AS data FROM VAREJO_RELACIONAL.tb012_017_compras
) AS datas;

-- Inserir dados na tabela dim_localidade
INSERT INTO dim_localidade (uf, cidade, endereco)
SELECT DISTINCT
    e.tb001_sigla_uf AS uf,
    c.tb002_nome_cidade AS cidade,
    CONCAT(e.tb003_nome_rua, ' ', e.tb003_numero_rua, ' ',  ifnull(e.tb003_complemento, ', sem complemento')) AS endereco
FROM VAREJO_RELACIONAL.tb003_enderecos e
JOIN VAREJO_RELACIONAL.tb002_cidades c ON e.tb002_cod_cidade = c.tb002_cod_cidade;

-- Inserir dados na tabela dim_produto
INSERT INTO dim_produto (tipo, categoria, descricao)
SELECT
    'Alimento' AS tipo,
    c.tb013_descricao AS categoria,
    a.tb014_detalhamento AS descricao
FROM VAREJO_RELACIONAL.tb014_prd_alimentos a
JOIN VAREJO_RELACIONAL.tb012_produtos p ON a.tb012_cod_produto = p.tb012_cod_produto
JOIN VAREJO_RELACIONAL.tb013_categorias c ON p.tb013_cod_categoria = c.tb013_cod_categoria
UNION
SELECT
    'Eletrodoméstico' AS tipo,
    c.tb013_descricao AS categoria,
    e.tb015_detalhamento AS descricao
FROM VAREJO_RELACIONAL.tb015_prd_eletros e
JOIN VAREJO_RELACIONAL.tb012_produtos p ON e.tb012_cod_produto = p.tb012_cod_produto
JOIN VAREJO_RELACIONAL.tb013_categorias c ON p.tb013_cod_categoria = c.tb013_cod_categoria
UNION
SELECT
    'Vestuário' AS tipo,
    c.tb013_descricao AS categoria,
    v.tb016_detalhamento AS descricao
FROM VAREJO_RELACIONAL.tb016_prd_vestuarios v
JOIN VAREJO_RELACIONAL.tb012_produtos p ON v.tb012_cod_produto = p.tb012_cod_produto
JOIN VAREJO_RELACIONAL.tb013_categorias c ON p.tb013_cod_categoria = c.tb013_cod_categoria;

-- Inserir dados na tabela dim_funcionario
INSERT INTO dim_funcionario (nome, data_nascimento, cpf, rg, status, data_contratacao, data_demissao, loja_id)
SELECT
    f.tb005_nome_completo AS nome,
    f.tb005_data_nascimento AS data_nascimento,
    f.tb005_CPF AS cpf,
    f.tb005_RG AS rg,
    f.tb005_status AS status,
    f.tb005_data_contratacao AS data_contratacao,
    f.tb005_data_demissao AS data_demissao,
    f.tb004_cod_loja AS loja_id
FROM VAREJO_RELACIONAL.tb005_funcionarios f;

-- Inserir dados na tabela dim_cliente
INSERT INTO dim_cliente (nome, cpf, fone_residencial, fone_celular)
SELECT
    c.tb010_nome AS nome,
    c.tb010_cpf AS cpf,
    c.tb010_fone_residencial AS fone_residencial,
    c.tb010_fone_celular AS fone_celular
FROM VAREJO_RELACIONAL.tb010_clientes c;

INSERT INTO fact_vendas (tempo_id, localidade_id, produto_id, funcionario_id, cliente_id, quantidade, valor_unitario, valor_total)
SELECT
    t.tempo_id,
    l.localidade_id,
    p.produto_id,
    f.funcionario_id,
    c.cliente_id,
    v.tb010_012_quantidade AS quantidade,
    v.tb010_012_valor_unitario AS valor_unitario,
    v.tb010_012_quantidade * v.tb010_012_valor_unitario AS valor_total
FROM VAREJO_RELACIONAL.tb010_012_vendas v
JOIN dim_tempo t ON v.tb010_012_data = t.data
JOIN VAREJO_RELACIONAL.tb012_produtos p2 ON v.tb012_cod_produto = p2.tb012_cod_produto
JOIN dim_produto p ON p.descricao = p2.tb012_descricao
JOIN dim_funcionario f ON v.tb005_matricula = f.funcionario_id
JOIN VAREJO_RELACIONAL.tb005_funcionarios f2 ON v.tb005_matricula = f2.tb005_matricula
JOIN VAREJO_RELACIONAL.tb003_enderecos e ON f2.tb003_cod_endereco = e.tb003_cod_endereco
JOIN dim_localidade l ON l.endereco = CONCAT(e.tb003_nome_rua, ' ', e.tb003_numero_rua, ' ', IFNULL(e.tb003_complemento, ', sem complemento'))
JOIN dim_cliente c ON v.tb010_cpf = c.cpf;

-- Inserir dados na tabela fact_atendimentos
INSERT INTO fact_atendimentos (tempo_id, localidade_id, funcionario_id, quantidade_atendimentos)
SELECT
    t.tempo_id,
    dl.localidade_id,
    f.tb005_matricula,
    COUNT(*) AS quantidade_atendimentos
FROM VAREJO_RELACIONAL.tb005_funcionarios f
JOIN VAREJO_RELACIONAL.tb004_lojas l ON f.tb004_cod_loja = l.tb004_cod_loja
JOIN VAREJO_RELACIONAL.tb003_enderecos e ON l.tb003_cod_endereco = e.tb003_cod_endereco
JOIN dim_localidade dl ON dl.endereco = CONCAT(e.tb003_nome_rua, ' ', e.tb003_numero_rua, ' ', IFNULL(e.tb003_complemento, ', sem complemento'))
JOIN dim_tempo t ON f.tb005_data_contratacao = t.data OR f.tb005_data_demissao = t.data
GROUP BY t.tempo_id, dl.localidade_id, f.tb005_matricula;

