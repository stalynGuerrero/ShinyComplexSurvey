# R/mod_map.R

#============================#
#        UI del módulo       #
#============================#
mod_map_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    h3("Mapa Interactivo"),
    leaflet::leafletOutput(ns("mapa"), height = "600px"),
    br(),
    actionButton(ns("guardar"), "Guardar Cambios", class = "btn-primary")
  )
}

#============================#
#     Server del módulo      #
#============================#
mod_map_server <- function(id, datos_poligonos, registros) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # Renderizar el mapa base
    output$mapa <- leaflet::renderLeaflet({
      leaflet::leaflet(datos_poligonos) %>%
        addTiles() %>%
        addPolygons(
          layerId = ~id,
          color = "black",
          weight = 1,
          fillColor = "lightblue",
          fillOpacity = 0.5,
          highlightOptions = highlightOptions(color = "red", weight = 2, bringToFront = TRUE)
        )
    })
    
    # Registrar selección de polígonos
    observeEvent(input$mapa_shape_click, {
      click <- input$mapa_shape_click
      if (!is.null(click)) {
        registros$seleccion <- rbind(
          registros$seleccion,
          data.frame(
            id_poligono = click$id,
            timestamp = Sys.time(),
            usuario = session$user
          )
        )
      }
    })
    
    # Guardar registros seleccionados
    observeEvent(input$guardar, {
      saveRDS(registros$seleccion, "data/registros_mapa.rds")
      showNotification("Cambios guardados correctamente", type = "message")
    })
    
  })
}
