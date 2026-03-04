mod_diseno_ui <- function(id) {
  ns <- shiny::NS(id)
  
  shiny::fluidPage(
    
    shiny::h3("Diseno muestral"),
    shiny::hr(),
    
    shiny::fluidRow(
      
      shiny::column(
        4,
        shiny::wellPanel(
          shiny::h4("Definición del Diseno"),
          
          shiny::selectInput(
            ns("design_type"),
            "Tipo de Diseno",
            choices = c(
              "Simple" = "srs",
              "Estratificado" = "stratified",
              "Conglomerado" = "cluster",
              "Bietápico" = "two_stage"
            )
          ),
          
          shiny::selectInput(ns("weight_var"),  "Peso muestral", choices = NULL),
          shiny::selectInput(ns("strata_var"),  "Estrato", choices = NULL),
          shiny::selectInput(ns("cluster_var"), "UPM / Conglomerado", choices = NULL),
          
          shiny::actionButton(
            ns("build"),
            "Construir Diseno",
            class = "btn-primary"
          )
        )
      ),
      
      shiny::column(
        8,
        shiny::wellPanel(
          shiny::h4("Resumen del Diseno"),
          shiny::verbatimTextOutput(ns("log")),
          shiny::tableOutput(ns("summary"))
        )
      )
    )
  )
}
