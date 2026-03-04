mod_datos_ui <- function(id) {
  ns <- shiny::NS(id)
  
  shiny::fluidPage(
    
    shiny::h3("Carga y validacion de datos"),
    shiny::hr(),
    
    shiny::fluidRow(
      
      # =========================
      # Columna izquierda
      # =========================
      shiny::column(
        4,
        shiny::wellPanel(
          shiny::h4("Entrada de datos"),
          
          shiny::fileInput(
            ns("file"),
            "Archivo de datos",
            accept = c(".csv", ".rds", ".xlsx")
          ),
          
          shiny::hr(),
          
          shiny::actionButton(
            ns("load_example"),
            "Cargar datos de ejemplo",
            class = "btn-primary"
          )
        )
      ),
      
      # =========================
      # Columna derecha
      # =========================
      shiny::column(
        8,
        shiny::wellPanel(
          shiny::h4("Vista previa"),
          
          DT::DTOutput(ns("preview")),
          shiny::hr(),
          shiny::verbatimTextOutput(ns("log"))
        )
      )
    )
  )
}
