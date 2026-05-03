#' Run ShinyComplexSurvey application
#'
#' Launches the Shiny app bundled within the package.
#'
#' @return Launches a Shiny application.
#' @export
ComplexSurvey_app <- function() {
  
  if (shiny::isRunning()) {
    stop("A Shiny app is already running in this session.")
  }
  
  app_dir <- system.file("app", package = "ShinyComplexSurvey")
  
  if (app_dir == "") {
    stop("Could not find Shiny app")
  }
  
  shiny::runApp(app_dir, launch.browser = TRUE)
}