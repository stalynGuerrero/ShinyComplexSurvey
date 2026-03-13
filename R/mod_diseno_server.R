mod_diseno_server <- function(id, data){
  
  shiny::moduleServer(id, function(input, output, session){
    
    ns <- session$ns
    
    
    # -------------------------------------------------
    # Teoría del diseño
    # -------------------------------------------------
    
    output$design_theory <- shiny::renderUI({
      
      req(input$design_type)
      
      switch(
        
        input$design_type,
        
        
        "srs" = tagList(
          
          withMathJax(),
          
          h5("Muestreo Aleatorio Simple (SRS)"),
          
          p("Cada unidad de la población tiene la misma probabilidad de ser seleccionada."),
          
          h6("Estimador de la media poblacional"),
          
          HTML("$$ \\hat{\\bar{Y}} = \\frac{1}{n} \\sum_{i=1}^{n} y_i $$"),
          
          h6("Varianza del estimador"),
          
          HTML("$$ Var(\\hat{\\bar{Y}}) =
           \\left(1-\\frac{n}{N}\\right)\\frac{S^2}{n} $$"),
          
          h6("Definición de los términos"),
          
          tags$ul(
            tags$li(HTML("\\(y_i\\): valor observado de la variable para la unidad i.")),
            tags$li(HTML("\\(n\\): tamaño de la muestra.")),
            tags$li(HTML("\\(N\\): tamaño de la población.")),
            tags$li(HTML("\\(S^2\\): varianza poblacional de la variable de interés.")),
            tags$li(HTML("\\(\\hat{\\bar{Y}}\\): estimador de la media poblacional."))
          )
          
        ),
        
        
        "stratified" = tagList(
          
          withMathJax(),
          
          h5("Muestreo Estratificado"),
          
          p("La población se divide en subgrupos homogéneos llamados estratos."),
          
          h6("Estimador de la media estratificada"),
          
          HTML("$$ \\hat{\\bar{Y}}_{st} =
           \\sum_{h=1}^{H} W_h \\bar{y}_h $$"),
          
          h6("Varianza del estimador"),
          
          HTML("$$ Var(\\hat{\\bar{Y}}_{st}) =
           \\sum_{h=1}^{H}
           W_h^2
           \\left(1-\\frac{n_h}{N_h}\\right)
           \\frac{S_h^2}{n_h} $$"),
          
          h6("Definición de los términos"),
          
          tags$ul(
            tags$li(HTML("\\(H\\): número total de estratos.")),
            tags$li(HTML("\\(W_h = N_h/N\\): peso poblacional del estrato \\(h\\).")),
            tags$li(HTML("\\(N_h\\): tamaño poblacional del estrato \\(h\\).")),
            tags$li(HTML("\\(n_h\\): tamaño de muestra en el estrato \\(h\\).")),
            tags$li(HTML("\\(\\bar{y}_h\\): media muestral del estrato \\(h\\).")),
            tags$li(HTML("\\(S_h^2\\): varianza dentro del estrato \\(h\\).")),
            tags$li(HTML("\\(\\hat{\\bar{Y}}_{st}\\): estimador estratificado de la media poblacional."))
          )
          
        ),
        
        
        "cluster" = tagList(
          
          withMathJax(),
          
          h5("Muestreo por Conglomerados / Multietápico"),
          
          p("Las unidades se seleccionan en grupos llamados conglomerados o UPM."),
          
          h6("Estimador de Horvitz–Thompson"),
          
          HTML("$$ \\hat{Y} =
           \\sum_{i \\in s}
           \\frac{y_i}{\\pi_i} $$"),
          
          h6("Varianza del estimador"),
          
          HTML("$$ Var(\\hat{Y}) =
           \\sum_i \\sum_j
           \\left(
           \\frac{\\pi_{ij}-\\pi_i\\pi_j}{\\pi_{ij}}
           \\right)
           \\frac{y_i}{\\pi_i}
           \\frac{y_j}{\\pi_j} $$"),
          
          h6("Definición de los términos"),
          
          tags$ul(
            tags$li(HTML("\\(y_i\\): valor observado para la unidad \\(i\\).")),
            tags$li(HTML("\\(s\\): conjunto de unidades seleccionadas en la muestra.")),
            tags$li(HTML("\\(\\pi_i\\): probabilidad de inclusión de la unidad \\(i\\).")),
            tags$li(HTML("\\(\\pi_{ij}\\): probabilidad conjunta de inclusión de las unidades \\(i\\) y \\(j\\).")),
            tags$li(HTML("\\(1/\\pi_i\\): peso muestral de la unidad \\(i\\).")),
            tags$li(HTML("\\(\\hat{Y}\\): estimador del total poblacional."))
          )
          
        )
        
      )
    })
    
    # -------------------------------------------------
    # Argumentos del diseño
    # -------------------------------------------------
    
    output$design_arguments <- shiny::renderUI({
      
      req(data())
      
      vars <- names(data())
      
      switch(
        
        input$design_type,
        
        
        "srs" = tagList(
          
          selectInput(
            ns("weight_var"),
            "Peso muestral",
            choices = vars
          )
          
        ),
        
        
        "stratified" = tagList(
          
          selectInput(
            ns("strata_var"),
            "Variable de estrato",
            choices = vars
          ),
          
          selectInput(
            ns("weight_var"),
            "Peso muestral",
            choices = vars
          )
          
        ),
        
        
        "cluster" = tagList(
          
          numericInput(
            ns("n_stages"),
            "Número de etapas",
            value = 2,
            min = 1,
            max = 5
          ),
          
          uiOutput(ns("stage_clusters")),
          
          selectInput(
            ns("strata_var"),
            "Estrato",
            choices = c("Ninguno" = "", vars)
          ),
          
          selectInput(
            ns("weight_var"),
            "Peso muestral",
            choices = vars
          ),
          
          selectInput(
            ns("lonely_psu"),
            "Estrategia último conglomerado",
            choices = c(
              "Ajuste conservador" = "adjust",
              "Promedio del estrato" = "average",
              "Eliminar estrato" = "remove",
              "Certidumbre" = "certainty"
            ),
            selected = "adjust"
          )
          
        )
        
      )
    })
    
    
    
    # -------------------------------------------------
    # Generar etapas dinámicas
    # -------------------------------------------------
    
    output$stage_clusters <- shiny::renderUI({
      
      req(input$n_stages)
      req(data())
      
      vars <- names(data())
      
      lapply(
        seq_len(input$n_stages),
        function(i){
          
          selectInput(
            ns(paste0("cluster_stage_", i)),
            paste("Conglomerado etapa", i),
            choices = vars
          )
          
        }
      )
      
    })
    
    
    
    # -------------------------------------------------
    # Función limpieza
    # -------------------------------------------------
    
    clean_input <- function(x){
      
      if(is.null(x) || x == "") return(NULL)
      x
      
    }
    
    
    # -------------------------------------------------
    # Construcción del diseño
    # -------------------------------------------------
    
    design_r <- shiny::eventReactive(input$build,{
      
      df <- data()
      req(df)
      
      weight <- input$weight_var
      
      
      if(input$design_type == "srs"){
        
        des <- survey::svydesign(
          id = ~1,
          weights = as.formula(paste("~",weight)),
          data = df
        )
        
      }
      
      
      if(input$design_type == "stratified"){
        
        strata <- input$strata_var
        
        des <- survey::svydesign(
          id = ~1,
          strata = as.formula(paste("~",strata)),
          weights = as.formula(paste("~",weight)),
          data = df
        )
        
      }
      
      
      if(input$design_type == "cluster"){
        
        clusters <- sapply(
          seq_len(input$n_stages),
          function(i)
            input[[paste0("cluster_stage_",i)]]
        )
        
        id_formula <- as.formula(
          paste("~",paste(clusters,collapse="+"))
        )
        
        strata <- clean_input(input$strata_var)
        
        options(
          survey.lonely.psu = input$lonely_psu
        )
        
        des <- survey::svydesign(
          id = id_formula,
          strata = if(!is.null(strata))
            as.formula(paste("~",strata))
          else NULL,
          weights = as.formula(paste("~",weight)),
          data = df,
          nest = TRUE
        )
        
      }
      
      
      srvyr::as_survey_design(des)
      
    })
    
    
    
    # -------------------------------------------------
    # Log reactivo
    # -------------------------------------------------
    
    log_design <- reactiveVal(NULL)
    
    observeEvent(input$design_type,{
      
      log_design(NULL)
      
    }, ignoreInit = TRUE)
    
    
    
    # -------------------------------------------------
    # Construcción del diseño
    # -------------------------------------------------
    
    design_r <- eventReactive(input$build,{
      
      df <- data()
      req(df)
      
      weight <- input$weight_var
      
      if(input$design_type == "srs"){
        
        des <- survey::svydesign(
          id = ~1,
          weights = as.formula(paste("~", weight)),
          data = df
        )
        
        formula_design <- paste0(
          "svydesign(\n",
          "  id = ~1,\n",
          "  weights = ~", weight, ",\n",
          "  data = data\n",
          ")"
        )
        
      }
      
      
      if(input$design_type == "stratified"){
        
        strata <- input$strata_var
        
        des <- survey::svydesign(
          id = ~1,
          strata = as.formula(paste("~", strata)),
          weights = as.formula(paste("~", weight)),
          data = df
        )
        
        formula_design <- paste0(
          "svydesign(\n",
          "  id = ~1,\n",
          "  strata = ~", strata, ",\n",
          "  weights = ~", weight, ",\n",
          "  data = data\n",
          ")"
        )
        
      }
      
      
      if(input$design_type == "cluster"){
        
        clusters <- sapply(
          seq_len(input$n_stages),
          function(i)
            input[[paste0("cluster_stage_", i)]]
        )
        
        id_formula <- as.formula(
          paste("~", paste(clusters, collapse = "+"))
        )
        
        strata <- clean_input(input$strata_var)
        
        options(
          survey.lonely.psu = input$lonely_psu
        )
        
        des <- survey::svydesign(
          id = id_formula,
          strata = if(!is.null(strata))
            as.formula(paste("~", strata))
          else NULL,
          weights = as.formula(paste("~", weight)),
          data = df,
          nest = TRUE
        )
        
        formula_design <- paste0(
          "svydesign(\n",
          "  id = ~", paste(clusters, collapse = " + "), ",\n",
          if(!is.null(strata)) paste0("  strata = ~", strata, ",\n") else "",
          "  weights = ~", weight, ",\n",
          "  nest = TRUE,\n",
          "  data = data\n",
          ")"
        )
        
      }
      
      
      log_design(
        list(
          tipo = input$design_type,
          formula_R = formula_design,
          etapas = input$n_stages,
          lonely_psu = input$lonely_psu
        )
      )
      
      srvyr::as_survey_design(des)
      
    })
    
    
    
    # -------------------------------------------------
    # Código del diseño
    # -------------------------------------------------
    
    output$design_code <- renderText({
      
      req(log_design())
      
      log_design()$formula_R
      
    })
    
    
    
    # -------------------------------------------------
    # Log
    # -------------------------------------------------
    
    output$log <- renderPrint({
      
      log_design()
      
    })
    
    
    
    # -------------------------------------------------
    # Resumen del diseño
    # -------------------------------------------------
    
    output$summary <- renderTable({
      
      req(design_r())
      
      describe_survey_design(design_r())
      
    })
    
    # -------------------------------------------------
    # Salida del módulo
    # -------------------------------------------------
    
    return(
      
      list(
        
        design = shiny::reactive(
          design_r()
        )
        
      )
      
    )
    
  })
}