mod_resultados_ui <- function(id) {
  ns <- shiny::NS(id)
  
  shiny::fluidPage(
    
    shiny::h3("Resultados"),
    shiny::hr(),
    
    shiny::tabsetPanel(
      shiny::tabPanel(
        "Tabla",
        DT::DTOutput(ns("table"))
      ),
      shiny::tabPanel(
        "Gráfico",
        shiny::plotOutput(ns("plot"), height = "450px")
      )
    )
  )
}
