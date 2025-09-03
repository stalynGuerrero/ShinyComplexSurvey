library(shiny)
library(dplyr)
library(DT)
library(rlang)

# ==============================
# UI del módulo
# ==============================
mod_mutate_ui <- function(id){
  ns <- NS(id)
  tagList(
    radioButtons(ns("modo"), "Modo de uso:",
                 choices = c("Principiante" = "guiado", "Experto" = "experto")),
    conditionalPanel(
      condition = sprintf("input['%s'] == 'guiado'", ns("modo")),
      textInput(ns("new_var"), "Nombre de la nueva variable", ""),
      numericInput(ns("n_cond"), "Número de condiciones (para ifelse/case_when)", 
                   value = 1, min = 1, max = 5),
      uiOutput(ns("condiciones_ui")),
      textInput(ns("default"), "Valor por defecto (TRUE ~ )", "NA"),
      hr(),
      h4("Vista previa del código"),
      verbatimTextOutput(ns("formula_guiada"))
    ),
    conditionalPanel(
      condition = sprintf("input['%s'] == 'experto'", ns("modo")),
      textAreaInput(ns('code'), 'Expresión dplyr (p.ej. nueva = ingreso / miembros)', rows = 5)
    ),
    actionButton(ns('apply'),'Aplicar'),
    hr(),
    DTOutput(ns('preview'))
  )
}

# ==============================
# SERVER del módulo
# ==============================
mod_mutate_server <- function(id, data){
  moduleServer(id, function(input, output, session){
    dfr <- reactiveVal(NULL)
    observeEvent(data(), { dfr(data()) })
    
    # --- UI dinámico para condiciones ---
    output$condiciones_ui <- renderUI({
      n <- input$n_cond
      if (is.null(n)) return(NULL)
      ns <- session$ns
      tagList(
        lapply(1:n, function(i) {
          fluidRow(
            column(3, selectInput(ns(paste0("var1_", i)), "Variable 1", choices = names(data()))),
            column(2, selectInput(ns(paste0("op_", i)), "Operador",
                                  choices = c(">", "<", "==", "!=", ">=", "<=", 
                                              "&", "|", "%in%"))),
            column(3, textInput(ns(paste0("var2_", i)), "Valor o Variable 2", "")),
            column(4, textInput(ns(paste0("res_", i)), "Resultado si cumple", ""))
          )
        })
      )
    })
    
    # --- Construcción de expresión guiada ---
    expr_txt <- reactive({
      req(input$modo == "guiado")
      n <- input$n_cond
      if (is.null(n)) return(NULL)
      
      condiciones <- lapply(1:n, function(i) {
        v1 <- input[[paste0("var1_", i)]]
        op <- input[[paste0("op_", i)]]
        v2 <- input[[paste0("var2_", i)]]
        res <- input[[paste0("res_", i)]]
        
        if (is.null(v1) || v1 == "" || op == "" || v2 == "" || res == "") return(NULL)
        
        # caso especial: %in% -> necesita c()
        if (op == "%in%") {
          paste0(".data[['", v1, "']] %in% c(", v2, ") ~ ", res)
        } else {
          paste0(".data[['", v1, "']] ", op, " ", v2, " ~ ", res)
        }
      })
      
      condiciones <- paste(na.omit(unlist(condiciones)), collapse = ",\n  ")
      paste0(input$new_var, " = case_when(\n  ", condiciones,
             ",\n  TRUE ~ ", input$default, "\n)")
    })
    
    output$formula_guiada <- renderText({
      expr_txt()
    })
    
    # --- Aplicar mutación ---
    observeEvent(input$apply, {
      req(dfr())
      df <- dfr()
      
      if (input$modo == "experto") {
        code <- input$code
        if(code=='') return()
        expr <- paste0('df <- dplyr::mutate(df, ', code, ')')
      } else {
        req(expr_txt())
        expr <- paste0('df <- dplyr::mutate(df, ', expr_txt(), ')')
      }
      
      tryCatch({
        eval(parse(text = expr))
        dfr(df)
      }, error = function(e){
        showModal(modalDialog('Error en mutate', e$message))
      })
    })
    
    # --- Vista previa ---
    output$preview <- renderDT({
      req(dfr()); datatable(head(dfr(),200))
    })
    
    return(reactive(dfr()))
  })
}
