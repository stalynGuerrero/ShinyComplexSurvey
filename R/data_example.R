#' Generar datos simulados de encuesta compleja
#'
#' @param seed Semilla aleatoria
#' @return tibble con datos simulados
#' @export
generate_example_data <- function(seed = 123) {
  
  set.seed(seed)
  
  n_strata   <- 3
  psu_per_s  <- 4
  obs_per_ps <- 20
  
  frame <- expand.grid(
    estrato = seq_len(n_strata),
    upm     = seq_len(psu_per_s),
    obs     = seq_len(obs_per_ps)
  )
  
  frame %>%
    dplyr::mutate(
      w = runif(dplyr::n(), 0.5, 2),
      miembros = sample(1:6, dplyr::n(), replace = TRUE),
      ingreso = round(
        rlnorm(
          dplyr::n(),
          meanlog = log(400 + estrato * 100),
          sdlog = 0.4
        ),
        0
      ),
      sexo   = sample(c("Hombre", "Mujer"), dplyr::n(), replace = TRUE),
      region = sample(c("Norte", "Centro", "Sur"), dplyr::n(), replace = TRUE),
      etnia  = sample(c("Indigena", "Afro", "Ninguna"), dplyr::n(), replace = TRUE),
      dam    = paste0("DAM_", sample(1:5, dplyr::n(), replace = TRUE))
    ) %>%
    dplyr::select(
      estrato, upm, w,
      sexo, region, etnia, dam,
      ingreso, miembros
    ) %>%
    tibble::as_tibble()
}
