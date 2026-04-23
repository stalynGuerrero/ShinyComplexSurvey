mod_diseno_ui <- function(id) {
  ns <- shiny::NS(id)
  
  shiny::fluidPage(
    
    shiny::h3("Diseño muestral"),
    shiny::hr(),
    
    shiny::fluidRow(
      
      shiny::column(
        4,
        shiny::wellPanel(
          
          shiny::h4("Definición del diseño"),
          
          shiny::selectInput(
            ns("design_type"),
            "Tipo de diseño",
            choices = c(
              "Simple (SRS)" = "srs",
              "Estratificado" = "stratified",
              "Conglomerado" = "cluster",
              "Bietápico" = "two_stage"
            )
          ),
          
          # argumentos dinámicos
          uiOutput(ns("design_arguments")),
          
          shiny::actionButton(
            ns("build"),
            "Construir diseño",
            class = "btn-primary"
          )
        )
      ),
      
      shiny::column(
        8,
        shiny::wellPanel(
          
          shiny::h4("Resumen del diseño"),
          
          shiny::verbatimTextOutput(ns("log")),
          
          shiny::tableOutput(ns("summary"))
        )
      )
    )
  )
}