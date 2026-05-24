# =============================================================================
# 00_setup.R
# -----------------------------------------------------------------------------
# Propósito: carregar os pacotes utilizados em todo o projeto e estabelecer
# configurações globais (locale, opções de impressão, sementes, etc.).
#
# Este script deve ser a primeira coisa carregada em qualquer sessão de
# análise, via:
#
#     source(here::here("R", "00_setup.R"))
#
# Projeto: Análise empírica de ADIs eleitorais no STF (2016-2026)
# Autor:   Davi Barbosa
# =============================================================================


# -----------------------------------------------------------------------------
# 1. Pacotes
# -----------------------------------------------------------------------------
# Manipulação e leitura de dados
library(tidyverse)   # dplyr, tidyr, ggplot2, readr, purrr, tibble, stringr, forcats
library(readxl)      # Leitura de arquivos .xlsx (base bruta do STF)
library(writexl)     # Escrita de arquivos .xlsx (exportação de tabelas)
library(janitor)     # Limpeza de nomes de colunas, tabelas de frequência
library(lubridate)   # Manipulação de datas (autuação, julgamento, trânsito)

# Infraestrutura do projeto
library(here)        # Construção portátil de caminhos relativos à raiz
library(fs)          # Operações de sistema de arquivos (mais consistente que base)

# Visualização e apresentação
library(scales)      # Formatação de eixos (datas, percentuais, números)
library(ggtext)      # Textos com markdown/HTML em ggplot2
library(gt)          # Tabelas formatadas para output


# -----------------------------------------------------------------------------
# 2. Configurações globais
# -----------------------------------------------------------------------------
# Locale em português para datas e formatação numérica (vírgula decimal)
Sys.setlocale("LC_TIME", "pt_BR.UTF-8")

# Opções de impressão de tibbles e números
options(
  tibble.print_max  = 50,
  tibble.print_min  = 20,
  scipen            = 999,        # Desativa notação científica
  OutDec            = ","         # Vírgula como separador decimal
)

# Semente para reprodutibilidade de qualquer operação estocástica
set.seed(2026)


# -----------------------------------------------------------------------------
# 3. Caminhos padrão do projeto
# -----------------------------------------------------------------------------
# Centralizamos aqui para que scripts subsequentes apenas referenciem estas
# constantes — facilita refatorações futuras.
path_raw       <- here::here("data", "raw")
path_interim   <- here::here("data", "interim")
path_processed <- here::here("data", "processed")
path_fig       <- here::here("output", "figuras")
path_tab       <- here::here("output", "tabelas")


# -----------------------------------------------------------------------------
# 4. Mensagem de confirmação
# -----------------------------------------------------------------------------
message("[setup] Pacotes carregados e ambiente configurado com sucesso.")
