mod_resultados_server <- function(id, results) {
  shiny::moduleServer(id, function(input, output, session) {
    
    # =========================
    # TABLA DE RESULTADOS
    # =========================
    output$table <- DT::renderDT({
      
      res <- results()
      shiny::req(res)
      
      # Formato básico y profesional
      res_fmt <- res |>
        dplyr::mutate(
          estimate = round(estimate, 3),
          se       = round(se, 3),
          cv       = round(cv, 3),
          lci      = round(lci, 3),
          uci      = round(uci, 3)
        )
      
      DT::datatable(
        res_fmt,
        rownames = FALSE,
        options = list(
          pageLength = 10,
          autoWidth = TRUE
        )
      )
    })
    
    # =========================
    # GRÁFICO SIMPLE (opcional)
    # =========================
    output$plot <- shiny::renderPlot({
      
      res <- results()
      shiny::req(res)
      
      # dominio dinámico
      dom_vars <- setdiff(names(res), c("estimate","se","cv","lci","uci"))
      
      ggplot2::ggplot(
        res,
        ggplot2::aes(
          x = .data[[dom_vars[1]]],
          y = estimate
        )
      ) +
        ggplot2::geom_point() +
        ggplot2::geom_errorbar(
          ggplot2::aes(ymin = lci, ymax = uci),
          width = 0.2
        ) +
        ggplot2::theme_minimal() +
        ggplot2::labs(
          x = dom_vars[1],
          y = "Estimación"
        )
    })
  })
}
