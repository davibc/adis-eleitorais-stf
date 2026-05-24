# =============================================================================
# 03_visualizacoes.R
# -----------------------------------------------------------------------------
# Propósito
#   Produzir e exportar todas as figuras do artigo a partir da base tratada
#   em 01_carregamento_categorizacao.R. Cada figura é salva em PNG (300 dpi)
#   e em SVG nas mesmas dimensões, prontas para inserção no manuscrito.
#
# Inputs
#   - data/interim/adis_categorizadas.rds
#   - R/utils/tema_grafico.R  (tema_pesquisa() e paletas)
#
# Outputs (em output/figuras/)
#   - fig01_distribuicao_andamentos.{png,svg}
#   - fig02_decisoes_por_ano.{png,svg}
#   - fig03_modo_categoria.{png,svg}
#   - fig04_tempo_tramitacao_boxplot.{png,svg}
#   - fig05_relatores.{png,svg}
#   - fig06_heatmap_relator_andamento.{png,svg}
#   - fig07_linha_tempo_adis.{png,svg}
#   - fig08_ambiente_categoria.{png,svg}
#   - INDEX.md  (catálogo das figuras com legenda explicativa)
#
# Ordem no pipeline
#   00_setup.R
#   01_carregamento_categorizacao.R
#   02_descritivas.R
#   03_visualizacoes.R   <-- este script
#
# Autor: Davi Barbosa
# =============================================================================


# -----------------------------------------------------------------------------
# 0. Setup, tema e paletas
# -----------------------------------------------------------------------------
source(here::here("R", "00_setup.R"))
source(here::here("R", "utils", "tema_grafico.R"))

fs::dir_create(here::here("output", "figuras"))


# -----------------------------------------------------------------------------
# 1. Carregamento dos dados
# -----------------------------------------------------------------------------
adis <- readRDS(here::here("data", "interim", "adis_categorizadas.rds"))


# -----------------------------------------------------------------------------
# 2. Configurações globais das figuras
# -----------------------------------------------------------------------------
caption_fonte <- paste0(
  "Fonte: elaboração própria com base em dados do STF ",
  "(jurisprudencia.stf.jus.br)."
)

# Dimensões padrão (cm) — sobrescrevíveis por figura.
LARG_WIDE   <- 16; ALT_WIDE   <- 10   # gráficos largos
LARG_QUAD   <- 12; ALT_QUAD   <- 12   # gráficos quadrados


# -----------------------------------------------------------------------------
# 3. Helper de exportação (PNG + SVG, mesmas dimensões)
# -----------------------------------------------------------------------------
# `bg = "white"` evita fundo transparente no SVG (útil quando o destino é
# Word/LibreOffice, que renderiza transparência de forma inconsistente).
salvar_figura <- function(plot, nome, largura = LARG_WIDE, altura = ALT_WIDE) {

  caminho_png <- here::here("output", "figuras", paste0(nome, ".png"))
  caminho_svg <- here::here("output", "figuras", paste0(nome, ".svg"))

  ggplot2::ggsave(
    filename = caminho_png, plot = plot,
    width = largura, height = altura, units = "cm",
    dpi = 300, bg = "white"
  )
  ggplot2::ggsave(
    filename = caminho_svg, plot = plot,
    width = largura, height = altura, units = "cm",
    bg = "white"
  )

  invisible(c(png = caminho_png, svg = caminho_svg))
}


# =============================================================================
# FIGURA 1 — Distribuição dos andamentos
# -----------------------------------------------------------------------------
# Barras horizontais com a frequência absoluta de cada rótulo bruto de
# `andamento_decisao`. Ordenação por contagem decrescente (mais frequente no
# topo). Cor pela paleta semântica de resultado.
# =============================================================================
df_fig01 <- adis |>
  dplyr::count(andamento_decisao, name = "n") |>
  dplyr::mutate(
    andamento_decisao = forcats::fct_reorder(andamento_decisao, n)
  )

