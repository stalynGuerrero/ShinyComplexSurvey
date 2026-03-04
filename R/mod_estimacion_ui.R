mod_estimacion_ui <- function(id) {
  ns <- shiny::NS(id)
  
  shiny::fluidPage(
    
    shiny::h3("Estimación"),
    shiny::hr(),
    
    shiny::fluidRow(
      
      shiny::column(
        3,
        shiny::wellPanel(
          shiny::h4("Parámetros"),
          
          shiny::selectInput(
            ns("estimator"),
            "Tipo de estimación",
            choices = c(
              "Media"       = "mean",
              "Total"       = "total",
              "Proporción"  = "prop",
              "Razón"       = "ratio",
              "Cuantiles"   = "quantile"
            )
          ),
          # -------------------------
          # RAZÓN
          # -------------------------
          shiny::conditionalPanel(
            condition = sprintf("input['%s'] == 'ratio'", ns("estimator")),
            shiny::selectInput(
              ns("numerator"),
              "Numerador",
              choices = NULL
            ),
            shiny::selectInput(
              ns("denominator"),
              "Denominador",
              choices = NULL
            ),
            uiOutput(ns("ratio_levels_ui"))  
          ),
           
          
          # -------------------------
          # CUANTILES
          # -------------------------
          shiny::conditionalPanel(
            condition = sprintf("input['%s'] == 'quantile'", ns("estimator")),
            shiny::textInput(
              ns("probs"),
              "Cuantiles (ej: 0.25, 0.5, 0.75)",
              value = "0.25, 0.5, 0.75"
            )
          ),
          
          shiny::selectInput(
            ns("y_var"),
            "Variable de interés",
            choices = NULL
          ),
          
          shiny::selectInput(
            ns("domain_vars"),
            "Dominio(s) (opcional)",
            choices = c("Ninguno" = ""),
            multiple = TRUE
          ),
          
          shiny::actionButton(
            ns("run"),
            "Ejecutar estimación",
            class = "btn-primary"
          )
        )
      ),
      
      shiny::column(
        9,
        shiny::wellPanel(
          shiny::h4("Estado de la estimación"),
          shiny::verbatimTextOutput(ns("log")),
          shiny::hr(),
          shiny::h4("Resultado (vista previa)"),
          DT::DTOutput(ns("preview"))
        )
      )
    )
  )
}
