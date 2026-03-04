mod_diagnostico_server <- function(id, datos, diseno, estimacion) {
  shiny::moduleServer(id, function(input, output, session) {
    
    output$status <- shiny::renderPrint({
      list(
        datos_disponibles = !is.null(datos$data()),
        diseno_disponible = !is.null(diseno$design()),
        estimacion_disponible = !is.null(estimacion$results())
      )
    })
    
    output$objects <- shiny::renderPrint({
      list(
        datos = if (!is.null(datos$data())) names(datos$data()) else NULL,
        design_class = if (!is.null(diseno$design())) class(diseno$design()) else NULL,
        results_class = if (!is.null(estimacion$results())) class(estimacion$results()) else NULL
      )
    })
  })
}
