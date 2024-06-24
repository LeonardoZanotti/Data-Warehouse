DROP DATABASE IF EXISTS VAREJO_DW;

CREATE DATABASE VAREJO_DW;

USE VAREJO_DW;

--- Tabela Dimensional de Tempo
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
