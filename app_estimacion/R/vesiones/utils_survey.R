# utils_survey.R

make_survey_design <- function(df, psu = NULL, strata = NULL, weight = NULL, 
                               use_jack_if_nopsu = TRUE, replicates = 500){
  ids <- if(!is.null(psu)) as.formula(paste0('~', psu)) else ~1
  strata_f <- if(!is.null(strata)) as.formula(paste0('~', strata)) else NULL
  weights <- if(!is.null(weight)) as.formula(paste0('~', weight)) else NULL
  
  design <- tryCatch(
    survey::svydesign(ids = ids, strata = strata_f, weights = weights, data = df),
    error = function(e) survey::svydesign(ids = ~1, data = df)
  )
  
  # Si no hay PSU explícita, aplicar replicación
  if(deparse(ids) == "~1" && use_jack_if_nopsu){
    repd <- tryCatch(
      survey::as.svrepdesign(design, type = "bootstrap", replicates = replicates),
      error = function(e) design
    )
    return(repd)
  }
  return(design)
}


# ------------------------------------------------------------
# Helpers para tablas de resultados
# ------------------------------------------------------------

# 1. Variables numéricas: medias, errores, CV, MOE, IC
result_table_numeric <- function(design,
                                 varname,
                                 by = NULL,
                                 conf_level = 0.95) {
  alpha <- 1 - conf_level
  zval <- qnorm(1 - alpha / 2)
  fml <- as.formula(paste0("~", varname))
  
  if (!is.null(by)) {
    byf <- as.formula(paste0("~", by))
    est_mean  <- survey::svyby(
      fml,
      byf,
      design,
      survey::svymean,
      vartype = c("se", "ci"),
      level = conf_level,
      na.rm = TRUE
    )
    est_total <- survey::svyby(
      fml,
      byf,
      design,
      survey::svytotal,
      vartype = c("se", "ci"),
      level = conf_level,
      na.rm = TRUE
    )
    out <- dplyr::left_join(as.data.frame(est_mean), as.data.frame(est_total), by = by)
  } else {
    est_mean  <- survey::svymean(
      fml,
      design,
      vartype = c("se", "ci"),
      level = conf_level,
      na.rm = TRUE
    )
    est_total <- survey::svytotal(
      fml,
      design,
      vartype = c("se", "ci"),
      level = conf_level,
      na.rm = TRUE
    )
    out <- data.frame(
      media      = coef(est_mean),
      se_media   = SE(est_mean),
      lci_media  = confint(est_mean)[, 1],
      uci_media  = confint(est_mean)[, 2],
      total      = coef(est_total),
      se_total   = SE(est_total),
      lci_total  = confint(est_total)[, 1],
      uci_total  = confint(est_total)[, 2]
    )
  }
  
  # Calidad
  out$cv_media <- 100 * out$se_media / out$media
  out$me_media <- 100 * (zval * out$se_media / out$media)
  out$cv_total <- 100 * out$se_total / out$total
  out$me_total <- 100 * (zval * out$se_total / out$total)
  
  format_table(out)
} 
  
# 2. Proporciones de variables categóricas
result_table_proportion <- function(design, varname, conf_level = 0.95){
  alpha <- 1 - conf_level
  zval <- qnorm(1 - alpha/2)
  fml <- as.formula(paste0("~", varname))
  
  est_prop  <- survey::svymean(fml, design, vartype = c("se","ci"), level = conf_level, na.rm=TRUE)
  est_total <- survey::svytotal(fml, design, vartype = c("se","ci"), level = conf_level, na.rm=TRUE)
  
  out <- data.frame(
    nivel     = names(coef(est_prop)),
    prop      = coef(est_prop),
    se_prop   = SE(est_prop),
    lci_prop  = confint(est_prop)[,1],
    uci_prop  = confint(est_prop)[,2],
    total     = coef(est_total),
    se_total  = SE(est_total),
    lci_total = confint(est_total)[,1],
    uci_total = confint(est_total)[,2]
  )
  
  # Calidad
  out$cv_prop <- 100 * out$se_prop / out$prop
  out$me_prop <- 100 * (zval * out$se_prop / out$prop)
  out$cv_total <- 100 * out$se_total / out$total
  out$me_total <- 100 * (zval * out$se_total / out$total)
  
  format_table(out)
}

# 3. Cuantiles / mediana
result_table_quantiles <- function(design, varname, probs = c(0.25, 0.5, 0.75), conf_level = 0.95){
  stopifnot(varname %in% names(design$variables))
  
  est <- survey::svyquantile(~get(varname), design, quantiles = probs, ci = TRUE, level = conf_level, na.rm = TRUE)
  
  qvals <- est$quantiles
  lci <- est$ci[,1]
  uci <- est$ci[,2]
  
  out <- data.frame(
    quantile = probs,
    estimate = qvals,
    lci = lci,
    uci = uci
  )
  rownames(out) <- NULL
  return(out)
}

# Helper local para formatear la tabla final (números a 4 decimales, CV/ME a 2 + %)
.format_results_for_display <- function(df) {
  if (is.null(df) || nrow(df) == 0) return(df)
  
  df_out <- df
  
  # Redondear numéricas a 4 decimales
  num_cols <- names(df_out)[vapply(df_out, is.numeric, logical(1))]
  df_out[num_cols] <- lapply(df_out[num_cols], function(x) round(x, 4))
  
  # Columnas de CV y ME: detectamos por prefijo cv_ y me_
  cv_cols <- grep("^cv", names(df_out), value = TRUE)
  me_cols <- grep("^me", names(df_out), value = TRUE)
  
  # Formatear CV y ME a 2 decimales y añadir sufijo %
  df_out[cv_cols] <- lapply(df_out[cv_cols], function(x) {
    # Evitar dividir por cero o NA: si NA o Inf, mantener NA
    x2 <- ifelse(is.finite(x), paste0(formatC(round(x, 2), digits = 2, format = "f"), "%"), NA)
    return(x2)
  })
  df_out[me_cols] <- lapply(df_out[me_cols], function(x) {
    x2 <- ifelse(is.finite(x), paste0(formatC(round(x, 2), digits = 2, format = "f"), "%"), NA)
    return(x2)
  })
  
  # Asegurar que columnas no numéricas permanezcan como tal
  return(df_out)
}



