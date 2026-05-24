# =============================================================================
# tema_grafico.R
# -----------------------------------------------------------------------------
# Propósito
#   Centralizar a identidade visual dos gráficos do projeto: um tema ggplot2
#   reutilizável (tema_pesquisa()) e três paletas categóricas nomeadas,
#   semanticamente alinhadas às variáveis-chave da análise.
#
# Uso
#   source(here::here("R", "utils", "tema_grafico.R"))
#
#   ggplot(...) +
#     geom_col(aes(fill = categoria_analise)) +
#     scale_fill_manual(values = paleta_categoria) +
#     tema_pesquisa()
#
# Princípios de design
#   - Mínimo de tinta não-informativa (apenas grid horizontal sutil).
#   - Hierarquia tipográfica clara (título > subtítulo > eixos > caption).
#   - Paletas pensadas para reprodução em preto-e-branco e para legibilidade
#     por pessoas com daltonismo do tipo deutan/protan (a forma mais comum,
#     ~8% dos homens). Pares críticos contrastam não só em matiz mas também
#     em luminância.
# =============================================================================


# -----------------------------------------------------------------------------
# 1. Tema gráfico
# -----------------------------------------------------------------------------
#' Tema gráfico do projeto
#'
#' Tema ggplot2 minimalista com fundo branco, grid horizontal sutil,
#' tipografia hierarquizada e legenda inferior sem título.
#'
#' @param base_size Tamanho de fonte base, em pt. Default: 11.
#' @param base_family Família tipográfica. Default: "sans" (genérica,
#'   disponível em qualquer SO sem instalação adicional).
#'
#' @return Um objeto ggplot2::theme.
tema_pesquisa <- function(base_size = 11, base_family = "sans") {

  ggplot2::theme_minimal(
    base_size   = base_size,
    base_family = base_family
  ) +
    ggplot2::theme(

      # --- Fundo e painel ---------------------------------------------------
      plot.background  = ggplot2::element_rect(fill = "white", colour = NA),
      panel.background = ggplot2::element_rect(fill = "white", colour = NA),

      # --- Grid: apenas horizontal, cinza muito claro -----------------------
      # Eixo Y horizontal porque a leitura comparativa em gráficos de barras
      # / pontos se dá por altura — linhas horizontais sutis ancoram a
      # comparação sem competir com os dados.
      panel.grid.major.y = ggplot2::element_line(colour = "#EEEEEE", linewidth = 0.4),
      panel.grid.major.x = ggplot2::element_blank(),
      panel.grid.minor   = ggplot2::element_blank(),

      # --- Eixos ------------------------------------------------------------
      axis.line  = ggplot2::element_line(colour = "#4D4D4D", linewidth = 0.3),
      axis.ticks = ggplot2::element_line(colour = "#4D4D4D", linewidth = 0.3),
      axis.text  = ggplot2::element_text(colour = "#333333",
                                         size   = ggplot2::rel(0.9)),
      axis.title = ggplot2::element_text(colour = "#333333",
                                         size   = ggplot2::rel(0.95)),

      # --- Títulos do gráfico -----------------------------------------------
      # Centralizados (hjust = 0.5) sobre toda a área do plot (não só o
      # painel), via plot.title.position = "plot". Isso evita que rótulos
      # longos no eixo Y empurrem o título visualmente para a direita.
      plot.title = ggplot2::element_text(
        size   = 13,
        face   = "bold",
        hjust  = 0.5,
        colour = "#111111",
        margin = ggplot2::margin(b = 4)
      ),
      plot.subtitle = ggplot2::element_text(
        size   = 10,
        hjust  = 0.5,
        colour = "#555555",
        margin = ggplot2::margin(b = 10)
      ),
      plot.caption = ggplot2::element_text(
        size   = 8,
        hjust  = 0.5,
        colour = "#777777",
        margin = ggplot2::margin(t = 8)
      ),
      plot.title.position   = "plot",
      plot.caption.position = "plot",

      # --- Legenda ----------------------------------------------------------
      # Posição inferior libera largura horizontal para os dados e funciona
      # bem em layouts de relatório (largura > altura). Sem título por
      # default: a maioria das legendas é autoexplicativa quando o aes() está
      # bem mapeado; o título pode ser reativado pontualmente via
      # + labs(fill = "...") ou + theme(legend.title = element_text()).
      legend.position   = "bottom",
      legend.title      = ggplot2::element_blank(),
      legend.text       = ggplot2::element_text(size = ggplot2::rel(0.9),
                                                colour = "#333333"),
      legend.key        = ggplot2::element_blank(),
      legend.background = ggplot2::element_blank(),

      # --- Strips (facets) --------------------------------------------------
      strip.background = ggplot2::element_blank(),
      strip.text       = ggplot2::element_text(face = "bold", size = ggplot2::rel(0.95),
                                               colour = "#333333"),

      # --- Margens externas -------------------------------------------------
      plot.margin = ggplot2::margin(t = 10, r = 14, b = 10, l = 10)
    )
}


