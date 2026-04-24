mod_diseno_ui <- function(id) {

  ns <- shiny::NS(id)

  shiny::fluidPage(

    shiny::h3("Dise\u00f1o muestral"),
    shiny::hr(),

    shiny::fluidRow(

      shiny::column(
        4,
        shiny::wellPanel(

          shiny::h4("Definici\u00f3n del dise\u00f1o"),

          shiny::selectInput(
            ns("design_type"),
            "Tipo de dise\u00f1o",
            choices = c(
              "Simple (SRS)"               = "srs",
              "Estratificado"              = "stratified",
              "Conglomerados / Multiet\u00e1pico" = "cluster"
            )
          ),

          shiny::uiOutput(ns("design_theory")),

          shiny::hr(),

          shiny::uiOutput(ns("design_arguments")),

          shiny::actionButton(
            ns("build"),
            "Construir dise\u00f1o",
            class = "btn-primary"
          )
        )
      ),

      shiny::column(
        8,
        shiny::wellPanel(

          shiny::h4("Resumen del dise\u00f1o"),
          shiny::verbatimTextOutput(ns("log")),

          shiny::h4("C\u00f3digo del dise\u00f1o en R"),
          shiny::verbatimTextOutput(ns("design_code")),

          shiny::hr(),

          shiny::h4("Diagn\u00f3stico"),
          shiny::tableOutput(ns("summary"))
        )
      )
    )
  )
}
