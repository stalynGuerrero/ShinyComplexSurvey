library(shiny)
library(ShinyComplexSurvey)

shinyApp(
  ui = ShinyComplexSurvey:::app_ui(),
  server = ShinyComplexSurvey:::app_server
)
