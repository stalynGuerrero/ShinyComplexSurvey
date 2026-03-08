#' Generar datos simulados de encuesta compleja
#'
#' @param seed Semilla aleatoria
#' @return tibble con datos simulados
#' @export
generate_example_data <- function(n = 3000, seed = 123){
  
  set.seed(seed)
  
  tibble::tibble(
    
    # estructura de diseño
    strata  = sample(paste0("S",1:5), n, TRUE),
    upm     = sample(paste0("UPM",1:200), n, TRUE),
    weight  = runif(n, 200, 1500),
    
    # dominios
    region  = sample(c("Norte","Centro","Sur"), n, TRUE),
    sexo    = sample(c("Hombre","Mujer"), n, TRUE),
    area    = sample(c("Urbano","Rural"), n, TRUE),
    
    # variables continuas
    ingreso      = rgamma(n, shape = 4, scale = 500),
    gasto        = rgamma(n, shape = 3, scale = 400),
    edad         = round(rnorm(n, 40, 15)),
    
    # variable binaria
    pobre        = rbinom(n,1,0.25),
    
    # categórica
    educacion = factor(sample(
      c("Primaria","Secundaria","Universitaria"),
      n,
      TRUE,
      prob = c(0.4,0.4,0.2)
    )),
    
    # categórica adicional
    empleo = factor(sample(
      c("Formal","Informal","Desempleado"),
      n,
      TRUE
    )),
    
    # variable con NA
    ingreso2 = ifelse(runif(n) < 0.1, NA, ingreso*runif(n,0.8,1.2))
    
  )
}
