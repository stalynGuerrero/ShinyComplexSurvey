mod_pivot_basic_ui <- function(id){
  
  ns <- shiny::NS(id)
  
  shiny::fluidPage(
    
    shiny::fluidRow(
      
      shiny::column(
        4,
        shiny::selectInput(
          ns("rows"),
          "Filas",
          choices = NULL,
          multiple = TRUE
        )
      ),
      
      shiny::column(
        4,
        shiny::selectInput(
          ns("cols"),
          "Columnas",
          choices = NULL,
          multiple = TRUE
        )
      ),
      
      shiny::column(
        4,
        shiny::selectInput(
          ns("vals"),
          "Valores",
          choices = NULL
        )
      )
      
    ),
    
    shiny::br(),
    
    rpivotTable::rpivotTableOutput(ns("pivot"))
    
  )
}