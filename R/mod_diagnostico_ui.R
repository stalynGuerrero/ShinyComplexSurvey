mod_diagnostico_ui <- function(id) {
  
  ns <- shiny::NS(id)
  
  shiny::fluidPage(
    
    shiny::h3("Diagnóstico de estimaciones"),
    shiny::hr(),
    
    shiny::tabsetPanel(
      
      shiny::tabPanel(
        "Estado",
        
        shiny::verbatimTextOutput(ns("status")),
        shiny::hr(),
        shiny::verbatimTextOutput(ns("objects"))
      ),
      
      shiny::tabPanel(
        "Calidad de estimaciones",
        
        shiny::h4("Indicadores de precisión"),
        DT::DTOutput(ns("quality_table"))
      ),
      
      shiny::tabPanel(
        "Editar tabla",
        
        shiny::h4("Editor de etiquetas"),
        DT::DTOutput(ns("editor"))
      )
      
    )
  )
}