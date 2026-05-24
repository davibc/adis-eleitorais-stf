# =============================================================================
# 02_descritivas.R
# -----------------------------------------------------------------------------
# Propósito
#   Produzir as estatísticas descritivas do corpus de 28 ADIs eleitorais
#   julgadas pelo STF entre 2016 e 2026: panorama geral, distribuição de
#   resultados, cruzamentos entre modo de decisão e categoria, volume por
#   relator, distribuição temporal e tempo de tramitação por categoria.
#
# Inputs
#   - data/interim/adis_categorizadas.rds   (gerado por 01_carregamento_*.R)
#
# Outputs (em output/tabelas/)
#   - panorama_geral.{csv,html}
#   - distribuicao_resultados.{csv,html}
#   - cruzamento_modo_categoria.{csv,html}
#   - relator_volume.{csv,html}
#   - ano_decisao_categoria.{csv,html}
#   - tempo_por_categoria.{csv,html}
#   - sumario_executivo.md   (texto narrativo para o capítulo descritivo)
#
# Ordem no pipeline
#   00_setup.R
#   01_carregamento_categorizacao.R
#   02_descritivas.R   <-- este script
#
# Observação
#   Este script NÃO gera gráficos. Visualizações ficam em 03_*.R.
#
# Autor: Davi Barbosa
# =============================================================================


# -----------------------------------------------------------------------------
# 0. Setup
# -----------------------------------------------------------------------------
source(here::here("R", "00_setup.R"))

# Garante que o diretório de saída existe (idempotente).
fs::dir_create(here::here("output", "tabelas"))


# -----------------------------------------------------------------------------
# 1. Carregamento da base tratada
# -----------------------------------------------------------------------------
adis <- readRDS(here::here("data", "interim", "adis_categorizadas.rds"))

# Sanidade: o corpus deve ter 28 linhas.
if (nrow(adis) != 28L) {
  warning(sprintf(
    "Esperadas 28 ADIs no corpus; encontradas %d. Verifique 01_carregamento_*.",
    nrow(adis)
  ))
}


# -----------------------------------------------------------------------------
# 2. Helpers de formatação (pt-BR: vírgula decimal, percentual com 1 casa)
# -----------------------------------------------------------------------------
# Definidos localmente (evita dependência adicional). Reutilizados em todas
# as tabelas e no sumário narrativo.

# Formata número decimal com `digits` casas e vírgula como separador decimal.
fmt_num <- function(x, digits = 2) {
  formatC(x, format = "f", digits = digits, decimal.mark = ",", big.mark = ".")
}

# Formata percentual: recebe proporção [0,1] e retorna string "xx,x%".
fmt_pct <- function(p, digits = 1) {
  paste0(formatC(100 * p, format = "f", digits = digits, decimal.mark = ","), "%")
}

# Atalho: salva uma tabela gt como HTML e o data frame original como CSV.
salvar_tabela <- function(df, gt_obj, nome) {
  caminho_csv  <- here::here("output", "tabelas", paste0(nome, ".csv"))
  caminho_html <- here::here("output", "tabelas", paste0(nome, ".html"))

  readr::write_csv(df, caminho_csv)
  gt::gtsave(gt_obj, filename = caminho_html)

  invisible(list(csv = caminho_csv, html = caminho_html))
}


# -----------------------------------------------------------------------------
# 3. Tabela 1 — panorama_geral
# -----------------------------------------------------------------------------
# Long-format (indicador, valor) com contagens, proporções e estatísticas de
# tempo. `valor` é character: mistura inteiros, percentuais e decimais
# já formatados em pt-BR — pronto para colar em texto sem reprocessamento.

n_total <- nrow(adis)

n_categoria <- table(adis$categoria_analise, useNA = "no")
n_modo      <- table(adis$modo_decisao,       useNA = "no")