fig01 <- ggplot2::ggplot(
  df_fig01,
  ggplot2::aes(x = n, y = andamento_decisao, fill = andamento_decisao)
) +
  ggplot2::geom_col(width = 0.7) +
  ggplot2::geom_text(
    ggplot2::aes(label = n),
    hjust = -0.4, size = 3.2, colour = "#333333"
  ) +
  ggplot2::scale_fill_manual(values = paleta_resultado, guide = "none") +
  ggplot2::scale_x_continuous(
    expand = ggplot2::expansion(mult = c(0, 0.12))
  ) +
  ggplot2::labs(
    title    = "Distribuição dos resultados das decisões finais (n=28)",
    subtitle = "ADIs eleitorais — STF, 2016-2026",
    x        = "Número de ADIs",
    y        = NULL,
    caption  = caption_fonte
  ) +
  tema_pesquisa()

print(fig01)
salvar_figura(fig01, "fig01_distribuicao_andamentos")


# =============================================================================
# FIGURA 2 — Decisões por ano (barras empilhadas por categoria)
# -----------------------------------------------------------------------------
# Distribuição temporal das decisões finais, empilhadas por categoria
# analítica. ano_decisao é tratado como factor para garantir um eixo
# discreto contínuo (anos sem decisões aparecem como gaps).
# =============================================================================
anos_observados <- sort(unique(stats::na.omit(adis$ano_decisao)))

df_fig02 <- adis |>
  dplyr::filter(!is.na(ano_decisao), !is.na(categoria_analise)) |>
  dplyr::mutate(
    ano_decisao = factor(ano_decisao,
                         levels = seq(min(anos_observados),
                                      max(anos_observados)))
  )

fig02 <- ggplot2::ggplot(
  df_fig02,
  ggplot2::aes(x = ano_decisao, fill = categoria_analise)
) +
  ggplot2::geom_bar(position = "stack", width = 0.75) +
  ggplot2::scale_fill_manual(values = paleta_categoria, drop = FALSE) +
  ggplot2::scale_x_discrete(drop = FALSE) +
  ggplot2::scale_y_continuous(
    breaks = scales::breaks_pretty(),
    expand = ggplot2::expansion(mult = c(0, 0.08))
  ) +
  ggplot2::labs(
    title   = "Decisões finais de ADIs eleitorais por ano (2016-2026)",
    x       = "Ano da decisão",
    y       = "Número de ADIs",
    fill    = NULL,
    caption = caption_fonte
  ) +
  tema_pesquisa()

print(fig02)
salvar_figura(fig02, "fig02_decisoes_por_ano")


# =============================================================================
# FIGURA 3 — Modo × Categoria (barras agrupadas)
# -----------------------------------------------------------------------------
# Cruzamento visual entre modo de decisão (colegiada/monocrática) e
# categoria analítica do desfecho. Rótulos numéricos sobre cada barra.
# =============================================================================
df_fig03 <- adis |>
  dplyr::filter(!is.na(modo_decisao), !is.na(categoria_analise)) |>
  dplyr::count(modo_decisao, categoria_analise, name = "n")

fig03 <- ggplot2::ggplot(
  df_fig03,
  ggplot2::aes(x = modo_decisao, y = n, fill = categoria_analise)
) +
  ggplot2::geom_col(position = ggplot2::position_dodge(width = 0.8),
                    width = 0.7) +
  ggplot2::geom_text(
    ggplot2::aes(label = n),
    position = ggplot2::position_dodge(width = 0.8),
    vjust = -0.5, size = 3.2, colour = "#333333"
  ) +
  ggplot2::scale_fill_manual(values = paleta_categoria, drop = FALSE) +
  ggplot2::scale_y_continuous(
    expand = ggplot2::expansion(mult = c(0, 0.12))
  ) +
  ggplot2::labs(
    title    = "Modo de decisão e desfecho processual",
    subtitle = "Cruzamento entre modo de decisão e categoria analítica",
    x        = NULL,
    y        = "Número de ADIs",
    fill     = NULL,
    caption  = caption_fonte
  ) +
  tema_pesquisa()

