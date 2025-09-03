library(shiny)
library(bslib)
library(shinyWidgets)
library(shinyjs)

source('R/mod_upload.R')
source('R/mod_map.R')
source('R/mod_design.r')
source('R/mod_descriptives.r')
source('R/mod_mutate.r')
source('R/mod_ratios.R')
source('R/mod_export.R')

# ui.R

# Define los colores del IDT
idt_blue <- "#007BFF"
idt_green <- "#28A745"

ui <- fluidPage(
    # Tema y CSS personalizado
    theme = bs_theme(
        version = 4,
        bootswatch = 'flatly',
        bg = "#e3f2fd", 
        fg = "#212529",
        primary = idt_blue,
        secondary = idt_green,
        "sidebar-bg" = "#E9ECEF"
    ),
    tags$head(
        tags$link(rel = "stylesheet", type = "text/css", href = "estilos.css")
    ),
    
    # Encabezado con logo y título
    div(
        class = "main-header",
        style = "display: flex; align-items: center; justify-content: center; padding: 20px 0; background-color: white; border-bottom: 2px solid #007BFF; box-shadow: 0 2px 5px rgba(0,0,0,0.1);",
        tags$img(src = "logo_idt.png", height = "60px", style = "margin-right: 20px;"),
        tags$h1("App de Estimación de Muestreo", class = "main-title")
    ),
    
    # Estructura principal de la aplicación
    sidebarLayout(
        sidebarPanel(width = 3,
                     div(
                         class = "sidebar-help",
                         helpText('Sigue el flujo: carga -> identificar diseño -> análisis -> exportar'),
                     ),
                     hr(),
                     uiOutput('help_context')
        ),
        mainPanel(
            tabsetPanel(
                id = "main_tabs",
                type = "pills",
                tabPanel(title = tagList(icon("upload"), 'Carga & Mapa'), mod_upload_ui('upload1'), mod_map_ui('map1')),
                tabPanel(title = tagList(icon("id-card"), 'Identificación'), mod_design_ui('design1')),
                tabPanel(title = tagList(icon("info-circle"), 'Diseño - Características'), verbatimTextOutput('design_summary')),
                tabPanel(title = tagList(icon("chart-bar"), 'Descriptivos'), mod_descriptives_ui('desc1')),
                tabPanel(title = tagList(icon("pencil-alt"), 'Crear variables'), mod_mutate_ui('mut1')),
                tabPanel(title = tagList(icon("percentage"), 'Razones'), mod_ratios_ui('rat1')),
                tabPanel(title = tagList(icon("file-export"), 'Exportación'), mod_export_ui('exp1'))
            )
        )
    ),
    
    # --- Pie de Página ---
    tags$footer(
        style = "background-color: #007BFF; color: white; padding: 20px; margin-top: 50px; font-size: 0.85em; text-align: center;",
        div(
            class = "container-fluid",
            fluidRow(
                column(4,
                       h5("Sede Electrónica"),
                       p("Instituto Distrital de Turismo (IDT)"),
                       p("Edificio Centro Internacional, Carrera 10 # 28-49 Torre A, pisos 23"),
                       p("Horario: 7:00 a.m a 4:30 p.m"),
                       p("Recepción: +57 (601) 2170711 Ext. 1000"),
                       p("Línea turista: (57) 01 8000 127400"),
                       p("Línea de emergencias: 123"),
                       p("Línea de Información: 195"),
                       p("Línea Anticorrupción"),
                       tags$a(href = "mailto:info@idt.gov.co", "info@idt.gov.co", style = "color: white;"), br(),
                       tags$a(href = "mailto:correspondenciarecepcion@idt.gov.co", "correspondenciarecepcion@idt.gov.co", style = "color: white;"), br(),
                       tags$a(href = "mailto:notificacionjudicial@idt.gov.co", "notificacionjudicial@idt.gov.co", style = "color: white;"),
                       p("NIT: 900.140.515-6")
                ),
                column(4,
                       h5("Entidades de Control"),
                       tags$ul(
                           style = "list-style-type: none; padding-left: 0;",
                           tags$li(tags$a(href = "#", "Personería Distrital", style = "color: white;")),
                           tags$li(tags$a(href = "#", "Procuraduría General de la Nación", style = "color: white;")),
                           tags$li(tags$a(href = "#", "Contraloría General de la Nación", style = "color: white;")),
                           tags$li(tags$a(href = "#", "Concejo de Bogotá", style = "color: white;")),
                           tags$li(tags$a(href = "#", "Veeduría Distrital de Bogotá", style = "color: white;")),
                           tags$li(tags$a(href = "#", "Portal de Contratación a la Vista", style = "color: white;")),
                           tags$li(tags$a(href = "#", "Portal de Contratación - SECOP", style = "color: white;")),
                           tags$li(tags$a(href = "#", "Tablero de Control Ciudadano TCC", style = "color: white;"))
                       )
                ),
                column(4,
                       h5("Vínculos de Interés"),
                       tags$ul(
                           style = "list-style-type: none; padding-left: 0;",
                           tags$li(tags$a(href = "#", "Secretaría de Desarrollo Económico", style = "color: white;")),
                           tags$li(tags$a(href = "#", "Instituto para la Economía Social - IPES", style = "color: white;")),
                           tags$li(tags$a(href = "#", "Presidencia de la República", style = "color: white;")),
                           tags$li(tags$a(href = "#", "Visit Bogotá", style = "color: white;")),
                           tags$li(tags$a(href = "#", "Invest In Bogotá", style = "color: white;")),
                           tags$li(tags$a(href = "#", "MinTIC", style = "color: white;")),
                           tags$li(tags$a(href = "#", "Gobierno en Línea", style = "color: white;")),
                           tags$li(tags$a(href = "#", "Transparencia y Acceso a la Información Pública", style = "color: white;")),
                           tags$li(tags$a(href = "#", "Atención y Servicios a la Ciudadanía", style = "color: white;"))
                       )
                )
            )
        ),
        hr(style = "border-top: 1px solid #ffffff; width: 80%;"),
        p("Desarrollado por Stalyn Guerrero Gómez", style = "font-size: 0.9em;")
    )
)