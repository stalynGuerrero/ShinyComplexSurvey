mod_upload_ui <- function(id) {
  ns <- NS(id)
  tagList(fileInput(
    ns('file'),
    'Cargar archivo',
    accept = c(
      '.rds',
      '.rdata',
      '.csv',
      '.txt',
      '.dta',
      '.xlsx',
      '.xls',
      '.sas7bdat'
    )
  ),
  DT::DTOutput(ns('preview')))
}

mod_upload_server <- function(id){
  moduleServer(id, function(input, output, session){
    data <- reactiveVal(NULL)
    observeEvent(input$file, {
      req(input$file)
      df <- tryCatch(
        read_any(input$file$datapath, tools::file_ext(input$file$name)),
        error = function(e) {
          showModal(modalDialog('Error', e$message))
          return(NULL)
        }
      )
      df <- clean_haven(df)
      df <- data.frame(df)  # Convertir a data.frame si es necesario
      data(df)
      
    })
    
    output$preview <- DT::renderDT({
      req(data())
      DT::datatable(
        head(data(), 200),
        rownames = FALSE,
        filter = "top",   # filtros arriba de cada columna
        extensions = c("Buttons", "ColReorder", "FixedHeader"),
        options = list(
          dom = "Bfrtip",   # B=Buttons, f=filter, r=processing, t=table, i=info, p=pagination
          buttons = c("copy", "csv", "excel", "pdf", "print"),
          colReorder = TRUE,
          fixedHeader = TRUE,
          pageLength = 20,
          autoWidth = TRUE,
          scrollX = TRUE
        ),
        class = "display nowrap stripe hover"  # estilo moderno
      )
    })
    
    return(list(data = data))
  })
}
