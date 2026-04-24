mod_estimacion_ui <- function(id) {
  ns <- shiny::NS(id)

  shiny::fluidPage(

    shiny::h3("Estimaci\u00f3n"),
    shiny::hr(),

    shiny::fluidRow(

      shiny::column(
        3,
        shiny::wellPanel(

          shiny::h4("Par\u00e1metros"),

          # =====================================================
          # Tipo de estimaci\u00f3n
          # =====================================================
          shiny::selectInput(
            inputId = ns("estimator"),
            label   = "Tipo de estimaci\u00f3n",
            choices = c(
              "Media"      = "mean",
              "Total"      = "total",
              "Proporci\u00f3n" = "prop",
              "Raz\u00f3n"      = "ratio",
              "Cuantiles"  = "quantile"
            )
          ),

          # =====================================================
          # RAZ\u00d3N
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
          # VARIABLE DE INTER\u00c9S
          # =====================================================
          shiny::conditionalPanel(
            condition = sprintf("input['%s'] != 'ratio'", ns("estimator")),

            shiny::selectInput(
              inputId = ns("y_var"),
              label   = "Variable de inter\u00e9s",
              choices = NULL
            )
          ),

          # =====================================================
          # DOMINIOS
          # =====================================================
          shiny::selectInput(
            inputId  = ns("domain_vars"),
            label    = "Dominio(s) (opcional)",
            choices  = c("Ninguno" = ""),
            multiple = TRUE
          ),

          # =====================================================
          # BOT\u00d3N
          # =====================================================
          shiny::actionButton(
            inputId = ns("run"),
            label   = "Ejecutar estimaci\u00f3n",
            class   = "btn-primary"
          )
        )
      ),

      shiny::column(
        9,
        shiny::wellPanel(

          shiny::h4("Marco te\u00f3rico"),
          shiny::uiOutput(ns("theory_box")),

          shiny::hr(),

          shiny::h4("Estado de la estimaci\u00f3n"),
          shiny::verbatimTextOutput(ns("log")),

          shiny::hr(),

          shiny::h4("Resultado"),
          DT::DTOutput(ns("preview")),

          shiny::hr(),

          shiny::h4("Indicadores de calidad"),
          shiny::uiOutput(ns("quality_theory"))
        )
      )
    )
  )
}
