# Codebook — Base de ADIs Eleitorais (STF, 2016-2026)

Este documento descreve cada variável (coluna) da base tratada de Ações
Diretas de Inconstitucionalidade (ADIs) em matéria eleitoral decididas
pelo Supremo Tribunal Federal entre 2016 e 2026 (n = 28).

- **Base canônica:** `data/interim/adis_categorizadas.csv` (28 obs × 27 cols).
  Produzida por `R/01_carregamento_categorizacao.R` a partir do Excel bruto
  `data/raw/adis_final.xlsx`.
- **Base enriquecida:** `data/processed/adis_com_calendario.rds` (28 obs × 31 cols).
  Inclui as 27 colunas da base canônica mais 4 variáveis temporais cruzadas
  com o calendário eleitoral, produzidas por `R/04_analise_temporal.R`.
- **Convenção de nomes:** padrão `janitor::clean_names()` (snake_case, sem
  acentos) aplicado ao cabeçalho do Excel bruto.
- **Fonte primária:** Portal Corte Aberta do STF
  (<https://portal.stf.jus.br/hotsites/corteaberta/>), coleta manual em
  jurisprudência e acompanhamento processual.

> Variáveis com a etiqueta **Derivada** em "Fonte" são construídas em
> tempo de pipeline pelos scripts indicados; as demais vêm do extrato
> bruto do STF.

---

## 1. Identificação do processo

### `id_fato_decisao`
- **Tipo:** integer
- **Descrição:** Identificador único da decisão no sistema do STF.
- **Valores possíveis / exemplo:** `20574197`
- **Fonte:** Portal Corte Aberta do STF.
- **Observações:** Chave técnica; não tem leitura jurídica.

### `processo`
- **Tipo:** character
- **Descrição:** Identificador público da ação, no padrão "ADI <número>".
- **Valores possíveis / exemplo:** `ADI 5487`, `ADI 7677`
- **Fonte:** Portal Corte Aberta do STF.
- **Observações:** Usado como rótulo do eixo Y nas figuras de linha do tempo
  (fig07 e fig09).

---

## 2. Relator e composição

### `relator_atual`
- **Tipo:** character
- **Descrição:** Nome do ministro relator no momento da decisão final.
- **Valores possíveis / exemplo:** `Min. Rosa Weber`, `Celso de Mello`
- **Fonte:** Portal Corte Aberta do STF, padronizado em
  `R/01_carregamento_categorizacao.R`.
- **Observações:** Padronização tipográfica via `to_title_pt()`: aplica
  `stringr::str_to_title()` e rebaixa preposições portuguesas (`de`, `da`,
  `do`, `das`, `dos`, `e`) quando ocorrem **no meio** do nome. Sem essa
  regra, sairia "Celso De Mello".

### `nome_ministro_a`
- **Tipo:** character
- **Descrição:** Nome completo do relator no formato exportado pelo STF
  (caixa alta, com prefixo "MIN.").
- **Valores possíveis / exemplo:** `MIN. ROSA WEBER`, `MIN. DIAS TOFFOLI`
- **Fonte:** Portal Corte Aberta do STF.
- **Observações:** Mantida para auditoria; nas análises usa-se
  `relator_atual` (versão padronizada).

---

## 3. Tramitação (datas e tempo)

### `data_de_autuacao`
- **Tipo:** Date
- **Descrição:** Data de protocolo/autuação da ADI no STF.
- **Valores possíveis / exemplo:** `2016-03-17`
- **Fonte:** Portal Corte Aberta do STF.
- **Observações:** No Excel bruto chega como `POSIXct` com timestamp não-zero
  em ~11 das 28 linhas. Parsing robusto via `to_date_robust()` no script 01
  (detecta POSIXt/Date e usa `as.Date()`; fallback `lubridate::parse_date_time()`).

### `data_da_decisao`
- **Tipo:** Date
- **Descrição:** Data da decisão final classificada em `andamento_decisao`.
- **Valores possíveis / exemplo:** `2016-08-25`
- **Fonte:** Portal Corte Aberta do STF.
- **Observações:** Mesmo tratamento de `data_de_autuacao`. Base para cruzamento
  com o calendário eleitoral (seção 7).

### `data_baixa`
- **Tipo:** character (timestamp em formato `DD/MM/YYYY HH:MM:SS`)
- **Descrição:** Data e hora de encerramento da tramitação no sistema.
- **Valores possíveis / exemplo:** `19/02/2018 13:49:48`
- **Fonte:** Portal Corte Aberta do STF.
- **Observações:** Diferentemente das demais datas, **não é convertida** para
  classe `Date` no pipeline atual — não é usada nas análises. Se for ativada
  no futuro, considerar `lubridate::dmy_hms()`.

### `ano_da_decisao`
- **Tipo:** integer
- **Descrição:** Ano da decisão final, conforme registrado pelo STF.
- **Valores possíveis / exemplo:** `2016`, `2024`
- **Fonte:** Portal Corte Aberta do STF.
- **Observações:** Em geral idêntico a `ano_decisao` (derivada), mantido como
  campo bruto de checagem.

### `ano_autuacao`
- **Tipo:** integer
- **Descrição:** Ano extraído de `data_de_autuacao`.
- **Valores possíveis / exemplo:** `2016`, `2024`
- **Fonte:** Derivada — `R/01_carregamento_categorizacao.R` via
  `lubridate::year(data_de_autuacao)`.
- **Observações:** —

### `ano_decisao`
- **Tipo:** integer
- **Descrição:** Ano extraído de `data_da_decisao`.
- **Valores possíveis / exemplo:** `2016`, `2025`
- **Fonte:** Derivada — `R/01_carregamento_categorizacao.R` via
  `lubridate::year(data_da_decisao)`.
- **Observações:** Variável usada nas figuras 02 e 09.

### `anos_tramitacao`
- **Tipo:** numeric (decimal)
- **Descrição:** Tempo de tramitação em anos, da autuação à decisão.
- **Valores possíveis / exemplo:** `0.4407939767...`, `7.83`
- **Fonte:** Derivada — `R/01_carregamento_categorizacao.R`.
- **Observações:** Calculada como `(data_da_decisao - data_de_autuacao) / 365.25`
  (média que absorve anos bissextos). No CSV o separador decimal é **ponto**:
  `readr::write_csv()` ignora a configuração global `options(OutDec = ",")`.
  Para apresentação em tabelas humanizadas, o pipeline usa `formatC()` com
  vírgula (ex.: `"1,81"`).

### `indicador_de_tramitacao`
- **Tipo:** character ("Sim" / "Não")
- **Descrição:** Flag bruta do STF indicando se o processo ainda tramita.
- **Valores possíveis / exemplo:** `Sim`, `Não`
- **Fonte:** Portal Corte Aberta do STF.
- **Observações:** No corpus desta pesquisa todos os casos têm decisão final
  registrada; o campo é mantido para auditoria.

---

## 4. Forma de julgamento

### `meio_processo`
- **Tipo:** character
- **Descrição:** Canal de tramitação do processo no STF.
- **Valores possíveis / exemplo:** `ELETRÔNICO`
- **Fonte:** Portal Corte Aberta do STF.
- **Observações:** Em caixa alta, conforme o extrato bruto.

### `origem_decisao`
- **Tipo:** character
- **Descrição:** Indica o órgão que proferiu a decisão classificada em
  `andamento_decisao`.
- **Valores possíveis / exemplo:** `TRIBUNAL PLENO`, `PRESIDÊNCIA`, `MIN.
  RELATOR`
- **Fonte:** Portal Corte Aberta do STF.
- **Observações:** Em caixa alta. Complementa `indicador_colegiado` e
  `orgao_julgador`.

### `orgao_julgador`
- **Tipo:** character
- **Descrição:** Colegiado (ou autoridade monocrática) responsável pelo
  julgamento.
- **Valores possíveis / exemplo:** `TRIBUNAL PLENO`
- **Fonte:** Portal Corte Aberta do STF.
- **Observações:** Em geral coincide com `origem_decisao`; mantido como
  campo bruto distinto para auditoria.

### `ambiente_julgamento`
- **Tipo:** character
- **Descrição:** Formato bruto do julgamento, conforme o STF registra.
- **Valores possíveis / exemplo:** `Presencial`, `Virtual`, `Eletrônico`,
  `Plenário Virtual`
- **Fonte:** Portal Corte Aberta do STF.
- **Observações:** Heterogeneidade de rótulos é tratada na derivada
  `ambiente_simplificado`.

### `ambiente_simplificado`
- **Tipo:** factor (3 níveis, ordenados)
- **Descrição:** Recodificação enxuta do formato de julgamento.
- **Valores possíveis / exemplo:** `Plenário Virtual` → `Plenário Presencial`
  → `Monocrática/Outro`
- **Fonte:** Derivada — `R/01_carregamento_categorizacao.R` (regex
  case-insensitive sobre `ambiente_julgamento`: substring `virtual` ou
  `eletr` → "Plenário Virtual"; `presencial` → "Plenário Presencial";
  demais e NA → "Monocrática/Outro").
- **Observações:** Usada na figura 08 (ambiente × categoria).

### `indicador_colegiado`
- **Tipo:** character (CAIXA ALTA)
- **Descrição:** Flag bruta do STF indicando se a decisão foi colegiada ou
  monocrática.
- **Valores possíveis / exemplo:** `COLEGIADA`, `MONOCRÁTICA`
- **Fonte:** Portal Corte Aberta do STF.
- **Observações:** Apesar do nome sugerir um booleano `Sim/Não`, os valores
  vêm em caixa alta com o rótulo completo. A derivada `modo_decisao`
  normaliza para uso em gráficos.

### `modo_decisao`
- **Tipo:** factor (2 níveis, ordenados)
- **Descrição:** Modo de julgamento, com tipografia padronizada.
- **Valores possíveis / exemplo:** `Colegiada` → `Monocrática`
- **Fonte:** Derivada — `R/01_carregamento_categorizacao.R` (substring
  case-insensitive em `indicador_colegiado`: `coleg` → "Colegiada";
  `monocr` → "Monocrática").
- **Observações:** A **ordem dos níveis** (Colegiada antes de Monocrática)
  é load-bearing: scripts downstream e a paleta `paleta_modo` assumem essa
  ordem.

---

## 5. Objeto e tema

### `ramo_direito`
- **Tipo:** character (lista separada por `|`)
- **Descrição:** Classificação temática do STF por ramos do Direito.
- **Valores possíveis / exemplo:** `DIREITO ELEITORAL E PROCESSO ELEITORAL DO STF
  | ELEIÇÃO | CAMPANHA ELEITORAL | PROPAGANDA ELEITORAL`
- **Fonte:** Portal Corte Aberta do STF.
- **Observações:** Múltiplos rótulos concatenados pelo separador `|`. Pode ser
  desempilhado com `tidyr::separate_rows(ramo_direito, sep = "\\|")` para
  análises por tópico.

### `assuntos_do_processo`
- **Tipo:** character (lista separada por `|`)
- **Descrição:** Tags temáticas mais granulares atribuídas pelo STF.
- **Valores possíveis / exemplo:** `DIREITO ELEITORAL | ELEIÇÕES | PROPAGANDA
  POLÍTICA - PROPAGANDA ELEITORAL | PROPAGANDA POLÍTICA - PROPAGANDA
  ELEITORAL - DEBATE POLÍTICO`
- **Fonte:** Portal Corte Aberta do STF.
- **Observações:** Em geral parcialmente redundante com `ramo_direito` (uma
  é refinamento da outra). Mesmo critério de desempilhamento.

### `descricao_procedencia_processo`
- **Tipo:** character
- **Descrição:** Unidade federativa (ou âmbito federal) de origem da norma
  impugnada.
- **Valores possíveis / exemplo:** `DISTRITO FEDERAL`, `SÃO PAULO`
- **Fonte:** Portal Corte Aberta do STF.
- **Observações:** Em caixa alta. Não recodificada no pipeline atual.

### `descricao_orgao_origem`
- **Tipo:** character
- **Descrição:** Órgão ou instituição cuja norma foi impugnada.
- **Valores possíveis / exemplo:** `SUPREMO TRIBUNAL FEDERAL`, `CONGRESSO NACIONAL`
- **Fonte:** Portal Corte Aberta do STF.
- **Observações:** Em caixa alta. Permite cruzar a ADI com o tipo de norma
  contestada (lei federal, resolução do TSE, EC etc.).

---

## 6. Decisão e desfecho

### `tipo_decisao`
- **Tipo:** character
- **Descrição:** Natureza processual da decisão registrada.
- **Valores possíveis / exemplo:** `Decisão Final`
- **Fonte:** Portal Corte Aberta do STF.
- **Observações:** No corpus atual, todas as linhas são "Decisão Final" — o
  critério de inclusão exige decisão terminativa. Mantido para auditoria.

### `andamento_decisao`
- **Tipo:** character
- **Descrição:** Resultado da decisão final, conforme rotulado pelo STF.
- **Valores possíveis / exemplo:** `Procedente`, `Procedente em parte`,
  `Improcedente`, `Não conhecido(s)`, `Negado seguimento`, `Prejudicado`
- **Fonte:** Portal Corte Aberta do STF.
- **Observações:** Variável-fonte da derivada `categoria_analise`. Distribuição
  detalhada na figura 01.

### `categoria_analise`
- **Tipo:** factor (3 níveis, ordenados)
- **Descrição:** Agrupamento analítico de `andamento_decisao` em três classes
  substantivas para a análise do TCC.
- **Valores possíveis / exemplo:** `Mérito` → `Prejudicado` → `Sem mérito`
- **Fonte:** Derivada — `R/01_carregamento_categorizacao.R` via `case_when`
  sobre `andamento_decisao`:
  - `Procedente`, `Improcedente`, `Procedente em parte` → **Mérito**
  - `Prejudicado` → **Prejudicado**
  - `Não conhecido(s)`, `Negado seguimento` → **Sem mérito**
- **Observações:** A **ordem dos níveis** (Mérito → Prejudicado → Sem mérito)
  é load-bearing: paletas (`paleta_categoria`) e gráficos downstream assumem
  essa ordem. A categoria "Sem mérito" é o foco da hipótese de tramitação
  pós-eleitoral (seção 7).

### `observacao_do_andamento`
- **Tipo:** character (texto longo)
- **Descrição:** Sumário textual da decisão e/ou ata de julgamento, contendo
  fundamentação, placar e ministros vencidos/vencedores.
- **Valores possíveis / exemplo:** trechos da ordem de centenas a milhares de
  caracteres, em prosa.
- **Fonte:** Portal Corte Aberta do STF.
- **Observações:** Não utilizada quantitativamente; serve para consulta
  qualitativa caso-a-caso (auditoria das classificações).

---

## 7. Variáveis derivadas do calendário eleitoral

> As quatro variáveis a seguir **não estão** em
> `data/interim/adis_categorizadas.csv`. Elas são geradas por
> `R/04_analise_temporal.R` e persistidas em
> `data/processed/adis_com_calendario.rds`. O calendário de referência inclui
> os pleitos de **2016, 2018, 2020, 2022, 2024 e 2026** (primeiros turnos),
> com a eleição municipal de 2020 adiada para 15/11 por força da EC 107/2020
> e a data de 2026 projetada a partir do art. 1º da Lei 9.504/1997.

### `n_eleicoes_durante_tramitacao`
- **Tipo:** integer
- **Descrição:** Quantidade de pleitos (federais ou municipais) cuja data
  cai no intervalo `[data_de_autuacao, data_da_decisao]`.
- **Valores possíveis / exemplo:** `0`, `1`, `2`
- **Fonte:** Derivada — `R/04_analise_temporal.R`.
- **Observações:** Métrica central do diagnóstico "tramitação cruzou eleição"
  reportado na figura 09 e no console do script 04.

### `proxima_eleicao_apos_decisao`
- **Tipo:** Date
- **Descrição:** Menor data de eleição **estritamente posterior** à
  `data_da_decisao`.
- **Valores possíveis / exemplo:** `2018-10-07`, `2026-10-04`, `NA`
- **Fonte:** Derivada — `R/04_analise_temporal.R`.
- **Observações:** Vale `NA` quando a decisão é posterior à última eleição do
  calendário (atualmente, decisões posteriores a 04/10/2026).

### `dias_ate_proxima_eleicao_apos_decisao`
- **Tipo:** integer (dias)
- **Descrição:** Diferença em dias entre `proxima_eleicao_apos_decisao` e
  `data_da_decisao`.
- **Valores possíveis / exemplo:** `45`, `412`, `NA`
- **Fonte:** Derivada — `R/04_analise_temporal.R`.
- **Observações:** Sempre não-negativa por construção (já que a eleição é
  estritamente posterior à decisão). `NA` segue a regra de
  `proxima_eleicao_apos_decisao`.

### `decidida_antes_da_eleicao_relevante`
- **Tipo:** logical
- **Descrição:** Indica se o STF decidiu com antecedência compatível com o
  princípio da anterioridade eleitoral (art. 16 da CF, 1 ano).
- **Valores possíveis / exemplo:** `TRUE`, `FALSE`, `NA`
- **Fonte:** Derivada — `R/04_analise_temporal.R`.
- **Observações:** `TRUE` quando `dias_ate_proxima_eleicao_apos_decisao >= 365`;
  `FALSE` quando `< 365`; `NA` quando não há eleição posterior no calendário.
  O limiar de 365 dias replica, por analogia, a regra constitucional aplicada
  a leis eleitorais — seguindo Marchetti, Fleischer e Vieira.