panorama_geral <- tibble::tribble(
  ~indicador,                          ~valor,
  "Total de ADIs no corpus",           as.character(n_total),
  "Decisões de mérito",                sprintf("%d (%s)",
                                               n_categoria["Mérito"],
                                               fmt_pct(n_categoria["Mérito"] / n_total)),
  "Decisões sem mérito",               sprintf("%d (%s)",
                                               n_categoria["Sem mérito"],
                                               fmt_pct(n_categoria["Sem mérito"] / n_total)),
  "ADIs prejudicadas",                 sprintf("%d (%s)",
                                               n_categoria["Prejudicado"],
                                               fmt_pct(n_categoria["Prejudicado"] / n_total)),
  "Decisões monocráticas",             sprintf("%d (%s)",
                                               n_modo["Monocrática"],
                                               fmt_pct(n_modo["Monocrática"] / n_total)),
  "Decisões colegiadas",               sprintf("%d (%s)",
                                               n_modo["Colegiada"],
                                               fmt_pct(n_modo["Colegiada"] / n_total)),
  "Tempo médio de tramitação (anos)",  fmt_num(mean(adis$anos_tramitacao,   na.rm = TRUE)),
  "Tempo mediano de tramitação (anos)",fmt_num(median(adis$anos_tramitacao, na.rm = TRUE)),
  "Tempo máximo (anos)",               fmt_num(max(adis$anos_tramitacao,    na.rm = TRUE)),
  "Tempo mínimo (anos)",               fmt_num(min(adis$anos_tramitacao,    na.rm = TRUE))
)

panorama_gt <- panorama_geral |>
  gt::gt() |>
  gt::tab_header(
    title    = "Panorama geral do corpus",
    subtitle = "ADIs eleitorais — STF, 2016-2026"
  ) |>
  gt::cols_label(indicador = "Indicador", valor = "Valor") |>
  gt::tab_source_note("Fonte: portal do STF (elaboração própria).")

salvar_tabela(panorama_geral, panorama_gt, "panorama_geral")


# -----------------------------------------------------------------------------
# 4. Tabela 2 — distribuicao_resultados
# -----------------------------------------------------------------------------
# Frequência absoluta e relativa de cada rótulo bruto de andamento_decisao,
# ordenada por N decrescente.
distribuicao_resultados <- adis |>
  dplyr::count(Andamento = andamento_decisao, name = "N", sort = TRUE) |>
  dplyr::mutate(Percentual = fmt_pct(N / sum(N)))

distribuicao_gt <- distribuicao_resultados |>
  gt::gt() |>
  gt::tab_header(
    title    = "Distribuição dos andamentos de decisão",
    subtitle = sprintf("N = %d ADIs", n_total)
  ) |>
  gt::cols_align(align = "left",  columns = Andamento) |>
  gt::cols_align(align = "right", columns = c(N, Percentual)) |>
  gt::tab_source_note("Fonte: portal do STF (elaboração própria).")

salvar_tabela(distribuicao_resultados, distribuicao_gt, "distribuicao_resultados")


# -----------------------------------------------------------------------------
# 5. Tabela 3 — cruzamento_modo_categoria  (Modo × Categoria, % por linha)
# -----------------------------------------------------------------------------
# Cada célula traz "N (xx,x%)" onde o percentual é calculado sobre o total
# da linha (sobre o total de cada modo de decisão). Última coluna e última
# linha trazem os totais marginais.

# Contagens brutas em formato longo.
contagens <- adis |>
  dplyr::filter(!is.na(modo_decisao), !is.na(categoria_analise)) |>
  dplyr::count(modo_decisao, categoria_analise, name = "n") |>
  dplyr::group_by(modo_decisao) |>
  dplyr::mutate(p_linha = n / sum(n)) |>
  dplyr::ungroup() |>
  dplyr::mutate(celula = sprintf("%d (%s)", n, fmt_pct(p_linha)))

# Pivot para formato wide (linhas = modo, colunas = categoria).
cruzamento_modo_categoria <- contagens |>
  dplyr::select(modo_decisao, categoria_analise, celula) |>
  tidyr::pivot_wider(
    names_from  = categoria_analise,
    values_from = celula,
    values_fill = "0 (0,0%)"
  ) |>
  dplyr::rename(Modo = modo_decisao) |>
  dplyr::mutate(Modo = as.character(Modo))

# Total marginal por modo (linha).
totais_linha <- adis |>
  dplyr::filter(!is.na(modo_decisao)) |>
  dplyr::count(Modo = modo_decisao, name = "Total") |>
  dplyr::mutate(Total = sprintf("%d (100,0%%)", Total))

cruzamento_modo_categoria <- cruzamento_modo_categoria |>
  dplyr::left_join(totais_linha, by = "Modo")

