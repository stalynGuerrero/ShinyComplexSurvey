mod_diagnostico_ui <- function(id) {
  ns <- shiny::NS(id)
  
  shiny::fluidPage(
    shiny::h3("Diagnóstico interno"),
    shiny::hr(),
    
    shiny::verbatimTextOutput(ns("status")),
    shiny::hr(),
    shiny::verbatimTextOutput(ns("objects"))
  )
}
