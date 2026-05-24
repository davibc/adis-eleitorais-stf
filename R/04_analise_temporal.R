# =============================================================================
# 04_analise_temporal.R
# -----------------------------------------------------------------------------
# Propósito
#   Construir as variáveis temporais que dão sustentação à discussão sobre
#   controle de agenda judicial e anterioridade eleitoral no STF. Cruza a
#   tramitação de cada ADI (autuação → decisão) com o calendário das eleições
#   federais e municipais de 2016 a 2026 e gera tabela, figura e base
#   enriquecida.
#
# Inputs
#   - data/interim/adis_categorizadas.rds
#
# Outputs
#   - output/tabelas/tempo_calendario_eleitoral.csv
#       Uma linha por ADI com andamento + 3 variáveis temporais derivadas.
#   - output/figuras/fig09_tramitacao_e_eleicoes.{png,svg}
#       Linha do tempo das ADIs com sobreposição do calendário eleitoral.
#   - data/processed/adis_com_calendario.rds
#       Base canônica para os scripts analíticos seguintes.
#
# Ordem no pipeline
#   00_setup.R
#   01_carregamento_categorizacao.R
#   02_descritivas.R
#   03_visualizacoes.R
#   04_analise_temporal.R   <-- este script
#
# Autor: Davi Barbosa
# =============================================================================


# -----------------------------------------------------------------------------
# 0. Setup, tema e diretórios de saída
# -----------------------------------------------------------------------------
source(here::here("R", "00_setup.R"))
source(here::here("R", "utils", "tema_grafico.R"))

fs::dir_create(here::here("data", "processed"))
fs::dir_create(here::here("output", "tabelas"))
fs::dir_create(here::here("output", "figuras"))


# -----------------------------------------------------------------------------
# 1. Carregamento da base tratada
# -----------------------------------------------------------------------------
adis <- readRDS(here::here("data", "interim", "adis_categorizadas.rds"))


# -----------------------------------------------------------------------------
# 2. Calendário das eleições federais e municipais (2016-2026)
# -----------------------------------------------------------------------------
# Datas dos primeiros turnos. A eleição municipal de 2020 foi adiada para
# novembro em razão da pandemia de COVID-19 (EC 107/2020). A data de 2026 é
# uma projeção: pelo art. 1º, caput, da Lei 9.504/1997, o pleito ocorre no
# primeiro domingo de outubro do ano eleitoral — em 2026, 04/10. A data
# final será confirmada por resolução do TSE.
calendario_eleitoral <- tibble::tribble(
  ~ano,  ~tipo,        ~data_eleicao,
  2016L, "municipal",  as.Date("2016-10-02"),
  2018L, "geral",      as.Date("2018-10-07"),
  2020L, "municipal",  as.Date("2020-11-15"),  # adiada — pandemia
  2022L, "geral",      as.Date("2022-10-02"),
  2024L, "municipal",  as.Date("2024-10-06"),
  2026L, "geral",      as.Date("2026-10-04")   # projeção: 1º domingo de outubro
)


# -----------------------------------------------------------------------------
# 3. Variáveis temporais por ADI
# -----------------------------------------------------------------------------
# Sobre a anterioridade de 1 ano (art. 16 da CF):
#
#   "Art. 16. A lei que alterar o processo eleitoral entrará em vigor na
#    data de sua publicação, não se aplicando à eleição que ocorra até um
#    ano da data de sua vigência."
#
# A regra constitucional fixa um período de 365 dias entre a vigência da
# norma e a eleição em que ela poderá incidir. Por analogia (e seguindo a
# literatura sobre judicialização eleitoral — Marchetti, Fleischer e
# Vieira), usamos o mesmo limiar de 1 ano como teste do desfecho do
# controle de constitucionalidade: decisões do STF proferidas a menos de
# 365 dias da próxima eleição não cumprem o princípio da anterioridade e
# tendem a ter eficácia diferida para o pleito subsequente.
#
# Operacionalização:
#   n_eleicoes_durante_tramitacao :
#       quantos pleitos do calendário caem em [data_de_autuacao,
#       data_da_decisao].
#   proxima_eleicao_apos_decisao :
#       menor data_eleicao estritamente posterior a data_da_decisao
#       (NA se a decisão for posterior à última eleição do calendário).
#   dias_ate_proxima_eleicao_apos_decisao :
#       diferença em dias entre proxima_eleicao_apos_decisao e
#       data_da_decisao.
#   decidida_antes_da_eleicao_relevante :
#       TRUE se >= 365 dias; FALSE se < 365; NA se não há eleição posterior
#       no calendário.
adis_enriquecidas <- adis |>
  dplyr::rowwise() |>
  dplyr::mutate(
    n_eleicoes_durante_tramitacao = sum(
      calendario_eleitoral$data_eleicao >= data_de_autuacao &
        calendario_eleitoral$data_eleicao <= data_da_decisao
    ),
    proxima_eleicao_apos_decisao = {
      candidatas <- calendario_eleitoral$data_eleicao[
        calendario_eleitoral$data_eleicao > data_da_decisao
      ]
      if (length(candidatas) == 0L) as.Date(NA) else min(candidatas)
    }
  ) |>
  dplyr::ungroup() |>
  dplyr::mutate(
    dias_ate_proxima_eleicao_apos_decisao =
      as.integer(proxima_eleicao_apos_decisao - data_da_decisao),
    decidida_antes_da_eleicao_relevante =
      dias_ate_proxima_eleicao_apos_decisao >= 365L
  )


