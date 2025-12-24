#' Estimate basic survey statistics
#'
#' @param design A tbl_svy survey design object.
#' @param variable Character. Variable name to estimate.
#' @param estimator Character. One of "mean", "total", "prop".
#' @param conf_level Numeric. Confidence level between 0 and 1.
#' @param na_rm Logical. Whether to remove NA values.
#'
#' @return A tibble with estimate, standard error and confidence interval.
#' @export
estimate_survey <- function(
    design,
    variable,
    estimator = c("mean", "total", "prop"),
    conf_level = 0.95,
    na_rm = TRUE
) {
  
  # -------------------------
  # Validaciones
  # -------------------------
  
  if (!inherits(design, "tbl_svy")) {
    rlang::abort("`design` must be a srvyr tbl_svy object.")
  }
  
  estimator <- match.arg(estimator)
  
  if (!is.character(variable) || length(variable) != 1) {
    rlang::abort("`variable` must be a single character string.")
  }
  
  if (!variable %in% names(design$variables)) {
    rlang::abort(
      message = paste("Variable not found in design:", variable),
      class = "shinycomplexsurvey_variable_not_found"
    )
  }
  
  if (!is.numeric(conf_level) || conf_level <= 0 || conf_level >= 1) {
    rlang::abort("`conf_level` must be a number between 0 and 1.")
  }
  
  # -------------------------
  # Preparación
  # -------------------------
  
  var_sym <- rlang::sym(variable)
  alpha   <- 1 - conf_level
  
  n_obs <- design$variables |>
    dplyr::pull(!!var_sym) |>
    (\(x) if (na_rm) sum(!is.na(x)) else length(x))()
  
  # -------------------------
  # Estimación
  # -------------------------
  
  var_formula <- stats::as.formula(paste0("~", variable))
  
  est_obj <- switch(
    estimator,
    mean  = survey::svymean(
      var_formula,
      design = design,
      na.rm = na_rm
    ),
    total = survey::svytotal(
      var_formula,
      design = design,
      na.rm = na_rm
    ),
    prop  = survey::svymean(
      var_formula,
      design = design,
      na.rm = na_rm
    )
  )
  
  
  est  <- as.numeric(coef(est_obj))
  se   <- as.numeric(survey::SE(est_obj))
  ci   <- suppressWarnings(confint(est_obj, level = conf_level))
  
  # -------------------------
  # Salida tidy
  # -------------------------
  
  tibble::tibble(
    variable    = variable,
    estimator   = estimator,
    estimate    = est,
    se          = se,
    lci         = ci[1],
    uci         = ci[2],
    conf_level  = conf_level,
    n_obs       = n_obs
  )
}