print(fig03)
salvar_figura(fig03, "fig03_modo_categoria")


# =============================================================================
# FIGURA 4 — Tempo de tramitação (boxplot + jitter + média)
# -----------------------------------------------------------------------------
# Distribuição do tempo (anos) entre autuação e decisão por categoria.
# Boxplot com IQR; pontos individuais (jitter horizontal estreito) para não
# mascarar o pequeno N; losango branco marca a média (complemento à mediana
# representada pela linha central do box).
# =============================================================================
df_fig04 <- adis |>
  dplyr::filter(!is.na(categoria_analise), !is.na(anos_tramitacao))

fig04 <- ggplot2::ggplot(
  df_fig04,
  ggplot2::aes(x = categoria_analise, y = anos_tramitacao,
               fill = categoria_analise, colour = categoria_analise)
) +
  ggplot2::geom_boxplot(
    width = 0.45, alpha = 0.35,
    outlier.shape = NA, colour = "#333333"
  ) +
  ggplot2::geom_jitter(width = 0.15, alpha = 0.6, size = 1.8) +
  ggplot2::stat_summary(
    fun = mean, geom = "point",
    shape = 23, size = 3, fill = "white", colour = "#111111", stroke = 0.6
  ) +
  ggplot2::scale_fill_manual(values = paleta_categoria, guide = "none") +
  ggplot2::scale_colour_manual(values = paleta_categoria, guide = "none") +
  ggplot2::scale_y_continuous(
    breaks = scales::breaks_pretty(n = 6),
    labels = function(x) formatC(x, format = "f", digits = 1, decimal.mark = ",")
  ) +
  ggplot2::labs(
    title    = "Tempo de tramitação entre autuação e decisão, por categoria",
    subtitle = "Losango branco = média; linha central = mediana",
    x        = NULL,
    y        = "Anos",
    caption  = caption_fonte
  ) +
  tema_pesquisa()

print(fig04)
salvar_figura(fig04, "fig04_tempo_tramitacao_boxplot")


# =============================================================================
# FIGURA 5 — Volume por relator (barras horizontais empilhadas)
# -----------------------------------------------------------------------------
# Cada barra é um ministro relator; a composição da barra mostra como suas
# ADIs se distribuíram entre as categorias. Relatores ordenados pelo total
# (maior carga no topo).
# =============================================================================
df_fig05 <- adis |>
  dplyr::filter(!is.na(relator_atual), !is.na(categoria_analise)) |>
  dplyr::count(relator_atual, categoria_analise, name = "n") |>
  dplyr::group_by(relator_atual) |>
  dplyr::mutate(total = sum(n)) |>
  dplyr::ungroup() |>
  dplyr::mutate(relator_atual = forcats::fct_reorder(relator_atual, total))

fig05 <- ggplot2::ggplot(
  df_fig05,
  ggplot2::aes(y = relator_atual, x = n, fill = categoria_analise)
) +
  ggplot2::geom_col(width = 0.7) +
  ggplot2::scale_fill_manual(values = paleta_categoria, drop = FALSE) +
  ggplot2::scale_x_continuous(
    breaks = scales::breaks_pretty(),
    expand = ggplot2::expansion(mult = c(0, 0.05))
  ) +
  ggplot2::labs(
    title   = "Distribuição das ADIs por ministro relator e desfecho",
    x       = "Número de ADIs",
    y       = NULL,
    fill    = NULL,
    caption = caption_fonte
  ) +
  tema_pesquisa()

print(fig05)
# Largura ampliada (18 cm): nomes de ministro no eixo Y deslocam o painel
# para a direita, e o título não cabe em 16 cm.
salvar_figura(fig05, "fig05_relatores", largura = 18, altura = 11)


