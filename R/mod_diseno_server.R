mod_diseno_server <- function(id, data) {

  shiny::moduleServer(id, function(input, output, session) {

    ns <- session$ns

    # -------------------------------------------------
    # 1. Teor\u00eda del dise\u00f1o (MathJax)
    # -------------------------------------------------
    output$design_theory <- shiny::renderUI({

      shiny::req(input$design_type)

      switch(
        input$design_type,

        "srs" = shiny::tagList(
          shiny::withMathJax(),
          shiny::h5("Muestreo Aleatorio Simple (SRS)"),
          shiny::p("Cada unidad de la poblaci\u00f3n tiene la misma probabilidad de ser seleccionada."),
          shiny::h6("Estimador de la media poblacional"),
          shiny::HTML("$$ \\hat{\\bar{Y}} = \\frac{1}{n} \\sum_{i=1}^{n} y_i $$"),
          shiny::h6("Varianza del estimador"),
          shiny::HTML("$$ Var(\\hat{\\bar{Y}}) = \\left(1-\\frac{n}{N}\\right)\\frac{S^2}{n} $$"),
          shiny::tags$ul(
            shiny::tags$li(shiny::HTML("\\(y_i\\): valor observado de la variable para la unidad \\(i\\).")),
            shiny::tags$li(shiny::HTML("\\(n\\): tama\u00f1o de la muestra.")),
            shiny::tags$li(shiny::HTML("\\(N\\): tama\u00f1o de la poblaci\u00f3n.")),
            shiny::tags$li(shiny::HTML("\\(S^2\\): varianza poblacional de la variable de inter\u00e9s."))
          )
        ),

        "stratified" = shiny::tagList(
          shiny::withMathJax(),
          shiny::h5("Muestreo Estratificado"),
          shiny::p("La poblaci\u00f3n se divide en subgrupos homog\u00e9neos llamados estratos."),
          shiny::h6("Estimador de la media estratificada"),
          shiny::HTML("$$ \\hat{\\bar{Y}}_{st} = \\sum_{h=1}^{H} W_h \\bar{y}_h $$"),
          shiny::h6("Varianza del estimador"),
          shiny::HTML("$$ Var(\\hat{\\bar{Y}}_{st}) = \\sum_{h=1}^{H} W_h^2 \\left(1-\\frac{n_h}{N_h}\\right) \\frac{S_h^2}{n_h} $$"),
          shiny::tags$ul(
            shiny::tags$li(shiny::HTML("\\(H\\): n\u00famero total de estratos.")),
            shiny::tags$li(shiny::HTML("\\(W_h = N_h/N\\): peso poblacional del estrato \\(h\\).")),
            shiny::tags$li(shiny::HTML("\\(n_h\\): tama\u00f1o de muestra en el estrato \\(h\\).")),
            shiny::tags$li(shiny::HTML("\\(S_h^2\\): varianza dentro del estrato \\(h\\)."))
          )
        ),

        "cluster" = shiny::tagList(
          shiny::withMathJax(),
          shiny::h5("Muestreo por Conglomerados / Multiet\u00e1pico"),
          shiny::p("Las unidades se seleccionan en grupos llamados conglomerados o UPM."),
          shiny::h6("Estimador de Horvitz\u2013Thompson"),
          shiny::HTML("$$ \\hat{Y} = \\sum_{i \\in s} \\frac{y_i}{\\pi_i} $$"),
          shiny::h6("Varianza del estimador"),
          shiny::HTML("$$ Var(\\hat{Y}) = \\sum_i \\sum_j \\left(\\frac{\\pi_{ij}-\\pi_i\\pi_j}{\\pi_{ij}}\\right) \\frac{y_i}{\\pi_i} \\frac{y_j}{\\pi_j} $$"),
          shiny::tags$ul(
            shiny::tags$li(shiny::HTML("\\(\\pi_i\\): probabilidad de inclusi\u00f3n de la unidad \\(i\\).")),
            shiny::tags$li(shiny::HTML("\\(\\pi_{ij}\\): probabilidad conjunta de inclusi\u00f3n de \\(i\\) y \\(j\\).")),
            shiny::tags$li(shiny::HTML("\\(1/\\pi_i\\): peso muestral de la unidad \\(i\\)."))
          )
        )
      )
    })

    # -------------------------------------------------
    # 2. Argumentos din\u00e1micos del dise\u00f1o
    # -------------------------------------------------
    output$design_arguments <- shiny::renderUI({

      shiny::req(data())

      vars <- names(data())

      switch(
        input$design_type,

        "srs" = shiny::tagList(
          shiny::selectInput(ns("weight_var"), "Peso muestral", choices = vars)
        ),

        "stratified" = shiny::tagList(
          shiny::selectInput(ns("strata_var"),  "Variable de estrato", choices = vars),
          shiny::selectInput(ns("weight_var"),  "Peso muestral",       choices = vars)
        ),

        "cluster" = shiny::tagList(
          shiny::numericInput(ns("n_stages"), "N\u00famero de etapas", value = 2, min = 1, max = 5),
          shiny::uiOutput(ns("stage_clusters")),
          shiny::selectInput(ns("strata_var"), "Estrato", choices = c("Ninguno" = "", vars)),
          shiny::selectInput(ns("weight_var"), "Peso muestral", choices = vars),
          shiny::selectInput(
            ns("lonely_psu"),
            "Estrategia para UPM \u00fanico",
            choices = c(
              "Ajuste conservador" = "adjust",
              "Promedio del estrato" = "average",
              "Certidumbre"         = "certainty"
            ),
            selected = "adjust"
          )
        )
      )
    })

    # -------------------------------------------------
    # 3. Etapas din\u00e1micas (cluster multiet\u00e1pico)
    # -------------------------------------------------
    output$stage_clusters <- shiny::renderUI({

      shiny::req(input$n_stages, data())

      vars <- names(data())

      lapply(seq_len(input$n_stages), function(i) {
        shiny::selectInput(
          ns(paste0("cluster_stage_", i)),
          paste("Conglomerado etapa", i),
          choices = vars
        )
      })
    })

    # -------------------------------------------------
    # 4. Funci\u00f3n limpieza de inputs
    # -------------------------------------------------
    clean_input <- function(x) {
      if (is.null(x) || length(x) == 0 || nchar(trimws(x)) == 0) return(NULL)
      x
    }

    # -------------------------------------------------
    # 5. Log reactivo
    # -------------------------------------------------
    log_design <- shiny::reactiveVal(NULL)

    shiny::observeEvent(input$design_type, {
      log_design(NULL)
    }, ignoreInit = TRUE)

    # -------------------------------------------------
    # 6. Construcci\u00f3n del dise\u00f1o
    # -------------------------------------------------
    design_r <- shiny::eventReactive(input$build, {

      df <- data()
      shiny::req(df, input$design_type, input$weight_var)

      weight <- input$weight_var
      strata <- clean_input(input$strata_var)

      tryCatch({

        des <- if (input$design_type == "srs") {

          formula_design <- paste0("svydesign(id=~1, weights=~", weight, ", data=data)")
          as_survey_design_tbl(data = df, weight = weight)

        } else if (input$design_type == "stratified") {

          shiny::req(strata)
          formula_design <- paste0(
            "svydesign(id=~1, strata=~", strata, ", weights=~", weight, ", data=data)"
          )
          as_survey_design_tbl(data = df, weight = weight, strata = strata)

        } else {

          # cluster / multiet\u00e1pico
          clusters <- sapply(
            seq_len(input$n_stages),
            function(i) input[[paste0("cluster_stage_", i)]]
          )
          lonely <- input$lonely_psu
          if (!is.null(lonely) && nchar(lonely) > 0) {
            options(survey.lonely.psu = lonely)
          }

          formula_design <- paste0(
            "svydesign(id=~", paste(clusters, collapse = "+"),
            if (!is.null(strata)) paste0(", strata=~", strata) else "",
            ", weights=~", weight, ", nest=TRUE, data=data)"
          )

          # Build via as_survey_design_tbl with first-stage cluster
          as_survey_design_tbl(
            data    = df,
            weight  = weight,
            strata  = strata,
            cluster = clusters[1],
            nest    = TRUE
          )
        }

        log_design(list(
          tipo       = input$design_type,
          formula_R  = formula_design,
          lonely_psu = input$lonely_psu
        ))

        des

      }, error = function(e) {
        shiny::showNotification(
          paste("Error al construir el dise\u00f1o:", conditionMessage(e)),
          type = "error", duration = 8
        )
        NULL
      })

    }, ignoreInit = TRUE)

    # -------------------------------------------------
    # 7. C\u00f3digo del dise\u00f1o en R
    # -------------------------------------------------
    output$design_code <- shiny::renderText({
      shiny::req(log_design())
      log_design()$formula_R
    })

    # -------------------------------------------------
    # 8. Log del dise\u00f1o
    # -------------------------------------------------
    output$log <- shiny::renderPrint({
      log_design()
    })

    # -------------------------------------------------
    # 9. Resumen diagn\u00f3stico
    # -------------------------------------------------
    output$summary <- shiny::renderTable({
      shiny::req(design_r())
      tryCatch(
        describe_survey_design(design_r()),
        error = function(e) NULL
      )
    }, digits = 2)

    # -------------------------------------------------
    # 10. Salida del m\u00f3dulo
    # -------------------------------------------------
    return(list(
      design = shiny::reactive({ design_r() })
    ))

  })
}
