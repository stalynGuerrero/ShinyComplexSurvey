mod_diseno_server <- function(id, data) {
  
  shiny::moduleServer(id, function(input, output, session) {
    
    ns <- session$ns
    
    output$design_arguments <- shiny::renderUI({
   
      shiny::req(input$design_type)
      req(data())
      
      vars <- names(data())
      
      switch(
        input$design_type,
        
        "srs" = tagList(
          selectInput(ns("weight_var"),
                      "Peso muestral (opcional)",
                      choices = vars)
        ),
        
        "stratified" = tagList(
          selectInput(ns("strata_var"),
                      "Variable de estrato",
                      choices = vars),
          
          selectInput(ns("weight_var"),
                      "Peso muestral",
                      choices = vars)
        ),
        
        "cluster" = tagList(
          selectInput(ns("cluster_var"),
                      "UPM / Conglomerado",
                      choices = vars),
          
          selectInput(ns("weight_var"),
                      "Peso muestral",
                      choices = vars)
        ),
        
        "two_stage" = tagList(
          selectInput(ns("cluster_var"),
                      "UPM (primera etapa)",
                      choices = vars),
          
          selectInput(ns("strata_var"),
                      "Estrato",
                      choices = vars),
          
          selectInput(ns("weight_var"),
                      "Peso muestral",
                      choices = vars)
        )
      )
    })
    
    # =====================================================
    # 1. Actualizar selectores según la base
    # =====================================================
    
    shiny::observeEvent(data(), {
      
      df <- data()
      shiny::req(df)
      
      vars <- names(df)
      
      shiny::updateSelectInput(
        session, "weight_var",
        choices = vars,
        selected = vars[1]
      )
      
      shiny::updateSelectInput(
        session, "strata_var",
        choices = c("Ninguno" = "", vars)
      )
      
      shiny::updateSelectInput(
        session, "cluster_var",
        choices = c("Ninguno" = "", vars)
      )
      
    }, ignoreInit = TRUE)
    
    
    clean_input <- function(x){
      if (is.null(x) || length(x) == 0 || x == "") return(NULL)
      x
    }
    
    # =====================================================
    # 2. Construcción del diseño
    # =====================================================
    
    design_r <- shiny::eventReactive(input$build, {
      df <- data()
      shiny::req(df)
      shiny::req(input$design_type)
      
      weight  <- input$weight_var
      strata  <- clean_input(input$strata_var)
      cluster <- clean_input(input$cluster_var)
      
      des <- switch(
        
        input$design_type,
        
        "srs" = {
          as_survey_design_tbl(
            data   = df,
            weight = weight
          )
        },
        
        "stratified" = {
          shiny::req(strata)
          as_survey_design_tbl(
            data   = df,
            weight = weight,
            strata = strata
          )
        },
        
        "cluster" = {
          shiny::req(cluster)
          as_survey_design_tbl(
            data    = df,
            weight  = weight,
            cluster = cluster
          )
        },
        
        "two_stage" = {
          shiny::req(cluster)
          as_survey_design_tbl(
            data    = df,
            weight  = weight,
            strata  = strata,
            cluster = cluster
          )
        }
        
      )
      
      srvyr::as_survey_design(des)
      
    }, ignoreInit = TRUE)
    
    
    # =====================================================
    # 3. Log del diseño
    # =====================================================
    
    output$log <- shiny::renderPrint({
      
      shiny::req(input$design_type)
      
      tipo <- dplyr::case_when(
        input$design_type == "srs"        ~ "Muestreo Aleatorio Simple",
        input$design_type == "stratified" ~ "Diseño Estratificado",
        input$design_type == "cluster"    ~ "Diseño por Conglomerados",
        input$design_type == "two_stage"  ~ "Diseño Bietápico"
      )
      
      list(
        tipo_disenio = tipo,
        peso         = input$weight_var,
        estrato      = input$strata_var,
        upm          = input$cluster_var
      )
      
    })
    
    
    # =====================================================
    # 4. Resumen del diseño
    # =====================================================
    
    output$summary <- shiny::renderTable({
      
      shiny::req(design_r())
      
      describe_survey_design(
        design_r()
      )
      
    })
    
    
    # =====================================================
    # 5. Salida del módulo
    # =====================================================
    
    return(
      list(
        design = shiny::reactive({
          design_r()
        })
      )
    )
    
  })
}