# =============================================================================
# FIGURA 6 — Heatmap relator × andamento
# -----------------------------------------------------------------------------
# Padrão decisório por relator. Células brancas indicam ausência da
# combinação no corpus; intensidade de azul cresce com a contagem.
# Cor do texto adapta-se ao fundo (preto sobre claro, branco sobre escuro)
# para preservar legibilidade.
# =============================================================================
df_fig06 <- adis |>
  dplyr::filter(!is.na(relator_atual), !is.na(andamento_decisao)) |>
  dplyr::count(relator_atual, andamento_decisao, name = "n") |>
  tidyr::complete(relator_atual, andamento_decisao, fill = list(n = 0)) |>
  dplyr::group_by(relator_atual) |>
  dplyr::mutate(total_relator = sum(n)) |>
  dplyr::ungroup() |>
  dplyr::mutate(
    relator_atual = forcats::fct_reorder(relator_atual, total_relator)
  )

# Limiar para alternar cor do texto (metade do máximo).
limite_cor_texto <- max(df_fig06$n, na.rm = TRUE) / 2

fig06 <- ggplot2::ggplot(
  df_fig06,
  ggplot2::aes(x = andamento_decisao, y = relator_atual, fill = n)
) +
  ggplot2::geom_tile(colour = "white", linewidth = 0.4) +
  ggplot2::geom_text(
    ggplot2::aes(
      label  = n,
      colour = n > limite_cor_texto
    ),
    size = 3, fontface = "bold"
  ) +
  ggplot2::scale_fill_gradient(
    low = "#F5F8FC", high = "#0D47A1",
    name = "ADIs"
  ) +
  ggplot2::scale_colour_manual(
    values = c(`TRUE` = "white", `FALSE` = "#333333"),
    guide  = "none"
  ) +
  ggplot2::labs(
    title   = "Padrão decisório por ministro relator",
    x       = NULL,
    y       = NULL,
    caption = caption_fonte
  ) +
  tema_pesquisa() +
  ggplot2::theme(
    panel.grid  = ggplot2::element_blank(),
    axis.line   = ggplot2::element_blank(),
    axis.ticks  = ggplot2::element_blank(),
    # Rótulos de andamento são longos; inclinamos 25° (alinhados pela direita
    # via hjust = 1) para evitar sobreposição. Rodapé (default) é mais
    # confortável que o topo, que disputaria espaço com o título.
    axis.text.x = ggplot2::element_text(angle = 25, hjust = 1)
  )

print(fig06)
# Dimensões ampliadas: nomes longos no eixo X + nomes de relator no eixo Y.
salvar_figura(fig06, "fig06_heatmap_relator_andamento",
              largura = 18, altura = 13)


# =============================================================================
# FIGURA 7 — Linha do tempo de cada ADI
# -----------------------------------------------------------------------------
# Cada ADI é uma linha horizontal indo da autuação à decisão. ADIs ordenadas
# por data de autuação (mais antiga no rodapé, mais recente no topo —
# convenção de barras: o eixo Y categórico cresce para cima). Símbolo aberto
# na autuação, ponto cheio na decisão. Cor pela categoria analítica.
# Dimensões verticais ampliadas (≈ 0,6 cm por ADI) para acomodar 28 linhas.
# =============================================================================
df_fig07 <- adis |>
  dplyr::filter(!is.na(data_de_autuacao), !is.na(data_da_decisao)) |>
  dplyr::arrange(data_de_autuacao) |>
  dplyr::mutate(processo = factor(processo, levels = unique(processo)))

