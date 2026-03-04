mod_datos_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    
    # =========================
    # Contenedor reactivo
    # =========================
    data_r <- shiny::reactiveVal(NULL)
    
    # =========================
    # Cargar datos desde archivo
    # =========================
    shiny::observeEvent(input$file, {
      
      req(input$file)
      
      ext <- tools::file_ext(input$file$name)
      
      df <- switch(
        ext,
        "csv"  = readr::read_csv(input$file$datapath, show_col_types = FALSE),
        "rds"  = readRDS(input$file$datapath),
        "xlsx" = readxl::read_xlsx(input$file$datapath),
        stop("Formato de archivo no soportado")
      )
      
      data_r(df)
      
    }, ignoreInit = TRUE)
    
    # =========================
    # Cargar datos de ejemplo
    # =========================
    shiny::observeEvent(input$load_example, {
      
      df <- ShinyComplexSurvey::generate_example_data()
      data_r(df)
      
    }, ignoreInit = TRUE)
    
    # =========================
    # Vista previa
    # =========================
    output$preview <- DT::renderDT({
      req(data_r())
      head(data_r(), 100)
    })
    
    # =========================
    # Log de estado
    # =========================
    output$log <- shiny::renderPrint({
      
      if (is.null(data_r())) {
        return("No se han cargado datos.")
      }
      
      list(
        filas = nrow(data_r()),
        columnas = ncol(data_r()),
        variables = names(data_r())
      )
    })
    
    # =========================
    # Salida del módulo
    # =========================
    return(list(
      data = shiny::reactive({ data_r() })
    ))
  })
}