# -----------------------------------------------------------------------------
# 4. Tabela: tempo_calendario_eleitoral.csv
# -----------------------------------------------------------------------------
# Uma linha por ADI: identificador, andamento bruto e as três variáveis
# temporais. Ordenada pelo número do processo para facilitar auditoria.
tempo_calendario_eleitoral <- adis_enriquecidas |>
  dplyr::select(
    processo,
    andamento_decisao,
    n_eleicoes_durante_tramitacao,
    dias_ate_proxima_eleicao_apos_decisao,
    decidida_antes_da_eleicao_relevante
  ) |>
  dplyr::arrange(processo)

readr::write_csv(
  tempo_calendario_eleitoral,
  here::here("output", "tabelas", "tempo_calendario_eleitoral.csv")
)


# -----------------------------------------------------------------------------
# 5. Diagnósticos no console
# -----------------------------------------------------------------------------
n_total       <- nrow(adis_enriquecidas)
n_com_eleicao <- sum(adis_enriquecidas$n_eleicoes_durante_tramitacao >= 1L,
                     na.rm = TRUE)

cat("\n=== ADIs com pelo menos 1 eleição durante a tramitação ===\n")
cat(sprintf(
  "%d de %d ADIs (%s)\n",
  n_com_eleicao, n_total,
  scales::percent(n_com_eleicao / n_total, accuracy = 0.1, decimal.mark = ",")
))

cat("\n=== Média de eleições durante a tramitação, por categoria ===\n")
print(
  adis_enriquecidas |>
    dplyr::group_by(categoria_analise) |>
    dplyr::summarise(
      n               = dplyr::n(),
      media_eleicoes  = round(mean(n_eleicoes_durante_tramitacao, na.rm = TRUE), 2),
      .groups         = "drop"
    )
)

cat("\n=== Casos 'Sem mérito': eleições passando antes do não-conhecimento ===\n")
sem_merito  <- adis_enriquecidas |>
  dplyr::filter(categoria_analise == "Sem mérito")
n_sm_com_el <- sum(sem_merito$n_eleicoes_durante_tramitacao >= 1L, na.rm = TRUE)
cat(sprintf(
  "%d de %d ADIs sem mérito (%s) tiveram >= 1 eleição entre a autuação e a decisão.\n",
  n_sm_com_el, nrow(sem_merito),
  scales::percent(n_sm_com_el / max(nrow(sem_merito), 1L),
                  accuracy = 0.1, decimal.mark = ",")
))


# -----------------------------------------------------------------------------
# 6. Figura 9 — Tramitação cruzada com o calendário eleitoral
# -----------------------------------------------------------------------------
# Linha do tempo no estilo da fig07, acrescida de linhas verticais cinzas
# nas datas das eleições do período. ADIs cuja tramitação cruza pelo menos
# uma eleição são desenhadas com traço mais grosso.
caption_fonte <- paste0(
  "Fonte: elaboração própria com base em dados do STF ",
  "(jurisprudencia.stf.jus.br)."
)