fig07 <- ggplot2::ggplot(
  df_fig07,
  ggplot2::aes(y = processo, colour = categoria_analise)
) +
  ggplot2::geom_segment(
    ggplot2::aes(x = data_de_autuacao, xend = data_da_decisao,
                 y = processo,         yend = processo),
    linewidth = 0.9
  ) +
  # Autuação: símbolo aberto (círculo vazado branco)
  ggplot2::geom_point(
    ggplot2::aes(x = data_de_autuacao),
    shape = 21, fill = "white", size = 2.3, stroke = 0.8
  ) +
  # Decisão: ponto cheio
  ggplot2::geom_point(
    ggplot2::aes(x = data_da_decisao),
    shape = 16, size = 2.3
  ) +
  ggplot2::scale_colour_manual(values = paleta_categoria, drop = FALSE) +
  ggplot2::scale_x_date(
    date_breaks = "1 year", date_labels = "%Y",
    expand = ggplot2::expansion(mult = c(0.02, 0.02))
  ) +
  ggplot2::labs(
    title    = "Linha do tempo de cada ADI no corpus",
    subtitle = "Círculo vazado = autuação; ponto cheio = decisão final",
    x        = NULL,
    y        = NULL,
    colour   = NULL,
    caption  = caption_fonte
  ) +
  tema_pesquisa() +
  ggplot2::theme(
    panel.grid.major.y = ggplot2::element_line(colour = "#F5F5F5", linewidth = 0.3),
    panel.grid.major.x = ggplot2::element_line(colour = "#EEEEEE", linewidth = 0.3),
    axis.text.y        = ggplot2::element_text(size = 7)
  )

print(fig07)
# Altura ≈ 0,6 cm por ADI + margens.
salvar_figura(fig07, "fig07_linha_tempo_adis", largura = 16, altura = 22)


# =============================================================================
# FIGURA 8 — Ambiente × Categoria (barras proporcionais)
# -----------------------------------------------------------------------------
# Proporção de cada categoria analítica dentro de cada ambiente de
# julgamento. Eixo X mostra o ambiente (com N total entre parênteses);
# eixo Y, proporção. Rótulos internos trazem N (xx,x%) por célula.
# =============================================================================
df_fig08 <- adis |>
  dplyr::filter(!is.na(ambiente_simplificado), !is.na(categoria_analise)) |>
  dplyr::count(ambiente_simplificado, categoria_analise, name = "n") |>
  dplyr::group_by(ambiente_simplificado) |>
  dplyr::mutate(p = n / sum(n), total = sum(n)) |>
  dplyr::ungroup() |>
  dplyr::mutate(
    rotulo_x = paste0(ambiente_simplificado, "\n(n=", total, ")"),
    rotulo_x = forcats::fct_reorder(rotulo_x, total, .desc = TRUE)
  )

fig08 <- ggplot2::ggplot(
  df_fig08,
  ggplot2::aes(x = rotulo_x, y = p, fill = categoria_analise)
) +
  ggplot2::geom_col(width = 0.65) +
  ggplot2::geom_text(
    ggplot2::aes(label = paste0(
      n, " (",
      formatC(100 * p, format = "f", digits = 1, decimal.mark = ","), "%)"
    )),
    position = ggplot2::position_stack(vjust = 0.5),
    colour = "white", size = 3.1, lineheight = 0.9
  ) +
  ggplot2::scale_fill_manual(values = paleta_categoria, drop = FALSE) +
  ggplot2::scale_y_continuous(
    labels = scales::label_percent(accuracy = 1),
    expand = ggplot2::expansion(mult = c(0, 0.05))
  ) +
  ggplot2::labs(
    title   = "Ambiente de julgamento e desfecho processual",
    x       = NULL,
    y       = "Proporção de ADIs",
    fill    = NULL,
    caption = caption_fonte
  ) +
  tema_pesquisa()

print(fig08)
salvar_figura(fig08, "fig08_ambiente_categoria")


