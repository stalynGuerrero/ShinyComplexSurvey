mod_diagnostico_server <- function(id, datos, diseno, estimacion) {
  
  shiny::moduleServer(id, function(input, output, session) {
    browser()
    ns <- session$ns
    
    # ---------------------------
    # Acceso seguro a reactivos
    # ---------------------------
    
    datos_df <- shiny::reactive({
      if (is.null(datos) || is.null(datos$data)) return(NULL)
      datos$data()
    })
    
    design_obj <- shiny::reactive({
      if (is.null(diseno) || is.null(diseno$design)) return(NULL)
      diseno$design()
    })
    
    results_df <- shiny::reactive({
      if (is.null(estimacion) || is.null(estimacion$results)) return(NULL)
      estimacion$results()
    })
    
    
    # ---------------------------
    # Estado del pipeline
    # ---------------------------
    
    output$status <- shiny::renderPrint({
      
      list(
        datos_disponibles = !is.null(datos_df()),
        diseno_disponible = !is.null(design_obj()),
        estimacion_disponible = !is.null(results_df())
      )
      
    })
    
    
    output$objects <- shiny::renderPrint({
      
      list(
        variables_datos = if (!is.null(datos_df())) names(datos_df()) else NULL,
        clase_diseno = if (!is.null(design_obj())) class(design_obj()) else NULL,
        clase_resultados = if (!is.null(results_df())) class(results_df()) else NULL
      )
      
    })
    
    
    # ---------------------------
    # Diagnóstico de precisión
    # ---------------------------
    
    diagnostico_data <- shiny::reactive({
      
      df <- results_df()
      
      shiny::req(df)
      
      if (!"cv" %in% names(df) && "se" %in% names(df)) {
        df$cv <- df$se / df$estimate
      }
      
      if ("deff" %in% names(df) && "n" %in% names(df)) {
        df$n_eff <- df$n / df$deff
      }
      
      df
      
    })
    
    
    output$quality_table <- DT::renderDT({
      
      shiny::req(diagnostico_data())
      
      DT::datatable(
        diagnostico_data(),
        options = list(
          pageLength = 10,
          scrollX = TRUE
        )
      )
      
    })
    
    
    # ---------------------------
    # Editor de nombres
    # ---------------------------
    
    editor_data <- shiny::reactiveVal(NULL)
    
    
    shiny::observe({
      
      df <- results_df()
      
      shiny::req(df)
      
      if (is.null(editor_data())) {
        
        editor_data(
          data.frame(
            variable_original = names(df),
            etiqueta = names(df),
            stringsAsFactors = FALSE
          )
        )
        
      }
      
    })
    
    
    output$editor <- DT::renderDT({
      
      shiny::req(editor_data())
      
      DT::datatable(
        editor_data(),
        editable = "cell",
        options = list(pageLength = 20)
      )
      
    })
    
    
    shiny::observeEvent(input$editor_cell_edit, {
      
      info <- input$editor_cell_edit
      
      df <- editor_data()
      
      df[info$row, info$col] <- info$value
      
      editor_data(df)
      
    })
    
    
    # ---------------------------
    # Salida del módulo
    # ---------------------------
    
    return(
      list(
        diagnostico = diagnostico_data,
        etiquetas = shiny::reactive(editor_data())
      )
    )
    
  })
}