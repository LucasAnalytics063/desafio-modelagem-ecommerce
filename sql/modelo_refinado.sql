-- =====================================================================
-- PROJETO: Refinamento de Modelo de Dados - E-commerce
-- Autor: Lucas Beserra Ribeiro
-- Descrição: Script DDL para MySQL Workbench (Reverse Engineering)
-- =====================================================================

DROP SCHEMA IF EXISTS ecommerce_refinado;
CREATE SCHEMA ecommerce_refinado DEFAULT CHARACTER SET utf8mb4;
USE ecommerce_refinado;

-- ---------------------------------------------------------------------
1) CLIENTE (entidade genérica / superclasse)
-- ---------------------------------------------------------------------
CREATE TABLE cliente (
    id_cliente      INT AUTO_INCREMENT PRIMARY KEY,
    tipo_cliente    ENUM('PF', 'PJ') NOT NULL,
    email           VARCHAR(150) NOT NULL UNIQUE,
    telefone        VARCHAR(20),
    data_cadastro   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    endereco        VARCHAR(255) NOT NULL,
    cidade          VARCHAR(100) NOT NULL,
    uf              CHAR(2) NOT NULL
) ENGINE=InnoDB;

-- Subtipo Pessoa Física
CREATE TABLE cliente_pf (
    id_cliente      INT PRIMARY KEY,
    nome_completo   VARCHAR(200) NOT NULL,
    cpf             CHAR(11) NOT NULL UNIQUE,
    data_nascimento DATE NOT NULL,
    CONSTRAINT fk_clientepf_cliente
        FOREIGN KEY (id_cliente) REFERENCES cliente(id_cliente)
        ON DELETE CASCADE
) ENGINE=InnoDB;

-- Subtipo Pessoa Jurídica
CREATE TABLE cliente_pj (
    id_cliente          INT PRIMARY KEY,
    razao_social        VARCHAR(200) NOT NULL,
    nome_fantasia       VARCHAR(200),
    cnpj                CHAR(14) NOT NULL UNIQUE,
    inscricao_estadual  VARCHAR(20),
    CONSTRAINT fk_clientepj_cliente
        FOREIGN KEY (id_cliente) REFERENCES cliente(id_cliente)
        ON DELETE CASCADE
) ENGINE=InnoDB;

-- Trigger para reforçar a exclusividade PF/PJ no nível de banco:
-- impede inserir em cliente_pf um id cujo tipo_cliente não seja 'PF'.
DELIMITER $$
CREATE TRIGGER trg_check_tipo_pf
BEFORE INSERT ON cliente_pf
FOR EACH ROW
BEGIN
    DECLARE v_tipo VARCHAR(2);
    SELECT tipo_cliente INTO v_tipo FROM cliente WHERE id_cliente = NEW.id_cliente;
    IF v_tipo IS NULL OR v_tipo <> 'PF' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cliente informado não é do tipo PF.';
    END IF;
END$$

CREATE TRIGGER trg_check_tipo_pj
BEFORE INSERT ON cliente_pj
FOR EACH ROW
BEGIN
    DECLARE v_tipo VARCHAR(2);
    SELECT tipo_cliente INTO v_tipo FROM cliente WHERE id_cliente = NEW.id_cliente;
    IF v_tipo IS NULL OR v_tipo <> 'PJ' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cliente informado não é do tipo PJ.';
    END IF;
END$$
DELIMITER ;

-- ---------------------------------------------------------------------
2) FORMA DE PAGAMENTO
-------------------------------------------------------------------------
CREATE TABLE forma_pagamento (
    id_forma_pagamento  INT AUTO_INCREMENT PRIMARY KEY,
    tipo                ENUM('CARTAO_CREDITO','CARTAO_DEBITO','PIX','BOLETO') NOT NULL,
    descricao           VARCHAR(100)
) ENGINE=InnoDB;

