mod_resultados_server <- function(id, estimacion) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # 1. Datos base
    results_df <- shiny::reactive({
      shiny::req(estimacion())
    })
    
    # 2. Actualización inteligente de selectores
    shiny::observeEvent(results_df(), {
      df <- results_df()
      vars <- names(df)
      
      shiny::updateSelectInput(session, "row_var", choices = vars, selected = vars[1])
      shiny::updateSelectInput(session, "col_var", choices = c("Ninguna" = "None", vars), selected = "None")
      
      # Intentar seleccionar 'estimate' por defecto si existe
      def_val <- if("estimate" %in% vars) "estimate" else vars[length(vars)]
      shiny::updateSelectInput(session, "value_var", choices = vars, selected = def_val)
    })
    
    # 3. Editor de etiquetas (Reactivo persistente)
    editor_data <- shiny::reactiveVal(NULL)
    
    shiny::observe({
      df <- results_df()
      shiny::req(df)
      if ("variable" %in% names(df)) {
        unique_vars <- unique(df$variable)
        if (is.null(editor_data()) || !all(unique_vars %in% editor_data()$variable)) {
          editor_data(data.frame(
            variable = unique_vars,
            etiqueta = unique_vars,
            orden = seq_along(unique_vars),
            stringsAsFactors = FALSE
          ))
        }
      }
    })
    
    # 4. Lógica de Tabla Pivot Ampliada
    tabla_pivot <- shiny::reactive({
      df <- results_df()
      row_v <- input$row_var
      col_v <- input$col_var
      val_v <- input$value_var
      agg_f <- input$agg_fun
      
      shiny::req(df, row_v, val_v)
      
      # Agregación base
      res <- df |>
        dplyr::group_by(dplyr::across(dplyr::all_of(row_v)))
      
      if (col_v != "None") {
        res <- res |> dplyr::group_by(dplyr::across(dplyr::all_of(col_v)), .add = TRUE)
      }
      
      res <- res |> 
        dplyr::summarise(
          dplyr::across(dplyr::all_of(val_v), ~match.fun(agg_f)(.x, na.rm = TRUE), .names = "{.col}"),
          .groups = "drop"
        )
      
      # Pivotado si hay columnas seleccionadas
      if (col_v != "None") {
        res <- res |> 
          tidyr::pivot_wider(
            names_from = dplyr::all_of(col_v),
            values_from = dplyr::all_of(val_v),
            names_glue = "{.value}_{.name}"
          )
      }
      res
    })
    
    # --- Outputs ---
    
    output$table <- DT::renderDT({
      shiny::req(tabla_pivot())
      DT::datatable(tabla_pivot(), 
                    extensions = 'Buttons', 
                    options = list(dom = 'Bfrtip', buttons = c('copy', 'csv', 'excel'), scrollX = TRUE))
    })
    
    output$editor <- DT::renderDT({
      shiny::req(editor_data())
      DT::datatable(editor_data(), editable = 'cell', selection = 'none')
    })
    
    shiny::observeEvent(input$editor_cell_edit, {
      df <- editor_data()
      df <- DT::editData(df, input$editor_cell_edit, 'editor')
      editor_data(df)
    })
    
    output$plot <- shiny::renderPlot({
      df <- results_df()
      ed <- editor_data()
      shiny::req(df, ed, "estimate" %in% names(df))
      
      plot_df <- df |> 
        dplyr::left_join(ed, by = "variable") |> 
        dplyr::mutate(etiqueta = stats::reorder(etiqueta, estimate))
      
      p <- ggplot2::ggplot(plot_df, ggplot2::aes(x = etiqueta, y = estimate)) +
        ggplot2::geom_col(fill = "steelblue") +
        ggplot2::coord_flip() +
        ggplot2::theme_minimal(base_size = 14)
      
      if("se" %in% names(plot_df)) {
        p <- p + ggplot2::geom_errorbar(ggplot2::aes(ymin = estimate - 1.96*se, ymax = estimate + 1.96*se), width = 0.2)
      }
      p
    })
    
    return(list(tabla = tabla_pivot, etiquetas = editor_data))
  })
}