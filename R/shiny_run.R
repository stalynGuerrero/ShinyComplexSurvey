#' Ejecutar la app Shiny
#' @export
run_shiny <- function() {
  shiny::runApp(
    system.file("shiny", package = "ShinyComplexSurvey"),
    launch.browser = TRUE
  )
}
