-- Criação do schema
DROP DATABASE IF EXISTS oficina;
CREATE DATABASE Oficina;
USE Oficina;

-- Tabela de pessoas (clientes)
CREATE TABLE pessoa (
  id_pessoa INT AUTO_INCREMENT PRIMARY KEY,
  nome       VARCHAR(80) NOT NULL,
  endereco   VARCHAR(120) NULL
);

-- Tabela de mecânicos
CREATE TABLE mecanico (
  codigo INT PRIMARY KEY,
  especialidade VARCHAR(60) NOT NULL
) ;

-- Carro do cliente
-- No anexo há referência a Cliente_idPessoa e relação com OS; aqui normalizamos:
-- o carro pertence a uma pessoa; OS referencia carro e cliente.
CREATE TABLE carro (
  id_carro INT AUTO_INCREMENT PRIMARY KEY,
  id_cliente INT NOT NULL,
  placa  VARCHAR(8) NOT NULL,
  modelo VARCHAR(40) NOT NULL,
  CONSTRAINT uq_carro_placa UNIQUE (placa),
  CONSTRAINT fk_carro_pessoa FOREIGN KEY (id_cliente) REFERENCES pessoa(id_pessoa)
    ON UPDATE CASCADE ON DELETE RESTRICT
);

-- Ordem de Serviço
CREATE TABLE os (
  id_os INT AUTO_INCREMENT PRIMARY KEY,
  id_cliente INT NOT NULL,
  id_carro   INT NOT NULL,
  data_emissao     DATETIME NOT NULL,
  valor_estimado   DECIMAL(12,2) NULL,
  statusOS           ENUM('Aberta','Em execução','Concluida','Cancelada') default 'Aberta' NOT NULL,
  data_conclusao   DATETIME NULL,
  servico          VARCHAR(80) NULL,
  tipo_os          VARCHAR(40) NULL,
  equipe           INT NULL,
  aprovacao_cliente TINYINT(1) NOT NULL DEFAULT 0,
  CONSTRAINT fk_os_pessoa FOREIGN KEY (id_cliente) REFERENCES pessoa(id_pessoa)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_os_carro  FOREIGN KEY (id_carro)   REFERENCES carro(id_carro)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  INDEX idx_os_status (statusOS),
  INDEX idx_os_datas (data_emissao, data_conclusao),
  INDEX idx_os_cliente (id_cliente),
  INDEX idx_os_carro (id_carro)
);

-- Itens de peças vinculados à OS (no anexo "Peças" já aponta para OS)
CREATE TABLE os_peca (
  id_os_peca INT AUTO_INCREMENT PRIMARY KEY,
  id_os  INT NOT NULL,
  descricao VARCHAR(80) NOT NULL,
  valor_unit DECIMAL(12,2) NOT NULL,
  qtd  INT NOT NULL DEFAULT 1,
  CONSTRAINT fk_os_peca_os FOREIGN KEY (id_os) REFERENCES os(id_os)
    ON UPDATE CASCADE ON DELETE CASCADE,
  INDEX idx_os_peca_os (id_os)
);

-- Itens de mão-de-obra da OS (no anexo há "Mão-de-obra" com vínculo a OS e Mecânico)
CREATE TABLE os_mao_de_obra (
  id_os_mo INT AUTO_INCREMENT PRIMARY KEY,
  id_os INT NOT NULL,
  mecanico_codigo INT NOT NULL,
  servico VARCHAR(80) NOT NULL,
  -- valor_base: valor por hora (ou valor fixo por serviço; ajustável na query)
  valor_base DECIMAL(12,2) NOT NULL,
  horas_trabalhadas TIME NOT NULL, -- guardado como HH:MM:SS
  CONSTRAINT fk_os_mo_os FOREIGN KEY (id_os) REFERENCES os(id_os)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_os_mo_mec FOREIGN KEY (mecanico_codigo) REFERENCES mecanico(codigo)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  INDEX idx_os_mo_os (id_os),
  INDEX idx_os_mo_mec (mecanico_codigo)
);

