# =============================================================================
# 01_carregamento_categorizacao.R
# -----------------------------------------------------------------------------
# Propósito
#   Carregar a base bruta de ADIs eleitorais (STF, 2016-2026), padronizar nomes
#   de colunas, parsear datas, derivar variáveis analíticas (tempo de
#   tramitação, categoria de desfecho, ambiente de julgamento, modo de decisão)
#   e salvar a base tratada para uso pelos demais scripts do pipeline.
#
# Inputs
#   - data/raw/adis_final.xlsx
#       Planilha bruta extraída do portal do STF, contendo 28 ADIs
#       eleitorais únicas autuadas entre 2016 e 2026 (uma linha por ADI).
#
# Outputs
#   - data/interim/adis_categorizadas.rds
#       Objeto R serializado, preserva tipos (factor, Date) — entrada padrão
#       para os scripts subsequentes.
#   - data/interim/adis_categorizadas.csv
#       Versão em CSV (UTF-8) para inspeção manual e auditoria.
#
# Ordem no pipeline
#   00_setup.R                       (carrega pacotes e configurações)
#   01_carregamento_categorizacao.R  <-- este script
#   02_*.R                           (análises descritivas — a criar)
#
# Autor: Davi Barbosa
# =============================================================================


# -----------------------------------------------------------------------------
# 0. Setup: carrega pacotes e configurações globais
# -----------------------------------------------------------------------------
source(here::here("R", "00_setup.R"))


# -----------------------------------------------------------------------------
# 1. Leitura da planilha bruta e padronização de nomes de colunas
# -----------------------------------------------------------------------------
# read_excel() preserva os tipos detectados; clean_names() converte os
# cabeçalhos para snake_case, removendo acentos e espaços.
adis_brutas <- readxl::read_excel(
  path = here::here("data", "raw", "adis_final.xlsx")
) |>
  janitor::clean_names()


# -----------------------------------------------------------------------------
# 2. Conversão das colunas de data para o formato Date
# -----------------------------------------------------------------------------
# read_excel() devolve células com formato data como POSIXct (e não como
# string). Para esse caso, basta as.Date(). Mantemos um fallback baseado em
# parse_date_time() para o caso de a coluna vir como character em outra
# extração da planilha.
to_date_robust <- function(x) {
  if (inherits(x, c("POSIXt", "Date"))) return(as.Date(x))
  as.Date(lubridate::parse_date_time(
    x,
    orders = c("dmy HMS", "dmy HM", "dmy", "ymd HMS", "ymd HM", "ymd")
  ))
}

adis <- adis_brutas |>
  dplyr::mutate(
    data_de_autuacao = to_date_robust(data_de_autuacao),
    data_da_decisao  = to_date_robust(data_da_decisao)
  )


# -----------------------------------------------------------------------------
# 3. Tempo de tramitação em anos (decisão - autuação) / 365.25
# -----------------------------------------------------------------------------
# Divisão por 365.25 absorve, de forma aproximada, anos bissextos.
adis <- adis |>
  dplyr::mutate(
    anos_tramitacao = as.numeric(data_da_decisao - data_de_autuacao) / 365.25
  )


# -----------------------------------------------------------------------------
# 4. Categoria analítica do desfecho (case_when -> factor ordenado)
# -----------------------------------------------------------------------------
# Agrupa os múltiplos rótulos brutos de 'andamento_decisao' em três classes
# substantivamente relevantes para a análise:
#   - Mérito       : decisões que enfrentaram a inconstitucionalidade alegada
#   - Prejudicado  : perda de objeto, prejudicialidade superveniente etc.
#   - Sem mérito   : não conhecimento ou negativa de seguimento (não chegaram
#                    a enfrentar o mérito da questão)
adis <- adis |>
  dplyr::mutate(
    categoria_analise = dplyr::case_when(
      andamento_decisao %in% c("Procedente",
                               "Improcedente",
                               "Procedente em parte")    ~ "Mérito",
      andamento_decisao == "Prejudicado"                 ~ "Prejudicado",
      andamento_decisao %in% c("Não conhecido(s)",
                               "Negado seguimento")      ~ "Sem mérito",
      TRUE                                               ~ NA_character_
    ),
    categoria_analise = factor(
      categoria_analise,
      levels = c("Mérito", "Prejudicado", "Sem mérito")
    )
  )


