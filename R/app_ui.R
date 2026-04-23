#' Shiny UI for ShinyComplexSurvey
#'
#' @return A Shiny UI object.
app_ui <- function() {

  shiny::withMathJax(

    shiny::navbarPage(
      title  = "ShinyComplexSurvey",
      id     = "navbar",
      fluid  = TRUE,
      theme  = NULL,

      header = shiny::tags$head(
        shiny::tags$link(rel = "stylesheet", type = "text/css", href = "www/custom.css"),
        shiny::tags$style(shiny::HTML("
          .navbar-custom-menu {
            float: right !important;
            margin-right: 15px;
            display: flex;
            align-items: center;
            height: 50px;
          }
          .navbar-custom-menu .form-group {
            margin-bottom: 0 !important;
          }
        "))
      ),

      # ============================================================
      # Pestaña 1: Datos
      # ============================================================
      shiny::tabPanel(
        title = shiny::textOutput("tab_datos"),
        mod_datos_ui("datos")
      ),

      # ============================================================
      # Pestaña 2: Diseño muestral
      # ============================================================
      shiny::tabPanel(
        title = shiny::textOutput("tab_diseno"),
        mod_diseno_ui("diseno")
      ),

      # ============================================================
      # Pestaña 3: Estimación
      # ============================================================
      shiny::tabPanel(
        title = shiny::textOutput("tab_estimacion"),
        mod_estimacion_ui("estimacion")
      ),

      # ============================================================
      # Selector de idioma alineado a la derecha
      # ============================================================
      shiny::tags$script(shiny::HTML("
        $(document).ready(function() {
          $('.navbar-nav').after($('#lang-container'));
        });
      ")),

      footer = shiny::tags$div(
        id    = "lang-container",
        class = "navbar-custom-menu",
        shiny::tags$div(
          style = "display:flex; align-items:center; gap:8px;",
          shiny::tags$span(class = "fa fa-globe", style = "color:white;"),
          shiny::selectizeInput(
            inputId = "lang",
            label   = NULL,
            choices = c("ES" = "es", "EN" = "en"),
            selected = "es",
            width   = "80px",
            options = list(maxItems = 1, searchField = FALSE)
          )
        )
      )
    )

  )
}