# -----------------------------------------------------------------------------
# 2. Paletas categóricas nomeadas
# -----------------------------------------------------------------------------
# Nomeadas para permitir o uso direto em scale_*_manual(values = paleta_x):
# a correspondência cor <-> nível é definida pelos *nomes* do vetor, não pela
# ordem — robusto à reordenação de fatores em diferentes gráficos.


# -----------------------------------------------------------------------------
# 2.1 Paleta de resultado (Andamento da decisão)
# -----------------------------------------------------------------------------
# Lógica semântica:
#   - Verdes  -> procedência (alinhado à expectativa do leitor: verde = ação
#                judicial bem-sucedida na perspectiva do autor da ADI).
#   - Vermelho -> improcedência (contraste semântico claro).
#   - Cinzas  -> desfechos que não tocaram o mérito (não conhecido, negado
#                seguimento, prejudicado) — desaturados intencionalmente para
#                "recuar" visualmente em relação às decisões de mérito.
#
# Daltonismo:
#   O par crítico verde escuro (#1B5E20) vs vermelho (#C62828) tem luminância
#   bastante distinta (verde mais escuro), o que mantém a distinção em
#   simulações de deuteranopia/protanopia. Em impressão P&B, o verde escuro
#   também fica mais escuro que o vermelho.
#
# Hierarquia dentro do grupo "sem mérito":
#   três tons de cinza decrescentes em saturação/contraste permitem
#   distinguir os três rótulos sem competir com os de mérito.
paleta_resultado <- c(
  "Procedente"          = "#1B5E20",  # verde escuro
  "Procedente em parte" = "#7CB342",  # verde médio
  "Improcedente"        = "#C62828",  # vermelho
  "Não conhecido(s)"    = "#757575",  # cinza médio
  "Negado seguimento"   = "#9E9E9E",  # cinza claro
  "Prejudicado"         = "#BDBDBD"   # cinza mais claro
)


# -----------------------------------------------------------------------------
# 2.2 Paleta de categoria analítica (agrupamento de desfecho)
# -----------------------------------------------------------------------------
# Três níveis bem separados em matiz E luminância — funciona em deutan/protan
# e em P&B. Azul/laranja é o par canônico "colorblind-safe" (base de várias
# paletas, e.g. Okabe-Ito); o roxo escuro acrescenta uma terceira categoria
# sem colidir com nenhum dos dois.
paleta_categoria <- c(
  "Mérito"      = "#1565C0",  # azul     — categoria substantivamente central
  "Sem mérito"  = "#FF8F00",  # laranja  — par cromático de máximo contraste
  "Prejudicado" = "#6A1B9A"   # roxo     — terceira via, distinta em matiz
)


# -----------------------------------------------------------------------------
# 2.3 Paleta de modo de decisão (Colegiada vs. Monocrática)
# -----------------------------------------------------------------------------
# Apenas dois níveis: usamos azul escuro e laranja escuro, novamente o par
# safe-for-colorblind. Ambos foram escurecidos em relação à paleta_categoria
# para sugerir, visualmente, que se trata de um corte estrutural (modo de
# julgamento) e não de uma classificação de desfecho.
paleta_modo <- c(
  "Colegiada"   = "#283593",  # azul escuro   — institucional, "pleno/turma"
  "Monocrática" = "#EF6C00"   # laranja escuro — destaque para decisão solo
)


# -----------------------------------------------------------------------------
# 3. Mensagem de carga (silenciosa em produção, útil em desenvolvimento)
# -----------------------------------------------------------------------------
if (interactive()) {
  message("[tema_grafico] tema_pesquisa() e paletas (resultado/categoria/modo) carregados.")
}
