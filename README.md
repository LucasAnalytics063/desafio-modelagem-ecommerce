# Desafio de Modelagem de Dados - Refinamento de Esquema (E-commerce)

## Contexto

Este projeto é a entrega do desafio de modelagem de dados proposto em aula da DIO, cujo objetivo é **refinar um modelo relacional de e-commerce** apresentado previamente, incorporando três novas regras de negócio.

## Objetivo do Desafio

Refinar o modelo original acrescentando:

1. **Cliente PJ e PF** — uma conta pode ser Pessoa Física *ou* Pessoa Jurídica, nunca as duas simultaneamente.
2. **Pagamento** — um cliente pode ter mais de uma forma de pagamento cadastrada.
3. **Entrega** — deve possuir status e código de rastreio.

## Decisões de Modelagem

### 1. Cliente PF / PJ — Especialização Exclusiva (Herança)

Optei por modelar Cliente como uma **superclasse** (`cliente`) com duas **subclasses** (`cliente_pf` e `cliente_pj`), em vez de usar uma única tabela com colunas opcionais para CPF e CNPJ. 

Motivos:
- Evita colunas nulas em excesso (uma tabela única teria CPF nulo para PJ e CNPJ nulo para PF).
- Reforça a integridade: cada subtabela guarda somente os atributos que fazem sentido para aquele tipo de cliente (ex: `data_nascimento` só existe para PF, `razao_social` só existe para PJ).
- A exclusividade (não pode ser PF e PJ ao mesmo tempo) é garantida por:
  - Coluna `tipo_cliente` (ENUM) na tabela mãe;
  - Chave primária da subtabela = chave estrangeira da tabela mãe (relação 1:1);
  - Triggers (`trg_check_tipo_pf` e `trg_check_tipo_pj`) que impedem inserir um
    registro em `cliente_pf` cujo `tipo_cliente` não seja `'PF'` (e o mesmo
    para PJ).

### 2. Forma de Pagamento — Relacionamento N:N

Como um cliente pode cadastrar mais de uma forma de pagamento (cartão, Pix, boleto), o relacionamento entre `cliente` e  forma_pagamento` é **N:N**,
resolvido pela tabela associativa `cliente_forma_pagamento`, que também guarda qual é a forma de pagamento padrão do cliente (`padrao`).

O pedido, por sua vez, referencia diretamente qual forma de pagamento foi efetivamente usada naquela compra `pedido.id_forma_pagamento`), já que uma compra usa apenas uma forma de pagamento por vez.

### 3. Entrega — Status e Rastreio

A tabela `entrega` tem relação **1:1** com `pedido` (cada pedido gera uma entrega) e contempla:
- `status_entrega` (ENUM): aguardando envio, enviado, em trânsito, entregue, extraviado.
- `codigo_rastreio`: código único fornecido pela transportadora.
- Campos complementares (`transportadora`, datas de envio/entrega) para dar realismo ao modelo.

## Autor

**Lucas Beserra Ribeiro**  
Analista de Business Intelligence | Sicoob Tocantins  
[GitHub: LucasAnalytics063](https://github.com/LucasAnalytics063)