-- Associação Mecânico x OS x Equipe (presente no anexo)
CREATE TABLE mecanico_os (
  id_os INT NOT NULL,
  mecanico_codigo INT NOT NULL,
  equipe INT NULL,
  PRIMARY KEY (id_os, mecanico_codigo),
  CONSTRAINT fk_mec_os_os FOREIGN KEY (id_os) REFERENCES os(id_os)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_mec_os_mec FOREIGN KEY (mecanico_codigo) REFERENCES mecanico(codigo)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  INDEX idx_mec_os_equipe (equipe)
);

-- View de valor total do serviço. Ajuda performance para relatórios frequentes

CREATE OR REPLACE VIEW vw_os_totais AS
SELECT
  o.id_os,
  ROUND(COALESCE(SUM(p.valor_unit * p.qtd), 0), 2) AS total_pecas,
  ROUND(COALESCE(SUM(mo.valor_base * TIME_TO_SEC(mo.horas_trabalhadas)/3600), 0), 2) AS total_mao_de_obra
FROM os o
LEFT JOIN os_peca p ON p.id_os = o.id_os
LEFT JOIN os_mao_de_obra mo ON mo.id_os = o.id_os
GROUP BY o.id_os;


-- Pessoas (clientes)
INSERT INTO pessoa (nome, endereco) VALUES
('Ana Martins', 'Rua A, 100'),
('Bruno Silva', 'Av. B, 200'),
('Carla Souza', 'Rua C, 300');

-- Mecânicos
INSERT INTO mecanico (codigo, especialidade) VALUES
(101, 'Suspensão'),
(102, 'Motor'),
(103, 'Elétrica');

-- Carros
INSERT INTO carro (id_cliente, placa, modelo) VALUES
(1, 'ABC1D23', 'Gol'),
(2, 'EFG4H56', 'Civic'),
(3, 'JKL7M89', 'Corolla');

-- OS (algumas abertas, outras concluídas)
INSERT INTO os (id_cliente, id_carro, data_emissao, valor_estimado, statusOS, data_conclusao, servico, tipo_os, equipe, aprovacao_cliente) VALUES
(1, 1, '2025-08-15 09:30:00', 1200.00, 'Em Execução', NULL, 'Revisão completa', 'Revisão', 1, 1),
(2, 2, '2025-08-17 10:00:00', 800.00,  'Concluída', '2025-08-18 16:45:00', 'Troca de correia', 'Corretiva', 2, 1),
(3, 3, '2025-08-20 11:15:00', 500.00,  'Aberta',    NULL, 'Checagem elétrica', 'Diagnóstico', 1, 0);

-- Itens de peças
INSERT INTO os_peca (id_os, descricao, valor_unit, qtd) VALUES
(1, 'Filtro de óleo', 50.00, 1),
(1, 'Filtro de ar',   80.00, 1),
(2, 'Correia dentada', 300.00, 1),
(3, 'Fusível',        10.00, 2);

-- Mão-de-obra (valor_base interpretado como valor por hora)
INSERT INTO os_mao_de_obra (id_os, mecanico_codigo, servico, valor_base, horas_trabalhadas) VALUES
(1, 101, 'Revisão suspensão', 120.00, '02:30:00'),
(1, 102, 'Ajuste motor',      150.00, '01:45:00'),
(2, 102, 'Troca correia',     160.00, '03:00:00'),
(3, 103, 'Diagnóstico elétrico', 140.00, '01:20:00');

-- Associação Mecânico x OS x Equipe
INSERT INTO mecanico_os (id_os, mecanico_codigo, equipe) VALUES
(1, 101, 1),
(1, 102, 1),
(2, 102, 2),
(3, 103, 1);


-- OS abertas ou em execução?
SELECT
  o.id_os,
  p.nome AS cliente,
  c.placa,
  c.modelo,
  o.statusOS,
  o.data_emissao
FROM os o
JOIN pessoa p ON p.id_pessoa = o.id_cliente
JOIN carro  c ON c.id_carro   = o.id_carro
WHERE o.statusOS IN ('Aberta','Em execução')
ORDER BY o.data_emissao DESC;

-- OS aprovadas
SELECT
  o.id_os, p.nome AS cliente, o.aprovacao_cliente, o.data_emissao, o.statusOS
FROM os o
JOIN pessoa p ON p.id_pessoa = o.id_cliente
WHERE o.aprovacao_cliente = 1
ORDER BY o.data_emissao;

