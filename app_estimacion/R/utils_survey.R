library(srvyr)
library(dplyr)

# ------------------------------------------------------------
# Construcción del diseño de encuesta con srvyr
# ------------------------------------------------------------
make_survey_design <- function(df, psu = NULL, strata = NULL, weight = NULL,
                               use_jack_if_nopsu = TRUE, replicates = 500,
                               rep_type = "JK1") {
  # Caso PSU explícita
  if (psu != "Sin UPM") {
    design <- df %>%
      srvyr::as_survey_design(
        ids     = !!sym(psu),
        weights = weight,
        nest    = TRUE
      )
    return(design)
  }
  
  # Caso PSU = NULL -> usar replicación
  design <- df %>%
    srvyr::as_survey_design(
      ids     = 1,
      weights = weight,
      nest    = TRUE
    )
  
  if (use_jack_if_nopsu) {
    design <- tryCatch(
      srvyr::as_survey_rep(design, type = rep_type,
                           replicates = replicates),
      error = function(e)
        design
    )
  }
  return(design)
}
# ------------------------------------------------------------
# Helpers tidyverse con srvyr
# ------------------------------------------------------------

# 1. Variables numéricas: medias y totales
result_table_numeric <- function(dsg, varname, by = NULL, conf_level = 0.95) {
  alpha <- 1 - conf_level
  zval <- qnorm(1 - alpha / 2)
  
  srv <- dsg
  
  srv_grouped <- if (!is.null(by) && length(by) > 0) {
    srv %>% group_by(across(all_of(by)))
  } else {
    srv
  }
  
  srv_grouped %>%
    summarise(
      media = survey_mean(.data[[varname]], vartype = c("se", "ci"), level = conf_level, na.rm = TRUE),
       .groups = "drop"
    ) %>%
    mutate(
      !!sym(varname) := varname,
      cv_media = 100 * media_se / media,
      me_media = 100 * (zval * media_se / media),
    ) %>%
    relocate(!!sym(varname), .before = 1) %>% 
    format_results_for_display()
}

# 2. Proporciones (variables categóricas)
result_table_proportion <- function(dsg, varname, by = NULL, conf_level = 0.95) {
  alpha <- 1 - conf_level
  zval <- qnorm(1 - alpha / 2)
  
  srv <- dsg
  
  srv_grouped <- if (!is.null(by) && length(by) > 0) {
    srv %>% group_by(across(all_of(by)))
  } else {
    srv
  }
  
  srv_grouped %>%
    group_by(.data[[varname]], .add = TRUE) %>%  # agrupar también por niveles de la variable categórica
    summarise(
      prop = survey_mean(vartype = c("se", "ci"), level = conf_level, na.rm = TRUE),
      total = survey_total(vartype = c("se", "ci"), level = conf_level, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    mutate(
      cv_prop = 100 * prop_se / prop,
      me_prop = 100 * (zval * prop_se / prop),
      cv_total = 100 * total_se / total,
      me_total = 100 * (zval * total_se / total)
    ) %>%
    format_results_for_display()
}

# 3. Cuantiles / mediana
result_table_quantiles <- function(design, varname,
                                   probs = c(0.25, 0.5, 0.75),
                                   conf_level = 0.95) {
  design %>%
    summarise(
      quant = survey_quantile(!!sym(varname), quantiles = probs,
                              vartype = "ci", level = conf_level, na.rm = TRUE)
    ) %>%
    tidyr::unnest_wider(quant)
}

## ------------------------------------------------------------
# Formato final de tablas con asteriscos en CV
# ------------------------------------------------------------
format_results_for_display <- function(df) {
  if (is.null(df) || nrow(df) == 0) return(df)
  
  df %>%
    mutate(across(where(is.numeric), ~ round(.x, 4))) %>%
    mutate(across(matches("^cv_"), ~ case_when(
      is.na(.x) ~ NA_character_,
      .x < 3 ~ paste0(formatC(round(.x, 2), digits = 2, format = "f"), "%"),
      .x >= 3 & .x < 5 ~ paste0(formatC(round(.x, 2), digits = 2, format = "f"), "%*"),
      .x >= 5 & .x < 15 ~ paste0(formatC(round(.x, 2), digits = 2, format = "f"), "%**"),
      .x >= 15 ~ paste0(formatC(round(.x, 2), digits = 2, format = "f"), "%***"),
      TRUE ~ NA_character_
    ))) %>%
    mutate(across(matches("^me_"), ~ ifelse(
      is.finite(.x),
      paste0(formatC(round(.x, 2), digits = 2, format = "f"), "%"),
      NA
    )))
}

