shiny_server <- function(input, output, session) {
  
  # =========================
  # Datos
  # =========================
  datos <- mod_datos_server("datos")
  
  # =========================
  # Variables
  # =========================
  vars <- mod_variables_server(
    "vars",
    data = datos$data
  )
  
  # =========================
  # Diseño muestral
  # =========================
  diseno <- mod_diseno_server(
    "diseno",
    data = vars$data
  )
  
  # =========================
  # Estimación
  # =========================
  estimacion <- mod_estimacion_server(
    "estimacion",
    design = diseno$design
  )
  
  # =========================
  # Resultados
  # =========================
  mod_resultados_server(
    "resultados",
    results = estimacion$results
  )
  
  # =========================
  # Diagnóstico
  # =========================
  mod_diagnostico_server(
    "diag",
    datos = datos$data,
    diseno = diseno$design,
    estimacion = estimacion$results
  )
}
