mod_datos_server <- function(id, dict) {
  shiny::moduleServer(id, function(input, output, session) {

    output$title <- shiny::renderText({
      i18n_t(dict(), "mod_datos.title")
    })

    output$input_panel <- shiny::renderText({
      i18n_t(dict(), "mod_datos.input_panel")
    })

    output$source_card <- shiny::renderText({
      i18n_t(dict(), "mod_datos.source_card")
    })

    output$preview_card <- shiny::renderText({
      i18n_t(dict(), "mod_datos.preview_card")
    })

    output$status <- shiny::renderText({
      i18n_t(dict(), "mod_datos.status")
    })

    data_r <- shiny::reactiveVal(NULL)

    output$file_ui <- shiny::renderUI({
      shiny::fileInput(
        session$ns("file"),
        label  = i18n_t(dict(), "mod_datos.file_label"),
        accept = c(".csv", ".rds", ".xlsx")
      )
    })

    shiny::observe({
      shiny::updateActionButton(
        session, "load_example",
        label = i18n_t(dict(), "mod_datos.example_btn")
      )
    })

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

    shiny::observeEvent(input$load_example, {

      df <- ShinyComplexSurvey::generate_example_data()
      data_r(df)

    }, ignoreInit = TRUE)

    output$preview <- DT::renderDT({
      req(data_r())
      head(data_r(), 100)
    })

    output$log <- shiny::renderPrint({

      if (is.null(data_r())) {
        return(i18n_t(dict(), "mod_datos.no_data"))
      }

      d <- dict()
      stats::setNames(
        list(nrow(data_r()), ncol(data_r()), names(data_r())),
        c(i18n_t(d, "mod_datos.log_rows"),
          i18n_t(d, "mod_datos.log_cols"),
          i18n_t(d, "mod_datos.log_vars"))
      )
    })

    return(list(
      data = shiny::reactive({ data_r() })
    ))
  })
}
