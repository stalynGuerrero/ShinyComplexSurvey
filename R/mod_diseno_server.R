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
    
    output$design_theory <- renderUI({
      
      req(input$design_type)
      
      switch(
        
        input$design_type,
        
        "srs" = tagList(
          
          withMathJax(),
          
          h5("Fundamento estadístico"),
          
          p("En el muestreo aleatorio simple cada unidad tiene la misma probabilidad de selección."),
          
          p("Estimador de la media poblacional:"),
          
          HTML("$$ \\hat{\\mu} = \\frac{1}{n} \\sum_{i=1}^{n} y_i $$"),
          
          p("Varianza del estimador:"),
          
          HTML("$$ Var(\\hat{\\mu}) = \\left(1 - \\frac{n}{N}\\right) \\frac{S^2}{n} $$"),
          
          p("donde \\(S^2\\) es la varianza poblacional.")
          
        ),
        
        
        "stratified" = tagList(
          
          withMathJax(),
          
          h5("Fundamento estadístico"),
          
          p("La población se divide en H estratos y el estimador total se obtiene como suma ponderada de los estimadores por estrato."),
          
          p("Estimador de la media estratificada:"),
          
          HTML("$$ \\hat{\\mu}_{st} = \\sum_{h=1}^{H} W_h \\bar{y}_h $$"),
          
          p("donde:"),
          
          HTML("$$ W_h = \\frac{N_h}{N} $$"),
          
          p("Varianza del estimador:"),
          
          HTML("$$ Var(\\hat{\\mu}_{st}) = \\sum_{h=1}^{H} W_h^2 \\left(1 - \\frac{n_h}{N_h}\\right) \\frac{S_h^2}{n_h} $$")
          
        ),
        
        
        "cluster" = tagList(
          
          withMathJax(),
          
          h5("Fundamento estadístico"),
          
          p("En muestreo por conglomerados se seleccionan grupos de unidades."),
          
          p("Estimador del total poblacional:"),
          
          HTML("$$ \\hat{Y} = \\frac{N}{n} \\sum_{i=1}^{n} t_i $$"),
          
          p("donde \\(t_i\\) es el total del conglomerado i."),
          
          p("Varianza aproximada:"),
          
          HTML("$$ Var(\\hat{Y}) = \\frac{N^2}{n} S_t^2 $$"),
          
          p("Este diseño introduce correlación intra-cluster que aumenta la varianza del estimador.")
          
        ),
        
        
        "two_stage" = tagList(
          
          withMathJax(),
          
          h5("Fundamento estadístico"),
          
          p("En muestreo bietápico primero se seleccionan UPM y luego unidades dentro de cada UPM."),
          
          p("Estimador de Horvitz-Thompson:"),
          
          HTML("$$ \\hat{Y} = \\sum_{i \\in s} \\frac{y_i}{\\pi_i} $$"),
          
          p("donde \\(\\pi_i\\) es la probabilidad de inclusión."),
          
          p("Varianza del estimador:"),
          
          HTML("$$ Var(\\hat{Y}) = \\sum_i \\sum_j \\left( \\frac{\\pi_{ij} - \\pi_i \\pi_j}{\\pi_{ij}} \\right) \\frac{y_i}{\\pi_i} \\frac{y_j}{\\pi_j} $$")
          
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
          build_survey_design(
            data   = df,
            weight = weight
          )
        },
        
        "stratified" = {
          shiny::req(strata)
          build_survey_design(
            data   = df,
            weight = weight,
            strata = strata
          )
        },
        
        "cluster" = {
          shiny::req(cluster)
          build_survey_design(
            data    = df,
            weight  = weight,
            cluster = cluster
          )
        },
        
        "two_stage" = {
          shiny::req(cluster)
          build_survey_design(
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