# -----------------------------------------------------------------------------
# 4. INDEX.md — catálogo das figuras
# -----------------------------------------------------------------------------
index_md <- paste(
  "# Índice de figuras — ADIs eleitorais (STF, 2016-2026)",
  "",
  paste0("> Gerado automaticamente por `R/03_visualizacoes.R` em ",
         format(Sys.Date(), "%d/%m/%Y"), "."),
  "",
  "Cada figura está disponível em PNG (300 dpi, para inserção em manuscritos)",
  "e em SVG (vetorial, para edição em Inkscape/Illustrator).",
  "",
  "---",
  "",
  "## Figura 1 — `fig01_distribuicao_andamentos`",
  "",
  "Frequência absoluta de cada rótulo bruto de andamento da decisão final,",
  "em barras horizontais ordenadas do mais ao menos frequente. Mostra a",
  "composição do corpus sem agrupamentos analíticos.",
  "",
  "## Figura 2 — `fig02_decisoes_por_ano`",
  "",
  "Decisões finais por ano (2016-2026), em barras empilhadas pela categoria",
  "analítica (mérito / sem mérito / prejudicado). Permite visualizar a",
  "intensidade temporal da atividade decisória e a composição de cada ano.",
  "",
  "## Figura 3 — `fig03_modo_categoria`",
  "",
  "Cruzamento entre modo de decisão (colegiada vs. monocrática) e categoria",
  "analítica, em barras agrupadas com rótulos numéricos. Destaca o achado de",
  "que decisões de mérito tendem a ser colegiadas e não-decisões",
  "(prejudicialidade, não conhecimento) tendem a ser monocráticas.",
  "",
  "## Figura 4 — `fig04_tempo_tramitacao_boxplot`",
  "",
  "Distribuição do tempo de tramitação (anos entre autuação e decisão) por",
  "categoria analítica. Boxplot com pontos individuais sobrepostos (jitter)",
  "para revelar o N modesto; losango branco marca a média e a linha central",
  "do box marca a mediana.",
  "",
  "## Figura 5 — `fig05_relatores`",
  "",
  "Volume de ADIs por ministro relator, em barras horizontais empilhadas pela",
  "categoria analítica. Relatores ordenados por carga total decrescente.",
  "Permite identificar concentração de relatoria e padrões individuais.",
  "",
  "## Figura 6 — `fig06_heatmap_relator_andamento`",
  "",
  "Heatmap relator × andamento bruto. Intensidade de azul codifica a",
  "contagem; rótulos numéricos em cada célula. Combinações inexistentes",
  "aparecem em branco (zero). Útil para detectar padrões idiossincráticos",
  "de cada relator.",
  "",
  "## Figura 7 — `fig07_linha_tempo_adis`",
  "",
  "Linha do tempo individual de cada ADI: segmento horizontal indo da",
  "autuação (círculo vazado) à decisão (ponto cheio), colorido pela",
  "categoria. ADIs ordenadas verticalmente pela data de autuação (mais",
  "antiga no topo). Visualiza o tempo de tramitação caso a caso.",
  "",
  "## Figura 8 — `fig08_ambiente_categoria`",
  "",
  "Barras proporcionais (empilhamento normalizado a 100%) cruzando o",
  "ambiente de julgamento simplificado (Plenário Virtual / Presencial /",
  "Monocrática) com a categoria analítica. Rótulos exibem N e percentual",
  "intra-grupo. Cada coluna traz o N do ambiente correspondente.",
  "",
  "---",
  "",
  "## Convenções cromáticas",
  "",
  "- **Paleta de categoria analítica** (figs. 2, 3, 4, 5, 7, 8):",
  "  azul = mérito, laranja = sem mérito, roxo = prejudicado.",
  "- **Paleta de resultado bruto** (fig. 1): verdes = procedência total/",
  "  parcial; vermelho = improcedência; tons de cinza = não-mérito e",
  "  prejudicialidade.",
  "- **Gradiente do heatmap** (fig. 6): branco (zero) → azul escuro (máximo).",
  "",
  "Todas as paletas foram escolhidas para preservar contraste em deuteranopia/",
  "protanopia e em impressão preto-e-branco. Ver `R/utils/tema_grafico.R`.",
  sep = "\n"
)

writeLines(
  index_md,
  con = here::here("output", "figuras", "INDEX.md"),
  useBytes = TRUE
)

message("\n[03_visualizacoes] 8 figuras (PNG + SVG) e INDEX.md salvos em output/figuras/.")