df_fig09 <- adis_enriquecidas |>
  dplyr::filter(!is.na(data_de_autuacao), !is.na(data_da_decisao)) |>
  dplyr::arrange(data_de_autuacao) |>
  dplyr::mutate(
    processo      = factor(processo, levels = unique(processo)),
    cruza_eleicao = dplyr::if_else(n_eleicoes_durante_tramitacao >= 1L,
                                   "sim", "nao")
  )

fig09 <- ggplot2::ggplot(
  df_fig09,
  ggplot2::aes(y = processo)
) +
  # Linhas verticais cinzas: datas das eleições.
  ggplot2::geom_vline(
    data = calendario_eleitoral,
    ggplot2::aes(xintercept = data_eleicao),
    colour = "#9E9E9E", linetype = "dashed", linewidth = 0.4
  ) +
  # Tramitação: linewidth maior para quem cruza eleição.
  ggplot2::geom_segment(
    ggplot2::aes(
      x      = data_de_autuacao,
      xend   = data_da_decisao,
      yend   = processo,
      colour = categoria_analise,
      linewidth = cruza_eleicao
    )
  ) +
  # Autuação: círculo vazado.
  ggplot2::geom_point(
    ggplot2::aes(x = data_de_autuacao, colour = categoria_analise),
    shape = 21, fill = "white", size = 2.3, stroke = 0.8
  ) +
  # Decisão: ponto cheio.
  ggplot2::geom_point(
    ggplot2::aes(x = data_da_decisao, colour = categoria_analise),
    shape = 16, size = 2.3
  ) +
  # Rótulos das eleições, ancorados acima do topo do painel.
  ggplot2::annotate(
    "text",
    x        = calendario_eleitoral$data_eleicao,
    y        = nlevels(df_fig09$processo) + 0.9,
    label    = paste0(calendario_eleitoral$tipo, "\n", calendario_eleitoral$ano),
    size     = 2.6,
    colour   = "#555555",
    lineheight = 0.9,
    vjust    = 0
  ) +
  ggplot2::scale_colour_manual(values = paleta_categoria, drop = FALSE) +
  ggplot2::scale_linewidth_manual(
    values = c(sim = 1.6, nao = 0.7),
    guide  = "none"
  ) +
  ggplot2::scale_x_date(
    date_breaks = "1 year", date_labels = "%Y",
    expand = ggplot2::expansion(mult = c(0.02, 0.02))
  ) +
  ggplot2::coord_cartesian(clip = "off") +
  ggplot2::labs(
    title    = "Tramitação das ADIs e calendário eleitoral",
    subtitle = "Linha grossa = ADI cuja tramitação cruzou ao menos uma eleição",
    x        = NULL,
    y        = NULL,
    colour   = NULL,
    caption  = caption_fonte
  ) +
  tema_pesquisa() +
  ggplot2::theme(
    panel.grid.major.y = ggplot2::element_line(colour = "#F5F5F5", linewidth = 0.3),
    panel.grid.major.x = ggplot2::element_blank(),
    axis.text.y        = ggplot2::element_text(size = 7),
    # Margem superior ampliada para acomodar os rótulos das eleições.
    plot.margin        = ggplot2::margin(t = 28, r = 14, b = 10, l = 10)
  )

print(fig09)

# PNG (300 dpi) + SVG nas mesmas dimensões.
ggplot2::ggsave(
  filename = here::here("output", "figuras", "fig09_tramitacao_e_eleicoes.png"),
  plot     = fig09,
  width    = 18, height = 23, units = "cm",
  dpi      = 300, bg = "white"
)
ggplot2::ggsave(
  filename = here::here("output", "figuras", "fig09_tramitacao_e_eleicoes.svg"),
  plot     = fig09,
  width    = 18, height = 23, units = "cm",
  bg       = "white"
)


# -----------------------------------------------------------------------------
# 7. Persistência: base enriquecida em data/processed/
# -----------------------------------------------------------------------------
# Esta é a base canônica para os scripts analíticos seguintes — preserva os
# tipos (factor, Date, integer) e inclui as novas variáveis temporais.
saveRDS(
  adis_enriquecidas,
  file = here::here("data", "processed", "adis_com_calendario.rds")
)

message("\n[04_analise_temporal] Tabela, figura e base enriquecida salvas.")
