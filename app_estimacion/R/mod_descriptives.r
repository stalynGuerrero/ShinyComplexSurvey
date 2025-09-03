# ============================================================
# UI: descriptivos
# ============================================================
mod_descriptives_ui <- function(id) {
  ns <- NS(id)
  tagList(
    tabsetPanel(
      tabPanel("Resumen",
               # Fila 1: variable principal + tipo
               fluidRow(
                 column(6, selectInput(ns('var'), 'Variable', choices = NULL)),
                 column(6, radioButtons(
                   ns('type'),
                   'Tipo',
                   choices = c('Auto' = 'auto', 'Numérico' = 'num', 'Categórico' = 'cat'),
                   inline = TRUE
                 ))
               ),
               
               # Fila 2: filtros
               fluidRow(
                 column(4,
                        selectInput(ns("filter_var1"), "Filtrar por variable 1", choices = c('', NULL)),
                        uiOutput(ns("filter_val1"))
                 ),
                 column(4,
                        selectInput(ns("filter_var2"), "Filtrar por variable 2", choices = c('', NULL)),
                        uiOutput(ns("filter_val2"))
                 ),
                 column(4,
                        selectInput(ns("filter_var3"), "Filtrar por variable 3", choices = c('', NULL)),
                        uiOutput(ns("filter_val3"))
                 )
               ),
               
               # Fila 3: agrupación
               fluidRow(
                 column(12, selectInput(
                   ns('by'),
                   'Agrupar por (hasta 4 variables)',
                   choices = c('', NULL),
                   multiple = TRUE,
                   selectize = TRUE
                 ))
               ),
               
               # Botón de acción y tabla de salida
               actionButton(ns('run'), 'Calcular'),
               DT::DTOutput(ns('table')),
               
               # Leyendas de interpretación del CVE
               fluidRow(
                 column(12,
                        tags$div(
                          style = "margin-top: 15px; font-size: 13px;",
                          tags$b("Interpretación según el Coeficiente de Variación (CVE):"),
                          
                          tags$h5("Criterios DANE"),
                          tags$ul(
                            tags$li("CVE < 3% → Estimación Excelente."),
                            tags$li("3% ≤ CVE < 5%  → Estimación de buena calidad,"),
                            tags$li("5% ≤ CVE < 15% → Estimación de buena calidad,."),
                            tags$li("CVE ≥ 15% → Estimación poco confiable, no se recomienda su uso.")
                          ),
                          tags$p(
                            "Fuente: ",
                            tags$a("DANE - Guía para la Interpretación del Error Muestral en Términos del Coeficiente de Variación e Intervalo de Confianza Estimado Encuesta de Sacrificio de Ganado – ESAG", 
                                   href = "https://www.dane.gov.co/files/investigaciones/boletines/sacrificio/Anexo_Guia14.pdf", 
                                   target = "_blank")
                          )
                        )
                 )
               ), 
               hr(),
               fluidRow(column(3, selectInput(
                 ns("plot_type"),
                 "Métrica para gráfico:",
                 choices = c("Media", "Total", "Proporción")
               )),
               column(3, actionButton(ns("run_plot"), "Graficar")),
               column(
                 3,
                 selectInput(
                   ns("palette"),
                   "Paleta de colores:",
                   choices = c("Blues", "Reds", "Greens", "Set1", "Dark2", "Paired", "Viridis"),
                   selected = "Set1"
                 )
               )), 
               # Mostrar menú para elegir variable del eje X
               fluidRow(
                 column(12, uiOutput(ns("group_var_ui")))
               ),
               
               plotly::plotlyOutput(ns("plot"), height = "400px"), 
               tabPanel("Gráfica avanzada",
                        fluidPage(
                          actionButton(ns("btn_show_esq"), "Generar gráfica avanzada", icon = icon("chart-area")),
                          br(), br(),
                          uiOutput(ns("esq_ui"))
                        )
               )
        
               )
      
      
      # --- Pestaña de exploración con esquisse ---
     
    )
  )
}

