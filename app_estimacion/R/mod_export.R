# mod_export.R
mod_export_ui <- function(id){
  ns <- NS(id)
  tagList(
    textInput(ns('filename'),'Nombre archivo (sin extensión)', value = 'resultados'),
    downloadButton(ns('download_csv'),'Descargar CSV'),
    downloadButton(ns('download_xlsx'),'Descargar XLSX')
  )
}

mod_export_server <- function(id, data, results){
  moduleServer(id, function(input, output, session){
    output$download_csv <- downloadHandler(
      filename = function() paste0(input$filename, '.csv'),
      content = function(file) write.csv(results(), file, row.names = FALSE)
    )
    output$download_xlsx <- downloadHandler(
      filename = function() paste0(input$filename, '.xlsx'),
      content = function(file) openxlsx::write.xlsx(results(), file)
    )
  })
}