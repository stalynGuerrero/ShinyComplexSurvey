#' Ejecutar la app Shiny
#' @export
run_shiny <- function() {
  
  if (shiny::isRunning()) {
    stop("A Shiny app is already running in this session.")
  }
  
  app_dir <- system.file("shiny", package = "ShinyComplexSurvey")
  
  if (app_dir == "") {
    stop("Could not find Shiny app")
  }
  
  shiny::runApp(app_dir, launch.browser = TRUE)
  
}