CREATE TABLE cliente_forma_pagamento (
    id_cliente          INT NOT NULL,
    id_forma_pagamento  INT NOT NULL,
    dados_referencia     VARCHAR(255) COMMENT 'Ex: últimos 4 dígitos do cartão, chave PIX cadastrada',
    padrao              BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Indica a forma de pagamento preferencial do cliente',
    PRIMARY KEY (id_cliente, id_forma_pagamento),
    CONSTRAINT fk_cfp_cliente
        FOREIGN KEY (id_cliente) REFERENCES cliente(id_cliente)
        ON DELETE CASCADE,
    CONSTRAINT fk_cfp_forma
        FOREIGN KEY (id_forma_pagamento) REFERENCES forma_pagamento(id_forma_pagamento)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
3) PEDIDO Entidade central que liga Cliente, Pagamento usado na compra e Entrega.
-- ---------------------------------------------------------------------
CREATE TABLE pedido (
    id_pedido           INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente          INT NOT NULL,
    id_forma_pagamento  INT NOT NULL,
    data_pedido         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valor_total         DECIMAL(10,2) NOT NULL,
    status_pedido       ENUM('AGUARDANDO_PAGAMENTO','PAGO','CANCELADO','CONCLUIDO')
                         NOT NULL DEFAULT 'AGUARDANDO_PAGAMENTO',
    CONSTRAINT fk_pedido_cliente
        FOREIGN KEY (id_cliente) REFERENCES cliente(id_cliente),
    CONSTRAINT fk_pedido_forma
        FOREIGN KEY (id_forma_pagamento) REFERENCES forma_pagamento(id_forma_pagamento)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
4) ENTREGA
-- ---------------------------------------------------------------------
CREATE TABLE entrega (
    id_entrega          INT AUTO_INCREMENT PRIMARY KEY,
    id_pedido           INT NOT NULL UNIQUE,
    codigo_rastreio     VARCHAR(50) UNIQUE,
    status_entrega      ENUM('AGUARDANDO_ENVIO','ENVIADO','EM_TRANSITO','ENTREGUE','EXTRAVIADO')
                         NOT NULL DEFAULT 'AGUARDANDO_ENVIO',
    transportadora      VARCHAR(100),
    data_envio          DATETIME,
    data_entrega_prevista DATE,
    data_entrega_real   DATETIME,
    CONSTRAINT fk_entrega_pedido
        FOREIGN KEY (id_pedido) REFERENCES pedido(id_pedido)
        ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
Dados de exemplo
-- ---------------------------------------------------------------------
INSERT INTO cliente (tipo_cliente, email, telefone, endereco, cidade, uf)
VALUES
 ('PF', 'joao.silva@email.com', '63999990000', 'Rua A, 123', 'Paraíso do Tocantins', 'TO'),
 ('PJ', 'contato@empresa.com', '63988880000', 'Av. B, 456', 'Palmas', 'TO');

INSERT INTO cliente_pf (id_cliente, nome_completo, cpf, data_nascimento)
VALUES (1, 'João da Silva', '12345678900', '1990-05-10');

INSERT INTO cliente_pj (id_cliente, razao_social, nome_fantasia, cnpj, inscricao_estadual)
VALUES (2, 'Empresa Exemplo LTDA', 'Empresa Exemplo', '12345678000199', '123456789');

INSERT INTO forma_pagamento (tipo, descricao) VALUES
 ('CARTAO_CREDITO', 'Cartão de Crédito'),
 ('PIX', 'Pix'),
 ('BOLETO', 'Boleto Bancário');

INSERT INTO cliente_forma_pagamento (id_cliente, id_forma_pagamento, dados_referencia, padrao)
VALUES
 (1, 1, 'Final 4321', TRUE),
 (1, 2, 'chave-pix@email.com', FALSE),
 (2, 3, NULL, TRUE);

INSERT INTO pedido (id_cliente, id_forma_pagamento, valor_total, status_pedido)
VALUES (1, 1, 259.90, 'PAGO');

INSERT INTO entrega (id_pedido, codigo_rastreio, status_entrega, transportadora, data_entrega_prevista)
VALUES (1, 'BR123456789TO', 'EM_TRANSITO', 'Correios', '2026-08-20');
