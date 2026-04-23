mod_export_ui <- function(id) {
  ns <- shiny::NS(id)
  
  shiny::fluidPage(
    
    shiny::h3("Exportación de resultados"),
    shiny::hr(),
    
    shiny::fluidRow(
      
      # =========================
      # Columna izquierda
      # =========================
      shiny::column(
        4,
        shiny::wellPanel(
          shiny::h4("Opciones"),
          
          shiny::checkboxGroupInput(
            ns("export_elements"),
            "Contenido a exportar",
            choices = c(
              "Tabla de resultados" = "table",
              "Gráficos" = "plot",
              "Objeto R (resultados)" = "rds"
            ),
            selected = c("table")
          ),
          
          shiny::selectInput(
            ns("file_format"),
            "Formato de archivo",
            choices = c(
              "Excel (.xlsx)" = "xlsx",
              "CSV (.csv)"     = "csv",
              "RDS (.rds)"     = "rds"
            )
          )
        )
      ),
      
      # =========================
      # Columna derecha
      # =========================
      shiny::column(
        8,
        shiny::wellPanel(
          shiny::h4("Descarga"),
          
          shiny::p(
            "Los archivos exportados corresponden a los resultados ",
            "calculados en la pestaña de estimación."
          ),
          
          shiny::br(),
          
          shiny::downloadButton(
            ns("download"),
            "Descargar resultados",
            class = "btn-primary"
          ),
          
          shiny::hr(),
          
          shiny::verbatimTextOutput(ns("log"))
        )
      )
    )
  )
}