# Linha de totais marginais por categoria (coluna).
totais_coluna <- adis |>
  dplyr::filter(!is.na(categoria_analise)) |>
  dplyr::count(categoria_analise, name = "n") |>
  dplyr::mutate(celula = sprintf("%d (%s)", n, fmt_pct(n / sum(n)))) |>
  dplyr::select(-n) |>
  tidyr::pivot_wider(names_from = categoria_analise, values_from = celula) |>
  dplyr::mutate(Modo = "Total", Total = sprintf("%d (100,0%%)", n_total)) |>
  dplyr::select(Modo, dplyr::everything())

cruzamento_modo_categoria <- dplyr::bind_rows(cruzamento_modo_categoria, totais_coluna)

cruzamento_gt <- cruzamento_modo_categoria |>
  gt::gt() |>
  gt::tab_header(
    title    = "Modo de decisão × categoria analítica",
    subtitle = "N (% por linha)"
  ) |>
  gt::tab_source_note("Percentuais calculados sobre o total de cada linha.")

salvar_tabela(cruzamento_modo_categoria, cruzamento_gt, "cruzamento_modo_categoria")


# -----------------------------------------------------------------------------
# 6. Tabela 4 — relator_volume
# -----------------------------------------------------------------------------
# Por relator: total de ADIs, decomposição por categoria e taxa de mérito.
relator_volume <- adis |>
  dplyr::filter(!is.na(relator_atual), !is.na(categoria_analise)) |>
  dplyr::mutate(categoria_analise = as.character(categoria_analise)) |>
  dplyr::count(Relator = relator_atual, categoria_analise, name = "n") |>
  tidyr::pivot_wider(
    names_from  = categoria_analise,
    values_from = n,
    values_fill = 0L
  )

# Garante a existência das três colunas de categoria mesmo que alguma esteja
# ausente nos dados (e.g. nenhum relator com "Prejudicado").
for (col in c("Mérito", "Sem mérito", "Prejudicado")) {
  if (!col %in% names(relator_volume)) {
    relator_volume[[col]] <- 0L
  }
}

relator_volume <- relator_volume |>
  dplyr::mutate(
    `Total ADIs` = Mérito + `Sem mérito` + Prejudicado,
    `% Mérito`   = fmt_pct(Mérito / `Total ADIs`)
  ) |>
  dplyr::select(Relator, `Total ADIs`, Mérito, `Sem mérito`, Prejudicado, `% Mérito`) |>
  dplyr::arrange(dplyr::desc(`Total ADIs`), Relator)

relator_gt <- relator_volume |>
  gt::gt() |>
  gt::tab_header(
    title    = "Volume de ADIs por relator",
    subtitle = "Decomposição por categoria analítica"
  ) |>
  gt::tab_source_note("Fonte: portal do STF (elaboração própria).")

salvar_tabela(relator_volume, relator_gt, "relator_volume")


# -----------------------------------------------------------------------------
# 7. Tabela 5 — ano_decisao_categoria  (Ano × Categoria)
# -----------------------------------------------------------------------------
ano_decisao_categoria <- adis |>
  dplyr::filter(!is.na(ano_decisao), !is.na(categoria_analise)) |>
  dplyr::count(Ano = ano_decisao, categoria_analise, name = "n") |>
  tidyr::pivot_wider(
    names_from  = categoria_analise,
    values_from = n,
    values_fill = 0L
  ) |>
  dplyr::arrange(Ano)

# Garante presença das três colunas de categoria.
for (col in c("Mérito", "Sem mérito", "Prejudicado")) {
  if (!col %in% names(ano_decisao_categoria)) {
    ano_decisao_categoria[[col]] <- 0L
  }
}

ano_decisao_categoria <- ano_decisao_categoria |>
  dplyr::mutate(Total = Mérito + `Sem mérito` + Prejudicado) |>
  dplyr::select(Ano, Mérito, `Sem mérito`, Prejudicado, Total)

# Linha de totais marginais. Convertemos Ano para character para que o rótulo
# "Total" apareça tanto no CSV quanto no HTML (em vez de NA no CSV).
ano_decisao_categoria <- ano_decisao_categoria |>
  dplyr::mutate(Ano = as.character(Ano))

