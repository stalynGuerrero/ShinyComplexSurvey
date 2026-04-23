mod_resultados_ui <- function(id) {
  ns <- shiny::NS(id)
  
  shiny::tagList(
    # Usamos bslib para un diseño más limpio
    bslib::layout_column_wrap(
      width = 1,
      bslib::navset_card_pill(
        title = "Explorador de Resultados",
        
        # Panel de Gráficos
        bslib::nav_panel(
          title = "Visualización",
          icon = shiny::icon("chart-bar"),
          shiny::plotOutput(ns("plot"), height = "550px") |> 
            shinycssloaders::withSpinner(type = 8)
        ),
        
        # Panel de Tabla Pivot
        bslib::nav_panel(
          title = "Tabla Dinámica",
          icon = shiny::icon("table"),
          
          # Controles en una fila bien organizada
          shiny::wellPanel(
            shiny::fluidRow(
              shiny::column(3, shiny::selectInput(ns("row_var"), "Filas (Agrupar por):", choices = NULL)),
              shiny::column(3, shiny::selectInput(ns("col_var"), "Columnas (Cruzar):", choices = NULL)),
              shiny::column(3, shiny::selectInput(ns("value_var"), "Métricas:", choices = NULL, multiple = TRUE)),
              shiny::column(3, shiny::selectInput(ns("agg_fun"), "Función:", 
                                                  choices = c("Media"="mean", "Suma"="sum", "N"="length"), 
                                                  selected = "mean"))
            )
          ),
          DT::DTOutput(ns("table"))
        ),
        
        # Panel de Configuración
        bslib::nav_panel(
          title = "Configurar Etiquetas",
          icon = shiny::icon("gear"),
          shiny::helpText("Haz doble clic en una celda para editar el nombre que aparecerá en el gráfico."),
          DT::DTOutput(ns("editor"))
        )
      )
    )
  )
}