mod_diseno_server <- function(id, data) {
  shiny::moduleServer(id, function(input, output, session) {
    
    ns <- session$ns
    
    # =========================
    # 1. Actualizar selectores según la base
    # =========================
    shiny::observeEvent(data(), {
      
      df <- data()
      req(df)
      
      vars <- names(df)
      
      shiny::updateSelectInput(session, "weight_var",  choices = vars)
      shiny::updateSelectInput(session, "strata_var",  choices = c("Ninguno" = "", vars))
      shiny::updateSelectInput(session, "cluster_var", choices = c("Ninguno" = "", vars))
      
    }, ignoreInit = TRUE)
    
    # =========================
    # 2. Construcción del diseño (controlada por botón)
    # =========================
    design_r <- shiny::eventReactive(input$build, {
      
      df <- data()
      req(df)
      req(input$weight_var)
      
      strata  <- if (input$strata_var  == "") NULL else input$strata_var
      cluster <- if (input$cluster_var == "") NULL else input$cluster_var
      
      des <- ShinyComplexSurvey::build_survey_design(
        data    = df,
        weight  = input$weight_var,
        strata  = strata,
        cluster = cluster
      )
      
      srvyr::as_survey_design(des)
    }, ignoreInit = TRUE)
    
    
    # =========================
    # 3. Log de estado
    # =========================
    output$log <- shiny::renderPrint({
      
      if (is.null(design_r())) {
        return("El diseño aún no ha sido construido.")
      }
      
      tipo <- dplyr::case_when(
        input$strata_var  != "" & input$cluster_var != "" ~ "Bietápico",
        input$strata_var  != ""                           ~ "Estratificado",
        input$cluster_var != ""                           ~ "Conglomerado",
        TRUE                                               ~ "MAS"
      )
      
      list(
        tipo_disenio = tipo,
        peso         = input$weight_var,
        estrato      = input$strata_var,
        upm          = input$cluster_var
      )
    })
    
    
    # =========================
    # 4. Resumen del diseño
    # =========================
    output$summary <- shiny::renderTable({
      req(design_r())
      ShinyComplexSurvey::describe_survey_design(design_r())
    })
    
    # =========================
    # 5. Salida del módulo
    # =========================
    return(list(
      design = shiny::reactive({ design_r() })
    ))
  })
}
