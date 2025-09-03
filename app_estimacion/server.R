library(shiny)
library(tidyverse)
library(DT)
library(glue)
library(scales)
library(plotly)
library(bslib)
library(shinyWidgets)
library(shinyjs)
library(shinydashboard)
library(shinythemes)
library(esquisse)


source('R/utils_io.R')
source('R/utils_survey.R')
source('R/mod_upload.R')
source('R/mod_map.R')
source("R/design_summary_module.R")
source('R/mod_design.r')
source('R/mod_descriptives.r')
source('R/mod_mutate.r')
source('R/mod_ratios.R')
source('R/mod_export.R')
source('R/mod_logging.R')

server <- function(input, output, session){
    # Módulo de upload
    upload <- mod_upload_server('upload1')
    
    # # Map - consume datos de upload
    # mod_map_server('map1', data = upload$data)
     
    # Mutate (después de upload)
    mut <- mod_mutate_server('mut1', data = upload$data)
    
    # Diseño consume mutate
    design <- mod_design_server('design1', data = mut)
    
    # # Mostrar resumen del diseño
    design_summary_server("design_summary", design_data = design$design)
    #
    # Descriptivos (usa el objeto design)
    mod_descriptives_server('desc1', design = design$design)
    # 
    
    # # Razones
    # mod_ratios_server('rat1', data = mut$data, design = design$design)
    # 
    # # Export
    # mod_export_server('exp1', data = mut$data, results = reactive(NULL))
}