# -----------------------------------------------------------------------------
# 5-6. Anos de autuação e de decisão (extraídos das datas já parseadas)
# -----------------------------------------------------------------------------
adis <- adis |>
  dplyr::mutate(
    ano_autuacao = lubridate::year(data_de_autuacao),
    ano_decisao  = lubridate::year(data_da_decisao)
  )


# -----------------------------------------------------------------------------
# 7. Modo de decisão (factor de dois níveis) a partir de indicador_colegiado
# -----------------------------------------------------------------------------
# A coluna bruta traz "COLEGIADA" ou "MONOCRÁTICA" (uppercase). Usamos
# case_when explícito: tudo que não bate em nenhum dos dois padrões vira NA,
# em vez de cair silenciosamente em "Monocrática".
adis <- adis |>
  dplyr::mutate(
    modo_decisao = dplyr::case_when(
      stringr::str_detect(indicador_colegiado, stringr::regex("coleg",  ignore_case = TRUE)) ~ "Colegiada",
      stringr::str_detect(indicador_colegiado, stringr::regex("monocr", ignore_case = TRUE)) ~ "Monocrática",
      TRUE ~ NA_character_
    ),
    modo_decisao = factor(modo_decisao, levels = c("Colegiada", "Monocrática"))
  )


# -----------------------------------------------------------------------------
# 8. Ambiente simplificado (três níveis, tratando NAs)
# -----------------------------------------------------------------------------
# Mapeia os múltiplos rótulos brutos para um esquema enxuto. Usa detecção por
# substring (case-insensitive) para acomodar variações como "Eletrônico",
# "Virtual", "Plenário Virtual", "Presencial" etc.
adis <- adis |>
  dplyr::mutate(
    ambiente_simplificado = dplyr::case_when(
      is.na(ambiente_julgamento) ~ "Monocrática/Outro",
      stringr::str_detect(ambiente_julgamento,
                          stringr::regex("virtual|eletr", ignore_case = TRUE)) ~ "Plenário Virtual",
      stringr::str_detect(ambiente_julgamento,
                          stringr::regex("presencial",   ignore_case = TRUE)) ~ "Plenário Presencial",
      TRUE ~ "Monocrática/Outro"
    ),
    ambiente_simplificado = factor(
      ambiente_simplificado,
      levels = c("Plenário Virtual", "Plenário Presencial", "Monocrática/Outro")
    )
  )


# -----------------------------------------------------------------------------
# 9. Padronização do nome do relator (title case com preposições portuguesas)
# -----------------------------------------------------------------------------
# str_to_title() cru capitalizaria "De/Da/Do" no meio do nome
# ("Min. Celso De Mello"). Esta helper aplica title case e depois
# rebaixa preposições/conectivos quando estão *no meio* do nome.
to_title_pt <- function(x) {
  out <- stringr::str_to_title(x)
  stringr::str_replace_all(
    out,
    c(
      "(?<=\\s)De(?=\\s)"  = "de",
      "(?<=\\s)Da(?=\\s)"  = "da",
      "(?<=\\s)Do(?=\\s)"  = "do",
      "(?<=\\s)Das(?=\\s)" = "das",
      "(?<=\\s)Dos(?=\\s)" = "dos",
      "(?<=\\s)E(?=\\s)"   = "e"
    )
  )
}

adis <- adis |>
  dplyr::mutate(
    relator_atual = to_title_pt(relator_atual)
  )


# -----------------------------------------------------------------------------
# 10. Persistência: rds (canônico) e csv (inspeção)
# -----------------------------------------------------------------------------
# Garante que o diretório de saída existe (idempotente).
fs::dir_create(here::here("data", "interim"))

saveRDS(
  adis,
  file = here::here("data", "interim", "adis_categorizadas.rds")
)

readr::write_csv(
  adis,
  file = here::here("data", "interim", "adis_categorizadas.csv")
)


# -----------------------------------------------------------------------------
# 11. Sumários no console (diagnóstico rápido)
# -----------------------------------------------------------------------------
cat("\n=== Dimensões do data frame final ===\n")
print(dim(adis))

cat("\n=== Distribuição de categoria_analise ===\n")
print(table(adis$categoria_analise, useNA = "ifany"))

cat("\n=== Distribuição de modo_decisao ===\n")
print(table(adis$modo_decisao, useNA = "ifany"))

cat("\n=== Estatísticas de anos_tramitacao ===\n")
print(summary(adis$anos_tramitacao))

message("\n[01_carregamento_categorizacao] Base tratada salva em data/interim/.")
