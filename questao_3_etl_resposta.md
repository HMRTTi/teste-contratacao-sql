# Resposta da Questão 3 – Case de ETL (Azure Data Factory)

Este arquivo descreve, em tópicos, um case de ETL conforme solicitado, utilizando apenas atividades tradicionais do Azure Data Factory.

---

## ✅ Fluxo de ETL (em tópicos)

### 1. Extração dos dados

- **Oracle**: extração com `Copy Activity` conectando via `Self-hosted Integration Runtime`, utilizando `Linked Service` configurado com credenciais seguras.
- **AWS S3 (CSV)**: leitura dos arquivos CSV via `HTTP Dataset` apontando para um bucket do Amazon S3.

---

### 2. Validação da entrada

- Configuração do `Skip Line Count` e `Fault Tolerance` na `Copy Activity`.
- Após carga na staging, execução de **Stored Procedure** para:
  - Verificação de campos obrigatórios
  - Validação de formatos de data
  - Registro de erros de entrada em tabela de controle

---

### 3. Transformação

- Dados carregados em **tabela de staging** no SQL Server.
- Transformações realizadas com **Stored Procedures**, incluindo:
  - Normalização e padronização
  - Conversão de tipos
  - Aplicação de regras de negócio
  - Cálculo de colunas derivadas (ex: margem, score, categorias)

---

### 4. Carga no destino final

- Inserção e atualização nas **tabelas finais** do SQL Server por meio de `MERGE` ou `INSERT` dentro de Stored Procedure.
- Controle de histórico e versionamento opcional incluído no processo.

---

### 5. Validação dos dados finais

- Stored Procedure de auditoria comparando:
  - Quantidade de registros entre origem e destino
  - Regras de consistência e totais esperados
- Registro dos resultados em **tabela de log de auditoria**

---

### 6. Cálculo de indicadores

- Views e procedures finais realizam:
  - Agregações e filtros para KPIs
  - Cálculo de volume por categoria
  - Exposição de dados para **Power BI**

---

## ⚙️ Execução

- Orquestração via **pipelines do ADF**
- Controle de fluxo com `If Condition` e execução de `Stored Procedures`
- Agendamento com **Trigger diária às 6h**

---