linha_total_ano <- tibble::tibble(
  Ano          = "Total",
  Mérito       = sum(ano_decisao_categoria$Mérito),
  `Sem mérito` = sum(ano_decisao_categoria$`Sem mérito`),
  Prejudicado  = sum(ano_decisao_categoria$Prejudicado),
  Total        = sum(ano_decisao_categoria$Total)
)

ano_decisao_categoria <- dplyr::bind_rows(ano_decisao_categoria, linha_total_ano)

ano_decisao_gt <- ano_decisao_categoria |>
  gt::gt() |>
  gt::tab_header(
    title    = "Ano da decisão × categoria analítica",
    subtitle = "Contagens absolutas"
  ) |>
  gt::tab_source_note("Fonte: portal do STF (elaboração própria).")

salvar_tabela(ano_decisao_categoria, ano_decisao_gt, "ano_decisao_categoria")


# -----------------------------------------------------------------------------
# 8. Tabela 6 — tempo_por_categoria
# -----------------------------------------------------------------------------
# Descritivas de anos_tramitacao por categoria_analise.
tempo_por_categoria <- adis |>
  dplyr::filter(!is.na(categoria_analise), !is.na(anos_tramitacao)) |>
  dplyr::group_by(Categoria = categoria_analise) |>
  dplyr::summarise(
    N        = dplyr::n(),
    Média    = fmt_num(mean(anos_tramitacao)),
    Mediana  = fmt_num(median(anos_tramitacao)),
    `Desvio padrão` = fmt_num(stats::sd(anos_tramitacao)),
    Mínimo   = fmt_num(min(anos_tramitacao)),
    Máximo   = fmt_num(max(anos_tramitacao)),
    Q1       = fmt_num(stats::quantile(anos_tramitacao, 0.25, names = FALSE)),
    Q3       = fmt_num(stats::quantile(anos_tramitacao, 0.75, names = FALSE)),
    .groups  = "drop"
  )

tempo_gt <- tempo_por_categoria |>
  gt::gt() |>
  gt::tab_header(
    title    = "Tempo de tramitação por categoria",
    subtitle = "Anos entre autuação e decisão"
  ) |>
  gt::tab_source_note("Fonte: portal do STF (elaboração própria).")

salvar_tabela(tempo_por_categoria, tempo_gt, "tempo_por_categoria")


# -----------------------------------------------------------------------------
# 9. Impressão no console com cabeçalhos descritivos
# -----------------------------------------------------------------------------
imprimir_tabela <- function(titulo, gt_obj) {
  cat("\n", strrep("=", 70), "\n", sep = "")
  cat(titulo, "\n")
  cat(strrep("=", 70), "\n\n", sep = "")
  print(gt_obj)
}

imprimir_tabela("Tabela 1 — Panorama geral do corpus",                panorama_gt)
imprimir_tabela("Tabela 2 — Distribuição dos andamentos de decisão",  distribuicao_gt)
imprimir_tabela("Tabela 3 — Modo × Categoria (% por linha)",          cruzamento_gt)
imprimir_tabela("Tabela 4 — Volume por relator",                       relator_gt)
imprimir_tabela("Tabela 5 — Ano da decisão × Categoria",               ano_decisao_gt)
imprimir_tabela("Tabela 6 — Tempo de tramitação por categoria",        tempo_gt)


# -----------------------------------------------------------------------------
# 10. Sumário executivo (Markdown)
# -----------------------------------------------------------------------------
# Texto narrativo em pt-BR com os principais números já interpretados, pronto
# para ser colado no capítulo descritivo do artigo.

# Computa valores que entram no texto.
n_merito       <- as.integer(n_categoria["Mérito"])
n_sem_merito   <- as.integer(n_categoria["Sem mérito"])
n_prejudicado  <- as.integer(n_categoria["Prejudicado"])
n_colegiada    <- as.integer(n_modo["Colegiada"])
n_monocratica  <- as.integer(n_modo["Monocrática"])

p_merito       <- n_merito      / n_total
p_sem_merito   <- n_sem_merito  / n_total
p_prejudicado  <- n_prejudicado / n_total
p_colegiada    <- n_colegiada   / n_total
p_monocratica  <- n_monocratica / n_total

