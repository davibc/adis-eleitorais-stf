# Índice de figuras — ADIs eleitorais (STF, 2016-2026)

> Gerado automaticamente por `R/03_visualizacoes.R` em 24/05/2026.

Cada figura está disponível em PNG (300 dpi, para inserção em manuscritos)
e em SVG (vetorial, para edição em Inkscape/Illustrator).

---

## Figura 1 — `fig01_distribuicao_andamentos`

Frequência absoluta de cada rótulo bruto de andamento da decisão final,
em barras horizontais ordenadas do mais ao menos frequente. Mostra a
composição do corpus sem agrupamentos analíticos.

## Figura 2 — `fig02_decisoes_por_ano`

Decisões finais por ano (2016-2026), em barras empilhadas pela categoria
analítica (mérito / sem mérito / prejudicado). Permite visualizar a
intensidade temporal da atividade decisória e a composição de cada ano.

## Figura 3 — `fig03_modo_categoria`

Cruzamento entre modo de decisão (colegiada vs. monocrática) e categoria
analítica, em barras agrupadas com rótulos numéricos. Destaca o achado de
que decisões de mérito tendem a ser colegiadas e não-decisões
(prejudicialidade, não conhecimento) tendem a ser monocráticas.

## Figura 4 — `fig04_tempo_tramitacao_boxplot`

Distribuição do tempo de tramitação (anos entre autuação e decisão) por
categoria analítica. Boxplot com pontos individuais sobrepostos (jitter)
para revelar o N modesto; losango branco marca a média e a linha central
do box marca a mediana.

## Figura 5 — `fig05_relatores`

Volume de ADIs por ministro relator, em barras horizontais empilhadas pela
categoria analítica. Relatores ordenados por carga total decrescente.
Permite identificar concentração de relatoria e padrões individuais.

## Figura 6 — `fig06_heatmap_relator_andamento`

Heatmap relator × andamento bruto. Intensidade de azul codifica a
contagem; rótulos numéricos em cada célula. Combinações inexistentes
aparecem em branco (zero). Útil para detectar padrões idiossincráticos
de cada relator.

## Figura 7 — `fig07_linha_tempo_adis`

Linha do tempo individual de cada ADI: segmento horizontal indo da
autuação (círculo vazado) à decisão (ponto cheio), colorido pela
categoria. ADIs ordenadas verticalmente pela data de autuação (mais
antiga no topo). Visualiza o tempo de tramitação caso a caso.

## Figura 8 — `fig08_ambiente_categoria`

Barras proporcionais (empilhamento normalizado a 100%) cruzando o
ambiente de julgamento simplificado (Plenário Virtual / Presencial /
Monocrática) com a categoria analítica. Rótulos exibem N e percentual
intra-grupo. Cada coluna traz o N do ambiente correspondente.

---

## Convenções cromáticas

- **Paleta de categoria analítica** (figs. 2, 3, 4, 5, 7, 8):
  azul = mérito, laranja = sem mérito, roxo = prejudicado.
- **Paleta de resultado bruto** (fig. 1): verdes = procedência total/
  parcial; vermelho = improcedência; tons de cinza = não-mérito e
  prejudicialidade.
- **Gradiente do heatmap** (fig. 6): branco (zero) → azul escuro (máximo).

Todas as paletas foram escolhidas para preservar contraste em deuteranopia/
protanopia e em impressão preto-e-branco. Ver `R/utils/tema_grafico.R`.
