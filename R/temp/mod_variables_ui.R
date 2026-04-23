mod_variables_ui <- function(id) {
  ns <- shiny::NS(id)
  
  shiny::fluidPage(
    
    shiny::h3("Construcción de variables"),
    shiny::hr(),
    
    shiny::tabsetPanel(
      
      # ==================================================
      # MODO AVANZADO
      # ==================================================
      shiny::tabPanel(
        "Modo avanzado (R)",
        
        shiny::fluidRow(
          shiny::column(
            6,
            shiny::wellPanel(
              shiny::h4("Código R"),
              
              shiny::textAreaInput(
                ns("code"),
                NULL,
                placeholder =
                  "Ejemplo:
data <- data |>
  dplyr::mutate(
    ingreso_pc = ingreso / miembros,
    pobre = ingreso_pc < 300
  )",
                rows = 10
              ),
              
              shiny::actionButton(
                ns("run_code"),
                "Ejecutar código",
                class = "btn-primary"
              )
            )
          ),
          
          shiny::column(
            6,
            shiny::wellPanel(
              shiny::h4("Resultado"),
              shiny::verbatimTextOutput(ns("log_code"))
            )
          )
        )
      ),
      
      # ==================================================
      # MODO ASISTIDO
      # ==================================================
      shiny::tabPanel(
        "Modo asistido",
        
        shiny::fluidRow(
          shiny::column(
            4,
            shiny::wellPanel(
              shiny::h4("Definición"),
              
              shiny::textInput(
                ns("new_var"),
                "Nombre de la nueva variable"
              ),
              
              shiny::selectInput(
                ns("base_var"),
                "Variable base",
                choices = NULL
              ),
              
              shiny::selectInput(
                ns("var_type"),
                "Tipo de variable",
                choices = c(
                  "Numérica"   = "numeric",
                  "Categórica" = "categorical"
                )
              ),
              
              # ==========================
              # NUMÉRICA
              # ==========================
              shiny::conditionalPanel(
                condition = sprintf(
                  "input['%s'] == 'numeric'", ns("var_type")
                ),
                
                shiny::selectInput(
                  ns("operation"),
                  "Operación",
                  choices = c(
                    "Dividir"      = "div",
                    "Sumar"        = "sum",
                    "Restar"       = "sub",
                    "Multiplicar"  = "mul",
                    "Indicador (<)" = "lt"
                  )
                ),
                
                shiny::numericInput(
                  ns("value"),
                  "Valor",
                  value = 1
                )
              ),
              
              # ==========================
              # CATEGÓRICA
              # ==========================
              shiny::conditionalPanel(
                condition = sprintf(
                  "input['%s'] == 'categorical'", ns("var_type")
                ),
                
                shiny::numericInput(
                  ns("n_cat"),
                  "Número de categorías",
                  value = 2,
                  min = 1,
                  max = 10
                ),
                
                shiny::uiOutput(ns("categorias_ui"))
              ),
              
              shiny::actionButton(
                ns("apply_calc"),
                "Crear variable",
                class = "btn-primary"
              )
            )
          ),
          
          shiny::column(
            8,
            shiny::wellPanel(
              shiny::h4("Estado"),
              shiny::verbatimTextOutput(ns("log_calc"))
            )
          )
        )
      )
    )
  )
}
