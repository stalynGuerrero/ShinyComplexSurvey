mod_design_ui <- function(id){
  ns <- NS(id)
  tagList(
    fluidRow(
      column(3, selectInput(ns('psu'), 'UPM (PSU)', choices = NULL)),
      column(3, uiOutput(ns("rep_type_ui"))),
      column(3, selectInput(ns('weight'), 'Factor', choices = NULL)),
    ),
    actionButton(ns('create'), 'Crear diseño'),
    verbatimTextOutput(ns('summary'))
  )
}

mod_design_server <- function(id, data){
  moduleServer(id, function(input, output, session){
    
  # Actualizar opciones con columnas de la base
    observe({
      req(data())
      cols <- names(data())
      updateSelectInput(session, 'psu',    choices = c("Sin UPM", cols))
      updateSelectInput(session, 'weight', choices = c('', cols))
    })
    
    # Mostrar selectInput de remuestreo solo si se selecciona "Sin UPM"
    output$rep_type_ui <- renderUI({
      req(input$psu)
      if (input$psu == "Sin UPM") {
        selectInput(session$ns('rep_type'),
                    'Método de remuestreo',
                    choices = c("JK1", "BRR", "bootstrap"),
                    selected = "JK1")
      }else{ 
        req(data())
        cols <- names(data())
        selectInput(session$ns('strata'), 'Estrato', choices = c('', cols))
        }
      
    })
    
    design <- eventReactive(input$create, {
      df <- data(); req(df)

      psu    <- if (input$psu    == '') NULL else input$psu
      strata <- if (input$strata == '' || input$psu == "Sin UPM" ) NULL else input$strata
      weight <- if (input$weight == '') NULL else input$weight
      rep_type <- input$rep_type
      
      if (is.null(psu)) {
        showModal(modalDialog(
          title = "Advertencia",
          "No se especificó UPM (PSU). Se usará un diseño de replicación."
        ))
      }
      
      make_survey_design(
        df,
        psu = psu,
        strata = strata,
        weight = weight,
        use_jack_if_nopsu = TRUE,
        replicates = 500,
        rep_type = rep_type   # <--- nuevo argumento
      )
    
    })
    
    output$summary <- renderPrint({
      d <- summary(design())
      if (is.null(d)) cat('Diseño no creado')
      else print(d)
    })
    
    return(list(design = design))
  })
}
