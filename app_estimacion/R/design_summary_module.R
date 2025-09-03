# design_summary_module.R

design_summary_ui <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
      box(
        width = 12,
        title = "Resumen del Diseño de Muestreo",
        status = "primary",
        solidHeader = TRUE,
        br(), # Añade un salto de línea para separar
        h4("Distribución de los Factores de Expansión"),
        plotOutput(ns("weight_histogram"))
      )
    )
  )
}


# design_summary_module.R

design_summary_server <- function(id, design_data) {
  moduleServer(id, function(input, output, session) {
    
       # 2. Renderiza el histograma de los factores de expansión
    output$weight_histogram <- renderPlot({
      req(design_data())
      
      df <- weights(design_data())
      if (!is.null(df)) {
        df <- data.frame(weights = df)  # Convierte a data frame
        df %>%
          ggplot(aes(x = weights)) +
          geom_histogram(bins = 30, fill = "#007BFF", color = "white") +
          labs(
            title = "Histograma de Factores de Expansión",
            x = "Factor de Expansión",
            y = "Frecuencia"
          ) +
          theme_minimal(base_size = 14) +
          theme(
            plot.title = element_text(hjust = 0.5, face = "bold"),
            panel.grid.major = element_line(color = "grey90"),
            panel.grid.minor = element_line(color = "grey95")
          )
      } else {
        # Muestra un mensaje si no hay factores de expansión
        ggplot() +
          annotate(
            "text",
            x = 0.5,
            y = 0.5,
            label = "No se ha definido un factor de expansión.",
            size = 6,
            color = "grey50"
          ) +
          theme_void()
      }
    })
  })
}