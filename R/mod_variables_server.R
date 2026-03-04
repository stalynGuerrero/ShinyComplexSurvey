mod_variables_server <- function(id, data) {
  shiny::moduleServer(id, function(input, output, session) {
    
    # ==================================================
    # Base mutable (copia)
    # ==================================================
    data_var <- shiny::reactiveVal(NULL)
    
    shiny::observeEvent(data(), {
      req(data())
      data_var(data())
    }, ignoreInit = TRUE)
    
    # ==================================================
    # Actualizar variables disponibles
    # ==================================================
    shiny::observeEvent(data_var(), {
      vars <- names(data_var())
      shiny::updateSelectInput(session, "base_var", choices = vars)
    }, ignoreInit = TRUE)
    
    # ==================================================
    # UI dinámico de categorías
    # ==================================================
    output$categorias_ui <- shiny::renderUI({
      req(input$n_cat)
      
      lapply(seq_len(input$n_cat), function(i) {
        shiny::wellPanel(
          shiny::h5(paste("Categoría", i)),
          
          shiny::selectInput(
            session$ns(paste0("cat_op_", i)),
            "Condición",
            choices = c(
              "<"      = "lt",
              "<="     = "le",
              ">"      = "gt",
              ">="     = "ge",
              "=="     = "eq",
              "Entre"  = "between"
            )
          ),
          
          shiny::numericInput(
            session$ns(paste0("cat_val1_", i)),
            "Valor 1",
            value = 0
          ),
          
          shiny::conditionalPanel(
            condition = sprintf(
              "input['%s'] == 'between'",
              session$ns(paste0("cat_op_", i))
            ),
            shiny::numericInput(
              session$ns(paste0("cat_val2_", i)),
              "Valor 2",
              value = 1
            )
          ),
          
          shiny::textInput(
            session$ns(paste0("cat_label_", i)),
            "Etiqueta",
            value = paste("Cat", i)
          )
        )
      })
    })
    
    # ==================================================
    # MODO AVANZADO
    # ==================================================
    shiny::observeEvent(input$run_code, {
      
      req(data_var())
      req(input$code)
      
      env <- rlang::env(
        data  = data_var(),
        dplyr = asNamespace("dplyr")
      )
      
      tryCatch({
        
        eval(parse(text = input$code), envir = env)
        stopifnot(is.data.frame(env$data))
        data_var(env$data)
        
        output$log_code <- shiny::renderPrint(
          "Código ejecutado correctamente."
        )
        
      }, error = function(e) {
        output$log_code <- shiny::renderPrint(
          paste("Error:", e$message)
        )
      })
    })
    
    # ==================================================
    # MODO ASISTIDO
    # ==================================================
    shiny::observeEvent(input$apply_calc, {
      
      df <- data_var()
      req(df, input$new_var, input$base_var)
      
      if (input$var_type == "numeric") {
        
        df[[input$new_var]] <- switch(
          input$operation,
          div = df[[input$base_var]] / input$value,
          sum = df[[input$base_var]] + input$value,
          sub = df[[input$base_var]] - input$value,
          mul = df[[input$base_var]] * input$value,
          lt  = df[[input$base_var]] < input$value
        )
      }
      
      if (input$var_type == "categorical") {
        
        rules <- lapply(seq_len(input$n_cat), function(i) {
          list(
            op    = input[[paste0("cat_op_", i)]],
            v1    = input[[paste0("cat_val1_", i)]],
            v2    = input[[paste0("cat_val2_", i)]],
            label = input[[paste0("cat_label_", i)]]
          )
        })
        
        df[[input$new_var]] <- build_case_when(
          x     = df[[input$base_var]],
          rules = rules
        )
      }
      
      data_var(df)
      
      output$log_calc <- shiny::renderPrint({
        paste("Variable creada:", input$new_var)
      })
    })
    
    # ==================================================
    # Salida del módulo
    # ==================================================
    return(list(
      data = shiny::reactive({ data_var() })
    ))
  })
}
