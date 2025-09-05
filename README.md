# Projeto Oficina
# 🚗 Sistema de Gestão de Oficina Mecânica (SQL)

---

## 📌 Descrição
Este projeto implementa um **esquema lógico de banco de dados relacional** para o gerenciamento de uma **oficina mecânica**.  

O objetivo é:  
- Controlar **clientes, veículos, ordens de serviço (OS), peças, mão-de-obra e equipes de mecânicos**.  
- Fornecer **consultas otimizadas** para relatórios operacionais e gerenciais.  
- Garantir **consistência, integridade referencial** e facilitar análises de desempenho.  

---

## 🗂️ Estrutura do Banco de Dados
O banco é criado no **MySQL** com o nome `Oficina`.  

As principais entidades são:  

- **pessoa** → Cadastro de clientes.  
- **mecanico** → Profissionais e suas especialidades.  
- **carro** → Veículos pertencentes a clientes.  
- **os (ordem de serviço)** → Registro das manutenções e reparos.  
- **os_peca** → Itens de peças vinculados às ordens de serviço.  
- **os_mao_de_obra** → Serviços executados por mecânicos, incluindo horas trabalhadas.  
- **mecanico_os** → Associação entre mecânicos, ordens de serviço e equipes.  
- **vw_os_totais** → *View* de apoio para cálculo de valores totais por OS (peças + mão-de-obra).  

---

## 📊 Querys realizadas

- **Quantas OS abertas ou em execução?**
- **Total de OS aprovadas?**
- **Tempo gasto entre a da abertura da OS até a conclusão se aprovada?**
- **Quais clientes gataram valor superior a R$ 1000.00?**
- **junção das tabelas (OS × peças × mão-de-obra × mecânico)**
- **Query referenciando quantas OS foram atendidas dentro da estimativa do orçamento e quantas foram atendidas fora da estimativa?**
- **Mecânicos e suas especialidades com total de horas trabalhadas?**
- **Peças mais utilizadas nas OS?**