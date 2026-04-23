mod_datos_ui <- function(id) {
  ns <- shiny::NS(id)
  
  shiny::fluidPage(
    
    shiny::h3(shiny::textOutput(ns("title"))),
    shiny::hr(),
    
    shiny::fluidRow(
      
      shiny::column(
        4,
        shiny::wellPanel(
          shiny::h4(shiny::textOutput(ns("input_panel"))),
          
          shiny::uiOutput(ns("file_ui")),
          
          shiny::hr(),
          
          shiny::actionButton(
            ns("load_example"),
            label = NULL,
            class = "btn-primary"
          )
        )
      ),
      
      shiny::column(
        8,
        shiny::wellPanel(
          shiny::h4(shiny::textOutput(ns("preview"))),
          
          DT::DTOutput(ns("preview")),
          shiny::hr(),
          shiny::verbatimTextOutput(ns("log"))
        )
      )
    )
  )
}