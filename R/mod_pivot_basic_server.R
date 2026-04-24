mod_pivot_basic_server <- function(id, data) {

  shiny::moduleServer(id, function(input, output, session) {

    ns <- session$ns

    # -------------------------
    # Inicializar variables
    # -------------------------
    shiny::observe({

      df <- data()
      shiny::req(df)

      vars <- names(df)

      shiny::updateSelectInput(session, "rows", choices = vars, selected = vars[1])
      shiny::updateSelectInput(session, "cols", choices = vars, selected = vars[2])
      shiny::updateSelectInput(session, "vals", choices = vars, selected = vars[3])

    })

    # -------------------------
    # Pivot table (requires rpivotTable)
    # -------------------------
    output$pivot <- shiny::renderUI({
      if (!requireNamespace("rpivotTable", quietly = TRUE)) {
        return(shiny::p("Install the 'rpivotTable' package to enable this feature."))
      }

      df <- data()
      shiny::req(df)

      rpivotTable::rpivotTable(
        data           = df,
        rows           = input$rows,
        cols           = input$cols,
        vals           = input$vals,
        aggregatorName = "Average"
      )
    })

  })
}