tempo_media    <- mean(adis$anos_tramitacao,   na.rm = TRUE)
tempo_mediana  <- median(adis$anos_tramitacao, na.rm = TRUE)
tempo_min      <- min(adis$anos_tramitacao,    na.rm = TRUE)
tempo_max      <- max(adis$anos_tramitacao,    na.rm = TRUE)

ano_min_aut    <- min(adis$ano_autuacao, na.rm = TRUE)
ano_max_dec    <- max(adis$ano_decisao,  na.rm = TRUE)

# Andamento mais frequente (linha mais alta de distribuicao_resultados).
andamento_top  <- distribuicao_resultados$Andamento[1]
n_andamento_top<- distribuicao_resultados$N[1]
p_andamento_top<- n_andamento_top / n_total

# Relator com mais ADIs (linha 1 de relator_volume).
relator_top    <- relator_volume$Relator[1]
n_relator_top  <- relator_volume$`Total ADIs`[1]

# Predominância de modo (texto narrativo).
modo_predominante <- if (p_colegiada >= p_monocratica) {
  list(rotulo = "colegiadas",   n = n_colegiada,   p = p_colegiada)
} else {
  list(rotulo = "monocráticas", n = n_monocratica, p = p_monocratica)
}

# Monta o markdown.
texto_md <- glue::glue(
"# Sumário executivo — ADIs eleitorais (STF, {ano_min_aut}–{ano_max_dec})

> Documento gerado automaticamente em {format(Sys.Date(), '%d/%m/%Y')} \\
> pelo script `R/02_descritivas.R`. Os números são recalculados a cada \\
> execução; o texto narrativo segue um esqueleto fixo.

## Visão geral

O corpus reúne **{n_total} ADIs** de matéria eleitoral autuadas e julgadas pelo \\
Supremo Tribunal Federal entre {ano_min_aut} e {ano_max_dec}. Cada linha da base \\
corresponde a uma ADI única (deduplicação manual).

Das {n_total} ações analisadas, **{n_merito} ({fmt_pct(p_merito)})** receberam \\
decisão de mérito (procedente, parcialmente procedente ou improcedente); \\
**{n_sem_merito} ({fmt_pct(p_sem_merito)})** não tiveram o mérito enfrentado \\
(não conhecidas ou negado seguimento); e \\
**{n_prejudicado} ({fmt_pct(p_prejudicado)})** foram declaradas prejudicadas.

## Modo de decisão

Predominaram as decisões **{modo_predominante$rotulo}**: \\
{modo_predominante$n} de {n_total} ADIs ({fmt_pct(modo_predominante$p)}). \\
As decisões colegiadas somam {n_colegiada} ({fmt_pct(p_colegiada)}), e as \\
monocráticas, {n_monocratica} ({fmt_pct(p_monocratica)}).

## Tempo de tramitação

O intervalo entre autuação e decisão variou de **{fmt_num(tempo_min)}** a \\
**{fmt_num(tempo_max)} anos**, com média de **{fmt_num(tempo_media)} anos** \\
e mediana de **{fmt_num(tempo_mediana)} anos**. A discrepância entre média e \\
mediana sinaliza assimetria na distribuição dos tempos — sintoma típico de \\
poucas ADIs com tramitação muito longa puxando a média para cima.

## Andamento mais frequente

O rótulo de andamento mais comum foi **\"{andamento_top}\"**, com \\
{n_andamento_top} ocorrências ({fmt_pct(p_andamento_top)} do corpus).

## Relatoria com maior volume

A relatoria com mais ADIs eleitorais no período foi **{relator_top}**, \\
com {n_relator_top} ações sob sua condução.

---

*Para detalhamentos, consultar:*

- `panorama_geral.csv` — indicadores agregados.
- `distribuicao_resultados.csv` — frequência de cada rótulo de andamento.
- `cruzamento_modo_categoria.csv` — modo × categoria, com percentuais por linha.
- `relator_volume.csv` — decomposição por relator.
- `ano_decisao_categoria.csv` — distribuição temporal.
- `tempo_por_categoria.csv` — descritivas de tempo de tramitação por categoria.
",
.trim = FALSE
)

writeLines(
  texto_md,
  con = here::here("output", "tabelas", "sumario_executivo.md"),
  useBytes = TRUE
)

message("\n[02_descritivas] Tabelas e sumário executivo salvos em output/tabelas/.")