-- Tempo gasto entre a da abertura da OS até a conclusão se aprovada.
SELECT
  o.id_os,
  p.nome AS cliente,
  CASE
    WHEN o.data_conclusao IS NOT NULL
      THEN TIMESTAMPDIFF(DAY, o.data_emissao, o.data_conclusao)
    ELSE TIMESTAMPDIFF(DAY, o.data_emissao, NOW())
  END AS dias_ciclo,
  CASE 
    WHEN o.aprovacao_cliente = 1 THEN 'Aprovada'
    ELSE 'Pendente'
  END AS status_aprovacao
FROM os o
JOIN pessoa p ON p.id_pessoa = o.id_cliente
ORDER BY dias_ciclo DESC;

-- Quais clientes gataram valor superior a R$ 1000.00?
WITH totais AS (
  SELECT o.id_cliente,
         SUM(v.total_pecas + v.total_mao_de_obra) AS gasto_total
  FROM os o
  JOIN vw_os_totais v ON v.id_os = o.id_os
  WHERE o.data_emissao >= '2025-08-01'
  GROUP BY o.id_cliente
)
SELECT p.nome, t.gasto_total
FROM totais t
JOIN pessoa p ON p.id_pessoa = t.id_cliente
HAVING t.gasto_total > 1000.00
ORDER BY t.gasto_total DESC;

-- junção das tabelas (OS × peças × mão-de-obra × mecânico)

WITH p AS (
  SELECT id_os, SUM(valor_unit * qtd) AS total_pecas FROM os_peca GROUP BY id_os
),
mo AS (
  SELECT id_os, SUM(valor_base * TIME_TO_SEC(horas_trabalhadas)/3600) AS total_mo
  FROM os_mao_de_obra
  GROUP BY id_os
),
eq AS (
  SELECT o.id_os, GROUP_CONCAT(DISTINCT CONCAT(m.codigo, ':', m.especialidade) ORDER BY m.codigo SEPARATOR ', ') AS equipe_mecanicos
  FROM mecanico_os o
  JOIN mecanico m ON m.codigo = o.mecanico_codigo
  GROUP BY o.id_os
)
SELECT
  os.id_os,
  pcli.nome AS cliente,
  car.placa,
  os.statusOS,
  IFNULL(p.total_pecas,0) AS total_pecas,
  IFNULL(mo.total_mo,0)   AS total_mao_de_obra,
  (IFNULL(p.total_pecas,0)+IFNULL(mo.total_mo,0)) AS total_os,
  eq.equipe_mecanicos
FROM os
JOIN pessoa pcli ON pcli.id_pessoa = os.id_cliente
JOIN carro car   ON car.id_carro   = os.id_carro
LEFT JOIN p  ON p.id_os  = os.id_os
LEFT JOIN mo ON mo.id_os = os.id_os
LEFT JOIN eq ON eq.id_os = os.id_os
ORDER BY os.data_emissao DESC;


-- Query referenciando quantas OS foram atendidas dentro da estimativa do orçamento e quantas foram atendidas fora da estimativa
WITH totais AS (
  SELECT o.id_os,
         o.valor_estimado,
         (v.total_pecas + v.total_mao_de_obra) AS total_real
  FROM os o
  JOIN vw_os_totais v ON v.id_os = o.id_os
)
SELECT
  SUM(total_real <= valor_estimado) AS dentro_estimativa,
  SUM(total_real  > valor_estimado) AS acima_estimativa
FROM totais
HAVING dentro_estimativa + acima_estimativa > 0;

-- Mecânicos e suas especialidades com total de horas trabalhadas
SELECT m.codigo, m.especialidade, 
       SEC_TO_TIME(SUM(TIME_TO_SEC(mo.horas_trabalhadas))) as total_horas
FROM mecanico m
JOIN os_mao_de_obra mo ON m.codigo = mo.mecanico_codigo
GROUP BY m.codigo, m.especialidade
HAVING total_horas > '00:00:00'
ORDER BY total_horas DESC;

-- Peças mais utilizadas nas OS
SELECT descricao, SUM(qtd) as total_utilizado,
       SUM(valor_unit * qtd) as valor_total
FROM os_peca
GROUP BY descricao
HAVING total_utilizado > 0
ORDER BY total_utilizado DESC;

 