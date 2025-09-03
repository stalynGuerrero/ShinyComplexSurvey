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

# ui.R
ui <- dashboardPage(
  skin = "blue",
  
  # 1. Encabezado con logo
  dashboardHeader(
    titleWidth = 300,
    title = tags$a(
      h4("Estimación de Encuestas", 
         style = "margin: 0; font-weight: bold; color: white;"),
      href = 'http://idt.gov.co/',
      target = "_blank"
    )
  ),
  
  # 2. Sidebar
  dashboardSidebar(
    width = 260,
    sidebarMenu(
      id = "tabs",
      menuItem("Carga de Datos", tabName = "load_data", icon = icon("database")),
      menuItem("Identificación", tabName = "identification", icon = icon("project-diagram")),
      menuItem("Descriptivos", tabName = "descriptives", icon = icon("chart-bar"))
      #menuItem("Crear Variables", tabName = "create_vars", icon = icon("shapes"))
      # menuItem("Razones", tabName = "ratios", icon = icon("balance-scale")),
      # menuItem("Exportación", tabName = "export", icon = icon("file-export"))
    )
  ),
  
  # 3. Cuerpo del Dashboard (Body)
  dashboardBody(
    # Agrega CSS para la posición del pie de página
    tags$head(
      tags$style(
        HTML(
          "
          .main-footer {
            position: relative;
            bottom: 0;
            width: 100%;
            margin-top: 50px;
          }
          "
        )
      )
    ),
    
    tabItems(
      tabItem(tabName = "load_data", fluidRow(
        box(
          title = "Carga de Datos",
          width = 12,
          solidHeader = TRUE,
          status = "primary",
          mod_upload_ui("upload1")
        )
      )), 
      
      tabItem(tabName = "identification", fluidRow(
        box(
          title = "Diseño Muestral",
          width = 12,
          status = "info",
          solidHeader = TRUE,
          tabsetPanel(
            type = "tabs",
            tabPanel("Definir Diseño", mod_design_ui("design1")),
            tabPanel("Crear Variables Derivadas", mod_mutate_ui("mut1")),
            tabPanel("Resumen del Diseño", design_summary_ui("design_summary"))
          )
        )
      )), 
      
      tabItem(tabName = "descriptives",
              fluidRow(
                box(title = "Análisis Descriptivo", width = 12, status = "primary", solidHeader = TRUE,
                    mod_descriptives_ui("desc1"))
              ))
      
      # tabItem(
      #   tabName = "create_vars",
      #   box(
      #     title = "Crear Variables Derivadas",
      #     width = 12,
      #     solidHeader = TRUE,
      #     status = "warning",
      #     mod_mutate_ui("mut1")
      #   )
      # )
      # 
      # tabItem(tabName = "ratios",
      #         box(title = "Cálculo de Razones", width = 12, solidHeader = TRUE, status = "success",
      #             mod_ratios_ui("rat1"))),
      # 
      # tabItem(tabName = "export",
      #         box(title = "Exportación de Resultados", width = 12, solidHeader = TRUE, status = "info",
      #             mod_export_ui("exp1")))
    ),
    
    # 4. Pie de página (Footer)
    tags$footer(
      div(
        class = "footer",
        style = "background-color: #007BFF; color: white; padding: 35px;
                 font-size: 0.85em; text-align: center;",
        fluidRow(
          column(4,
                 h5("Sede Electrónica"),
                 # Aquí se agrega el logo en la columna del footer
                 tags$img(
                   src = "IDT_logo.png", # Asegúrate de que este archivo esté en la carpeta www
                   height = "50px", # Ajusté el tamaño para que se vea mejor
                   style = "margin-bottom: 10px;"
                 ),
                 p("Instituto Distrital de Turismo (IDT)"),
                 p("Edificio Centro Internacional, Carrera 10 # 28-49 Torre A, pisos 23"),
                 p("Horario: 7:00 a.m a 4:30 p.m"),
                 p("Recepción: +57 (601) 2170711 Ext. 1000"),
                 p("Línea turista: (57) 01 8000 127400"),
                 p("Línea de emergencias: 123"),
                 p("Línea de Información: 195"),
                 tags$a(href = "mailto:info@idt.gov.co", "info@idt.gov.co", style = "color: white;")
          ),
          column(4,
                 h5("Entidades de Control"),
                 tags$ul(
                   style = "list-style-type: none; padding-left: 0;",
                   tags$li(tags$a(href = "https://www.personeriabogota.gov.co/", "Personería Distrital", style = "color: white;")),
                   tags$li(tags$a(href = "https://www.procuraduria.gov.co/portal/", "Procuraduría General de la Nación", style = "color: white;")),
                   tags$li(tags$a(href = "https://www.contraloriabogota.gov.co/", "Contraloría General de la Nación", style = "color: white;"))
                 )
          ),
          column(4,
                 h5("Vínculos de Interés"),
                 tags$ul(
                   style = "list-style-type: none; padding-left: 0;",
                   tags$li(tags$a(href = "https://visitbogota.co/es/", "Visit Bogotá", style = "color: white;")),
                   tags$li(tags$a(href = "https://investinbogota.org/es", "Invest In Bogotá", style = "color: white;"))
                 )
          )
        ),
        hr(style = "border-top: 1px solid #ffffff; width: 80%;"),
        p("Desarrollado por Stalyn Guerrero - Instituto Distrital de Turismo", style = "font-size: 0.9em; margin-bottom: 0;")
      )
    )
  )
)

