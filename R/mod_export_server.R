mod_export_server <- function(id, results) {
  shiny::moduleServer(id, function(input, output, session) {
    
    output$download <- shiny::downloadHandler(
      filename = function() {
        "resultados.zip"
      },
      content = function(file) {
        # lógica de exportación
      }
    )
    
    output$log <- shiny::renderPrint({
      "Seleccione las opciones de exportación."
    })
  })
}
