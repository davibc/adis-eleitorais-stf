# Análise Empírica de ADIs Eleitorais no STF (2016–2026)

Projeto de pesquisa em R para análise empírica de Ações Diretas de
Inconstitucionalidade (ADIs) de matéria eleitoral julgadas pelo Supremo Tribunal
Federal entre 2016 e 2026. O objetivo é descrever padrões decisórios, taxas de
procedência, tempos de tramitação, relatorias, partes legitimadas, dispositivos
impugnados e desfechos a partir de dados extraídos do portal do STF.

---

## Estrutura do repositório

```
projeto/
├── data/
│   ├── raw/              # Dados brutos (originais, imutáveis)
│   ├── interim/          # Dados intermediários (limpeza parcial)
│   └── processed/        # Dados prontos para análise
├── R/
│   ├── 00_setup.R        # Carregamento de pacotes e configurações globais
│   └── utils/            # Funções auxiliares reutilizáveis
├── output/
│   ├── figuras/          # Gráficos gerados pelos scripts
│   └── tabelas/          # Tabelas exportadas (gt, xlsx, csv)
├── docs/
│   └── codebook.md       # Dicionário das variáveis da base
├── notebooks/            # Cadernos exploratórios (Rmd / Quarto)
├── renv/                 # Ambiente reprodutível (gerenciado pelo renv)
├── renv.lock             # Lockfile com versões exatas dos pacotes
├── .gitignore
└── README.md
```

---

## Como reproduzir

### Pré-requisitos

- **R** ≥ 4.3.0
- **RStudio** (recomendado) ou outro front-end de sua preferência
- Sistema operacional: Windows, macOS ou Linux

### Passo a passo

1. **Clone o repositório** (ou copie a pasta para sua máquina).

2. **Abra o projeto no RStudio** (`File → Open Project`), garantindo que o
   diretório de trabalho aponte para a raiz do projeto.

3. **Instale o `renv`**, caso ainda não o tenha:

   ```r
   install.packages("renv")
   ```

4. **Restaure o ambiente**, instalando todos os pacotes nas versões travadas
   no `renv.lock`:

   ```r
   renv::restore()
   ```

5. **Execute os scripts em ordem numérica**, a partir da pasta `R/`:

   ```r
   source(here::here("R", "00_setup.R"))     # Carrega pacotes
   # source(here::here("R", "01_import.R"))  # (a criar) Importa dados brutos
   # source(here::here("R", "02_clean.R"))   # (a criar) Limpeza e padronização
   # source(here::here("R", "03_analyze.R")) # (a criar) Análises descritivas
   # source(here::here("R", "04_figures.R")) # (a criar) Geração de gráficos
   # source(here::here("R", "05_tables.R"))  # (a criar) Geração de tabelas
   ```

> Todos os caminhos no projeto são construídos com o pacote `here`, garantindo
> portabilidade entre sistemas operacionais.

---

## Fonte dos dados

Os dados primários foram extraídos do **Portal Corte Aberta, do Supremo Tribunal Federal**
(<https://portal.stf.jus.br/hotsites/corteaberta/>), via consulta pública de jurisprudência e acompanhamento processual. A base bruta consolidada (`adis_final.xlsx`) reúne as ADIs de matéria eleitoral autuadas e/ou julgadas no período de **janeiro/2016 a [data de corte a definir]/2026**.

A documentação detalhada das variáveis está em
[`docs/codebook.md`](docs/codebook.md).

---

## Autoria

**Davi Barbosa Costa**
Contato: barbosadavi05@gmail.com

---

## Nota sobre o uso de IA na construção do código

Parte do código deste repositório foi escrita com auxílio de ferramentas de
inteligência artificial generativa (notadamente Claude, da Anthropic), em
caráter de assistência à programação. Todas as decisões metodológicas,
escolhas analíticas, interpretações substantivas e a revisão final do código
são de responsabilidade exclusiva do autor. As fontes de dados, os métodos
estatísticos aplicados e as conclusões da pesquisa não foram delegados à IA.

---

## Licença

Este projeto é distribuído sob a licença **MIT**, salvo indicação em
contrário em arquivos específicos. Os dados brutos provenientes do portal do
STF são públicos e seguem o regime de transparência do Poder Judiciário
brasileiro.
