app_ui <- function() {
  
  shiny::withMathJax(
    
    shiny::navbarPage(
      
      title = "ShinyComplexSurvey",
      fluid = TRUE,
      
      header = shiny::tags$head(
        shiny::tags$link(
          rel = "stylesheet",
          type = "text/css",
          href = "custom.css"
        )
      ),
      
      shiny::tabPanel(
        "Datos",
        mod_datos_ui("datos")
      ),
      
      shiny::tabPanel(
        "Variables",
        mod_variables_ui("vars")
      ),
      
      shiny::tabPanel(
        "Diseno",
        mod_diseno_ui("diseno")
      ),
      
      shiny::tabPanel(
        "Estimacion",
        mod_estimacion_ui("estimacion")
      ),
    
      
      shiny::tabPanel(
        "Resultados",
        mod_resultados_ui("resultados")
      ),
      
      shiny::tabPanel(
        "Exportar",
        mod_export_ui("export")
      )
      
    )
    
  )
}