#' Shiny server for ShinyComplexSurvey
#'
#' @param input Shiny input
#' @param output Shiny output
#' @param session Shiny session

app_server <- function(input, output, session) {

  # =========================
  # Idioma reactivo global
  # =========================
  lang <- shiny::reactiveVal("es")

  shiny::observeEvent(input$lang, {
    lang(input$lang)
  }, ignoreInit = TRUE)

  # =========================
  # Diccionario reactivo
  # =========================
  dict <- shiny::reactive({
    i18n_load(lang())
  })

  # =========================
  # Tabs traducidos
  # =========================
  output$tab_datos      <- shiny::renderText({ i18n_t(dict(), "app.tabs.datos") })
  output$tab_diseno     <- shiny::renderText({ i18n_t(dict(), "app.tabs.diseno") })
  output$tab_estimacion <- shiny::renderText({ i18n_t(dict(), "app.tabs.estimacion") })

  # =========================
  # Módulo: Datos
  # =========================
  datos_res <- mod_datos_server("datos", dict)

  # =========================
  # Módulo: Diseño muestral
  # =========================
  diseno_res <- mod_diseno_server("diseno", datos_res$data)

  # =========================
  # Módulo: Estimación
  # =========================
  mod_estimacion_server("estimacion", diseno_res$design)
}