# ============================================================
# SERVER: descriptivos
# ============================================================
mod_descriptives_server <- function(id, design) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # --- Inicializar opciones ---
    observe({
      req(design())
      df <- design()$variables
      
      cols <- names(df)
      updateSelectInput(session, 'var', choices = cols)
      updateSelectInput(session, 'by', choices = cols)
      updateSelectInput(session, 'filter_var1', choices = c('', cols))
      updateSelectInput(session, 'filter_var2', choices = c('', cols))
      updateSelectInput(session, 'filter_var3', choices = c('', cols))
    })
    
    # --- Filtros estáticos definidos por el usuario ---
    data <- reactive({ req(design()); design()$variables })
    
    output$filter_val1 <- renderUI({
      req(input$filter_var1, input$filter_var1 != "")
      vals <- unique(data()[[input$filter_var1]])
      selectInput(session$ns("filter_val1_sel"), "Valores", choices = vals, multiple = TRUE)
    })
    output$filter_val2 <- renderUI({
      req(input$filter_var2, input$filter_var2 != "")
      vals <- unique(data()[[input$filter_var2]])
      selectInput(session$ns("filter_val2_sel"), "Valores", choices = vals, multiple = TRUE)
    })
    output$filter_val3 <- renderUI({
      req(input$filter_var3, input$filter_var3 != "")
      vals <- unique(data()[[input$filter_var3]])
      selectInput(session$ns("filter_val3_sel"), "Valores", choices = vals, multiple = TRUE)
    })
    
    # --- Filtros dinámicos según variables de agrupación ---
    output$group_var_ui <- renderUI({
      req(input$by)
      ns <- session$ns
      
      lapply(input$by, function(v) {
        fluidRow(
          column(
            12,
            selectInput(
              ns(paste0("group_filter_", v)),
              label = paste("Filtrar valores de", v),
              choices = unique(data()[[v]]),
              multiple = TRUE
            )
          )
        )
      })
    })
    
    # --- Cálculos de tabla ---
    res <- eventReactive(input$run, {
      req(design())
      df <- design()$variables
      dsg <- design()
      var <- input$var
      if (!nzchar(var)) return(NULL)
      
      # aplicar filtros estáticos
      if (!is.null(input$filter_var1) && input$filter_var1 != "" && length(input$filter_val1_sel) > 0) {
        dsg <- dsg %>% filter(.data[[input$filter_var1]] %in% input$filter_val1_sel)
      }
      if (!is.null(input$filter_var2) && input$filter_var2 != "" && length(input$filter_val2_sel) > 0) {
        dsg <- dsg %>% filter(.data[[input$filter_var2]] %in% input$filter_val2_sel)
      }
      if (!is.null(input$filter_var3) && input$filter_var3 != "" && length(input$filter_val3_sel) > 0) {
        dsg <- dsg %>% filter(.data[[input$filter_var3]] %in% input$filter_val3_sel)
      }
      
      # determinar tipo
      t <- if (input$type == 'auto') {
        if (is.numeric(df[[var]])) 'num' else 'cat'
      } else input$type
      
      by_vars <- head(input$by, 4)
      
      if (t == 'num') {
        result_table_numeric(dsg, varname = var, by = by_vars)
      } else {
        result_table_proportion(dsg, varname = var, by = by_vars)
      }
    })
    
    # --- Tabla ---
    output$table <- DT::renderDT({
      req(res())
      DT::datatable(
        head(res(), 200),
        rownames = FALSE,
        filter = "top",
        extensions = c("Buttons", "ColReorder", "FixedHeader"),
        options = list(
          dom = "Bfrtip",
          buttons = c("copy", "csv", "excel"),
          colReorder = TRUE,
          fixedHeader = TRUE,
          pageLength = 20,
          autoWidth = TRUE,
          scrollX = TRUE
        ),
        class = "display nowrap stripe hover"
      )
    })
    
    # --- Gráfico dinámico (modo clásico con ICs) ---
    plot_data <- eventReactive(input$run_plot, {
      req(res())
      df <- res()
      # aplicar filtros dinámicos de las variables de agrupación
      if (!is.null(input$by) && length(input$by) > 0) {
        for (v in input$by) {
          filtro <- input[[paste0("group_filter_", v)]]
          if (!is.null(filtro) && length(filtro) > 0) {
            df <- df %>% filter(.data[[v]] %in% filtro)
          }
        }
      }
      df
    })
    
    output$plot <- plotly::renderPlotly({
      df <- plot_data()
      req(df)
      
      # elegir métrica
      if (input$plot_type == "Media" && "media" %in% names(df)) {
        yvar <- "media"
      } else if (input$plot_type == "Total" && "total" %in% names(df)) {
        yvar <- "total"
      } else if (input$plot_type == "Proporción" && "prop" %in% names(df)) {
        yvar <- "prop"
      } else return(NULL)
      
      
      li <- paste0(yvar, "_low")
      ls <- paste0(yvar, "_upp")
      
      if (!(li %in% names(df) && ls %in% names(df))) return(NULL)
      
      # --- Detectar qué variables tienen múltiples categorías seleccionadas ---
      
      by_vars <- input$by
      
      if (is.null(by_vars) || length(by_vars) == 0) {
        # --- Caso 1 ---
        p <- ggplot(df, aes(x = .data[[input$var]], y = .data[[yvar]])) +
          geom_col(fill = "steelblue") +
          geom_errorbar(aes(ymin = .data[[li]], ymax = .data[[ls]]), width = 0.2) +
          labs(
            x = input$var,
            y = input$plot_type,
            title = paste(input$plot_type, "de", input$var)
          ) +
          theme_minimal()
        
      } else if (length(by_vars) == 1) {
        # --- Caso 2 ---
        p <- ggplot(df, aes(x = .data[[input$var]], y = .data[[yvar]], fill = .data[[by_vars[1]]])) +
          geom_col(position = "dodge") +
          geom_errorbar(
            aes(
              ymin = .data[[li]],
              ymax = .data[[ls]]
            ),
            width = 0.2,
            position = position_dodge(width = 0.9)
          ) +
          labs(
            x = input$var,
            y = input$plot_type,
            title = paste(input$plot_type, "de", input$var, "por", by_vars[1])
          ) +
          theme_minimal()
        
      } else if (length(by_vars) == 2) {
        # --- Caso 3 ---
        p <- ggplot(df, aes(x = .data[[input$var]], y = .data[[yvar]], fill = .data[[by_vars[1]]])) +
          geom_col(position = "dodge") +
          geom_errorbar(
            aes(
              ymin = .data[[li]],
              ymax = .data[[ls]]
            ),
            width = 0.2,
            position = position_dodge(width = 0.9)
          ) +
          facet_grid(rows = vars(.data[[by_vars[2]]])) +
          labs(
            x = input$var,
            y = input$plot_type,
            title = paste(
              input$plot_type,
              "de",
              input$var,
              "por",
              paste(by_vars, collapse = ", ")
            )
          ) +
          theme_minimal()
        
      } else if (length(by_vars) == 3) {
        # --- Caso 4 ---
        p <- ggplot(df, aes(x = .data[[input$var]], y = .data[[yvar]], fill = .data[[by_vars[1]]])) +
          geom_col(position = "dodge") +
          geom_errorbar(
            aes(
              ymin = .data[[li]],
              ymax = .data[[ls]]
            ),
            width = 0.2,
            position = position_dodge(width = 0.9)
          ) +
          facet_grid(rows = vars(.data[[by_vars[2]]]), cols = vars(.data[[by_vars[3]]])) +
          labs(
            x = input$var,
            y = input$plot_type,
            title = paste(
              input$plot_type,
              "de",
              input$var,
              "por",
              paste(by_vars, collapse = ", ")
            )
          ) +
          theme_minimal()
        
      } else if (length(by_vars) == 4) {
        # --- Caso 5 (propuesta) ---
        p <- ggplot(df, aes(x = .data[[input$var]], y = .data[[yvar]], fill = .data[[by_vars[2]]])) +
          geom_col(position = "dodge") +
          geom_errorbar(
            aes(
              ymin = .data[[li]],
              ymax = .data[[ls]]
            ),
            width = 0.2,
            position = position_dodge(width = 0.9)
          ) +
          facet_grid(rows = vars(.data[[by_vars[3]]]), cols = vars(.data[[by_vars[4]]])) +
          labs(
            x = input$var,
            y = input$plot_type,
            title = paste(
              input$plot_type,
              "de",
              input$var,
              "por",
              paste(by_vars, collapse = ", ")
            )
          ) +
          theme_minimal()
      }
      # Formato del eje Y según estadístico
      if (input$plot_type == "Total") {
        p <- p + scale_y_continuous(labels = scales::comma)
      } else if (input$plot_type == "Proporción") {
        p <- p + scale_y_continuous(labels = scales::percent_format(accuracy = 1))
      } else if (input$plot_type == "Media") {
        p <- p + scale_y_continuous(labels = scales::comma)
      }
      
      # --- aplicar paleta seleccionada ---
      if (input$palette == "Viridis") {
        p <- p + scale_fill_viridis_d()
      } else {
        p <- p + scale_fill_brewer(palette = input$palette)
      }
      
      
      plotly::ggplotly(p)
    })
  

    
    # --- Manejo de esquisse ---
    show_esq <- reactiveVal(FALSE)
    
    observeEvent(input$btn_show_esq, {
      # Asegurarse de que 'plot_data' tiene datos antes de lanzar esquisse
      req(plot_data())
      
      # Cambiar a la pestaña de "Gráfica avanzada"
      updateTabsetPanel(session, "main_tabs", selected = "Gráfica avanzada")
      
      # Renderizar la interfaz de usuario de esquisse
      output$esq_ui <- renderUI({
        esquisse::esquisse_ui(id = ns("esq"))
      })
      
      # Iniciar el servidor de esquisse, pasándole los datos reactivos.
      # Esta llamada debe estar DENTRO del observeEvent
      esquisse::esquisse_server(
        id = "esq",
        data_rv = plot_data
      )
    })
    
  })
    
 }
