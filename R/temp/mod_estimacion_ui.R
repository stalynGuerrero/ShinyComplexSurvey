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
          
          # =====================================================
          # Tipo de estimación
          # =====================================================
          shiny::selectInput(
            inputId = ns("estimator"),
            label   = "Tipo de estimación",
            choices = c(
              "Media"       = "mean",
              "Total"       = "total",
              "Proporción"  = "prop",
              "Razón"       = "ratio",
              "Cuantiles"   = "quantile"
            )
          ),
          
          # =====================================================
          # RAZÓN
          # =====================================================
          shiny::conditionalPanel(
            condition = sprintf("input['%s'] == 'ratio'", ns("estimator")),
            
            shiny::selectInput(
              inputId = ns("numerator"),
              label   = "Numerador",
              choices = NULL
            ),
            
            shiny::selectInput(
              inputId = ns("denominator"),
              label   = "Denominador",
              choices = NULL
            ),
            
            shiny::uiOutput(ns("ratio_levels_ui"))
          ),
          
          # =====================================================
          # CUANTILES
          # =====================================================
          shiny::conditionalPanel(
            condition = sprintf("input['%s'] == 'quantile'", ns("estimator")),
            
            shiny::textInput(
              inputId = ns("probs"),
              label   = "Cuantiles (ej: 0.25, 0.5, 0.75)",
              value   = "0.25, 0.5, 0.75"
            )
          ),
          
          # =====================================================
          # VARIABLE DE INTERÉS (CORREGIDO)
          # =====================================================
          shiny::conditionalPanel(
            condition = sprintf("input['%s'] != 'ratio'", ns("estimator")),
            
            shiny::selectInput(
              inputId = ns("y_var"),
              label   = "Variable de interés",
              choices = NULL
            )
          ),
          
          # =====================================================
          # DOMINIOS
          # =====================================================
          shiny::selectInput(
            inputId = ns("domain_vars"),
            label   = "Dominio(s) (opcional)",
            choices = c("Ninguno" = ""),
            multiple = TRUE
          ),
          
          # =====================================================
          # BOTÓN
          # =====================================================
          shiny::actionButton(
            inputId = ns("run"),
            label   = "Ejecutar estimación",
            class   = "btn-primary"
          )
        )
      ),
      
      shiny::column(
        9,
        shiny::wellPanel(
          
          shiny::h4("Marco teórico"),
          shiny::uiOutput(ns("theory_box")),
          
          shiny::hr(),
          
          shiny::h4("Estado de la estimación"),
          shiny::verbatimTextOutput(ns("log")),
          
          shiny::hr(),
          
          shiny::h4("Resultado (vista previa)"),
          DT::DTOutput(ns("preview")), 
          
          shiny::h4("Indicadores de calidad de la estimación"),
          shiny::uiOutput(ns("quality_theory"))
        )
      )
    )
  )
}