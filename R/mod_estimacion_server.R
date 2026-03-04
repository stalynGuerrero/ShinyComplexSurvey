mod_estimacion_server <- function(id, design) {
  
  shiny::moduleServer(id, function(input, output, session) {
    
    ns <- session$ns
    
    # ==================================================
    # 1. Actualizar selectores desde el diseño (bien hecho)
    # ==================================================
    shiny::observeEvent(design(), {
      
      des <- design()
      shiny::req(des)
      
      vars <- colnames(des$variables)
      
      shiny::updateSelectInput(session, "y_var", choices = vars, selected = vars[1])
      shiny::updateSelectInput(session, "numerator", choices = vars, selected = vars[1])
      shiny::updateSelectInput(session, "denominator", choices = vars, selected = vars[2])
      shiny::updateSelectInput(session, "domain_vars", choices = c("Ninguno" = "", vars))
    }, ignoreInit = TRUE)
    
    
    # ==================================================
    # 2. UI dinámica para ratio categórica (usa y_var)
    # ==================================================
    output$ratio_levels_ui <- renderUI({
      
      req(input$estimator == "ratio")
      req(input$numerator, input$denominator)
      req(design())
      
      vars <- design()$variables
      
      num_is_cat <- is.factor(vars[[input$numerator]]) ||
        is.character(vars[[input$numerator]])
      
      den_is_cat <- is.factor(vars[[input$denominator]]) ||
        is.character(vars[[input$denominator]])
      
      ui <- list()
      
      if (num_is_cat) {
        ui <- c(ui, list(
          selectInput(
            ns("ratio_num_level"),
            "Categoría (numerador)",
            choices = sort(unique(stats::na.omit(vars[[input$numerator]])))
          )
        ))
      }
      
      if (den_is_cat) {
        ui <- c(ui, list(
          selectInput(
            ns("ratio_den_level"),
            "Categoría (denominador)",
            choices = sort(unique(stats::na.omit(vars[[input$denominator]])))
          )
        ))
      }
      
      if (length(ui) == 0) return(NULL)
      tagList(ui)
    })
    
    
    # ==================================================
    # 3. Ejecutar estimación
    # ==================================================
    results_r <- shiny::eventReactive(input$run, {
      
      des <- design()
      shiny::req(des, input$y_var, input$estimator)
      
      domain <- input$domain_vars
      if (length(domain) == 0 || all(domain == "")) domain <- NULL
      
      # ---- Ratio: categórica vs continua ----
      if (input$estimator == "ratio") {
        
        num <- input$numerator
        den <- input$denominator
        
        vars <- design()$variables
        
        num_is_cat <- is.factor(vars[[num]]) || is.character(vars[[num]])
        den_is_cat <- is.factor(vars[[den]]) || is.character(vars[[den]])
        
        return(
          estimate_survey(
            design = des,
            estimator = "ratio",
            by = domain,
            numerator = num,
            denominator = den,
            ratio_num_level = if (num_is_cat) input$ratio_num_level else NULL,
            ratio_den_level = if (den_is_cat) input$ratio_den_level else NULL
          )
        )
      }
      
      
      # ---- Cuantiles ----
      if (input$estimator == "quantile") {
        
        probs <- trimws(unlist(strsplit(input$probs, ",")))
        probs <- sort(unique(as.numeric(probs)))
        shiny::req(length(probs) > 0, !any(is.na(probs)))
        
        return(
          estimate_survey(
            design = des,
            estimator = "quantile",
            variable = input$y_var,
            by = domain,
            probs = probs
          )
        )
      }
      
      # ---- Mean/Total/Prop ----
      estimate_survey(
        design = des,
        estimator = input$estimator,
        variable = input$y_var,
        by = domain
      )
      
    }, ignoreInit = TRUE)
    
    
    # ==================================================
    # 4. Salidas
    # ==================================================
    output$log <- shiny::renderPrint({
      if (is.null(results_r())) return("La estimación aún no ha sido ejecutada.")
      list(
        variable_interes = input$y_var,
        tipo_estimacion = input$estimator,
        dominios = if (is.null(input$domain_vars) || all(input$domain_vars == "")) "Global" else input$domain_vars
      )
    })
    
    output$preview <- DT::renderDT({
      res <- results_r()
      shiny::req(res)
      
      res_fmt <- res |>
        dplyr::mutate(dplyr::across(where(is.numeric), ~ round(.x, 3)))
      
      DT::datatable(
        res_fmt,
        rownames = FALSE,
        options = list(pageLength = 5, scrollX = TRUE)
      )
    })
    
    list(results = shiny::reactive(results_r()))
  })
}
