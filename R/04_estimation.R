#' Estimate survey statistics under complex sampling designs
#'
#' Computes classical design-based estimators for complex surveys using
#' sampling weights, stratification and clustering. The function operates
#' on objects of class \code{tbl_svy} and supports estimation by domains
#' (subpopulations) defined by one or more grouping variables.
#'
#' The following estimators are implemented:
#'
#' \itemize{
#'   \item \strong{Mean} (\code{"mean"}): weighted population mean.
#'   \item \strong{Total} (\code{"total"}): weighted population total
#'         (Horvitz--Thompson estimator).
#'   \item \strong{Proportion} (\code{"prop"}): weighted proportions for
#'         binary variables or category-wise proportions for categorical variables.
#'   \item \strong{Ratio} (\code{"ratio"}): ratio of two population totals.
#'   \item \strong{Quantile} (\code{"quantile"}): weighted quantiles
#'         (e.g. median, quartiles).
#' }
#'
#' All estimators account for the complex sampling design. Variance estimation
#' is carried out using first-order Taylor linearization, as implemented in
#' the \pkg{survey} and \pkg{srvyr} packages.
#'
#' @param design A \code{tbl_svy} object created with
#'   \code{build_survey_design()}, containing the full survey design
#'   (weights, strata and clusters).
#'
#' @param variable Character string indicating the variable of interest.
#'   Required for \code{"mean"}, \code{"total"}, \code{"prop"} and
#'   \code{"quantile"}. Not used for \code{"ratio"}.
#'
#' @param estimator Character string specifying the estimator to compute.
#'   One of \code{"mean"}, \code{"total"}, \code{"prop"}, \code{"ratio"},
#'   or \code{"quantile"}.
#'
#' @param by Optional character vector specifying domain variables.
#'   If \code{NULL}, the estimator is computed for the entire population.
#'   If provided, estimates are produced independently for each domain
#'   or interaction of domains.
#'
#' @param na_rm Logical. Whether missing values should be removed prior
#'   to estimation. Defaults to \code{TRUE}.
#'
#' @param conf_level Confidence level for interval estimation.
#'   Defaults to \code{0.95}.
#'
#' @param numerator Character string indicating the numerator variable
#'   for the \code{"ratio"} estimator.
#'
#' @param denominator Character string indicating the denominator variable
#'   for the \code{"ratio"} estimator.
#'
#' @param probs Numeric vector of probabilities in the open interval (0, 1)
#'   indicating the quantiles to be estimated when
#'   \code{estimator = "quantile"}.
#'
#' @details
#' \strong{Mean.}
#' The weighted population mean of a variable Y is estimated as the ratio
#' of the weighted sum of Y to the sum of sampling weights, that is,
#' sum(w_i * y_i) divided by sum(w_i), where w_i denotes the sampling weight
#' of unit i. The variance is approximated by Taylor linearization, treating
#' the mean as a ratio estimator.
#'
#' \strong{Total.}
#' The population total is estimated using the Horvitz--Thompson estimator,
#' defined as the sum over the sample of w_i * y_i. Variance estimation
#' follows standard linearization methods under the specified design.
#'
#' \strong{Proportions.}
#' For binary variables, proportions are estimated as weighted means of
#' indicator variables. For categorical variables with more than two levels,
#' category-specific indicator variables are constructed and proportions
#' are estimated separately for each category. Variances are obtained
#' via linearization of the corresponding mean estimators.
#'
#' \strong{Ratios.}
#' Ratios are defined as the ratio of two population totals, namely
#' sum(w_i * y_i) divided by sum(w_i * x_i), where Y is the numerator
#' and X the denominator variable. Variance estimation is based on
#' first-order Taylor linearization of the ratio estimator and is implemented
#' through \code{survey::svyratio()}.
#'
#' \strong{Quantiles.}
#' Quantiles are estimated from the weighted empirical distribution function.
#' The p-th quantile is defined as the smallest value q such that the weighted
#' cumulative distribution function evaluated at q is greater than or equal
#' to p. Variance and confidence intervals are obtained via linearization
#' methods as implemented in \code{survey::svyquantile()}.
#'
#' \strong{Domain estimation.}
#' When domain variables are supplied, all estimators are computed independently
#' within each domain. Variance estimation is carried out conditionally on the
#' domain, following standard design-based practice.
#'
#' \strong{Confidence intervals.}
#' Confidence intervals are constructed using a Normal approximation of the form
#' estimate plus or minus z times the standard error, where z corresponds to
#' the specified confidence level.
#'
#' @return
#' A tibble containing the point estimate and associated quality measures.
#' Depending on the estimator, the output includes:
#'
#' \itemize{
#'   \item \code{estimate}: point estimate.
#'   \item \code{se}: standard error.
#'   \item \code{cv}: coefficient of variation.
#'   \item \code{lci}: lower confidence interval.
#'   \item \code{uci}: upper confidence interval.
#' }
#'
#' Additional columns identify the variable, estimator type, domain variables,
#' and, when applicable, categories or quantile levels.
#'
#' @seealso
#' \code{\link[srvyr]{survey_mean}},
#' \code{\link[srvyr]{survey_total}},
#' \code{\link[survey]{svyratio}},
#' \code{\link[survey]{svyquantile}}
#'
#' @references
#' Cochran, W. G. (1977).
#' \emph{Sampling Techniques} (3rd ed.).
#' Wiley.
#'
#' Särndal, C.-E., Swensson, B., & Wretman, J. (1992).
#' \emph{Model Assisted Survey Sampling}.
#' Springer.
#'
#' Lohr, S. (2019).
#' \emph{Sampling: Design and Analysis} (2nd ed.).
#' CRC Press.
#'
#' Lumley, T. (2010).
#' \emph{Complex Surveys: A Guide to Analysis Using R}.
#' Wiley.
#'
#' @export

estimate_survey <- function(
    design,
    variable = NULL,
    estimator = c("mean", "total", "prop", "ratio", "quantile"),
    by = NULL,
    na_rm = TRUE,
    conf_level = 0.95,
    numerator = NULL,
    denominator = NULL,
    ratio_num_level = NULL,
    ratio_den_level = NULL,
    probs = c(0.25, 0.5, 0.75)
) {
  
  estimator <- match.arg(estimator)
  
  # ==================================================
  # Validaciones base
  # ==================================================
  if (!inherits(design, "tbl_svy")) {
    rlang::abort("`design` must be a tbl_svy object.")
  }
  
  vars <- names(design$variables)
  
  if (!is.null(by)) {
    if (!is.character(by)) {
      rlang::abort("`by` must be a character vector.")
    }
    missing_by <- setdiff(by, vars)
    if (length(missing_by) > 0) {
      rlang::abort(
        paste("Grouping variables not found:", paste(missing_by, collapse = ", "))
      )
    }
  }
  
  alpha <- 1 - conf_level
  z <- stats::qnorm(1 - alpha / 2)
  
  # ==================================================
  # Helpers
  # ==================================================
  
  domain_keys <- function(df, by) {
    if (is.null(by) || length(by) == 0) return(NULL)
    dplyr::distinct(df, dplyr::across(dplyr::all_of(by)))
  }
  
  subset_design_by_row <- function(svy, by, row) {
    if (is.null(by) || length(by) == 0) return(svy)
    
    conds <- lapply(by, function(v) {
      call("==", as.name(v), row[[v]][[1]])
    })
    cond <- Reduce(function(a, b) call("&", a, b), conds)
    
    subset(svy, eval(cond, svy$variables, parent.frame()))
  }
  
  # survey.design base (siempre)
  svy_obj <- srvyr::as_survey_design(design)
  
  # ==================================================
  # MEAN / TOTAL / PROP  (srvyr)
  # ==================================================
  if (estimator %in% c("mean", "total", "prop")) {
    
    if (!is.character(variable) || length(variable) != 1 || !variable %in% vars) {
      rlang::abort("`variable` must be a single valid variable name.")
    }
    
    var_sym  <- rlang::sym(variable)
    var_data <- design$variables[[variable]]
    
    design_grp <- design
    if (!is.null(by) && length(by) > 0) {
      design_grp <- design_grp %>%
        srvyr::group_by(dplyr::across(dplyr::all_of(by)))
    }
    
    if (estimator == "mean") {
      
      res <- design_grp %>%
        srvyr::summarise(
          estimate = srvyr::survey_mean(
            !!var_sym, vartype = c("se", "cv"), na.rm = na_rm
          )
        )
      
    } else if (estimator == "total") {
      
      res <- design_grp %>%
        srvyr::summarise(
          estimate = srvyr::survey_total(
            !!var_sym, vartype = c("se", "cv"), na.rm = na_rm
          )
        )
      
    } else { # prop
      
      uniq <- unique(stats::na.omit(var_data))
      
      # binaria
      if (is.logical(var_data) || length(uniq) == 2) {
        
        res <- design_grp %>%
          srvyr::summarise(
            estimate = srvyr::survey_mean(
              !!var_sym, vartype = c("se", "cv"), na.rm = na_rm
            )
          )
        
      } else {
        
        levs <- levels(as.factor(var_data))
        
        res <- purrr::map_dfr(levs, function(lv) {
          
          tmp <- design_grp %>%
            dplyr::mutate(.ind = (!!var_sym) == lv) %>%
            srvyr::summarise(
              estimate = srvyr::survey_mean(
                .ind, vartype = c("se", "cv"), na.rm = na_rm
              )
            )
          
          tmp[[variable]] <- lv
          tmp
        })
      }
    }
    
    res <- res %>%
      dplyr::rename(se = estimate_se, cv = estimate_cv) %>%
      dplyr::mutate(
        lci = estimate - z * se,
        uci = estimate + z * se,
        estimator = estimator,
        variable = variable
      )
    
    # ==================================================
    # RATIO (survey)
    # ==================================================
  } else if (estimator == "ratio") {
    
    # dominios (faltaba en tu versión)
    keys <- domain_keys(design$variables, by)
    
    # Validación mínima de variable si la vamos a usar
    if (!is.null(variable) && (!is.character(variable) || length(variable) != 1)) {
      rlang::abort("`variable` must be a single character string when provided.")
    }
    
    is_cat <- !is.null(variable) &&
      (is.factor(design$variables[[variable]]) || is.character(design$variables[[variable]]))
    
    # -------------------------------
    # CASO 1: ratio categórica
    # -------------------------------
    if (is_cat) {
      
      levels_var <- unique(stats::na.omit(design$variables[[variable]]))
      
      if (is.null(ratio_num_level) || is.null(ratio_den_level)) {
        rlang::abort(
          "For categorical ratios, `ratio_num_level` and `ratio_den_level` must be specified."
        )
      }
      
      if (!ratio_num_level %in% levels_var || !ratio_den_level %in% levels_var) {
        rlang::abort("Selected ratio levels are not present in the variable.")
      }
      
      if (ratio_num_level == ratio_den_level) {
        rlang::abort("Numerator and denominator categories must be different.")
      }
      
      compute_ratio <- function(svy) {
        
        svy_tmp <- update(
          svy,
          I_num = as.numeric(get(variable) == ratio_num_level),
          I_den = as.numeric(get(variable) == ratio_den_level)
        )
        
        r <- survey::svyratio(
          ~I_num, ~I_den,
          design = svy_tmp,
          na.rm = na_rm
        )
        
        est <- as.numeric(coef(r))
        se  <- as.numeric(sqrt(vcov(r)))
        
        tibble::tibble(estimate = est, se = se, cv = se / est)
      }
      
      ratio_label <- paste0(variable, ": ", ratio_num_level, "/", ratio_den_level)
      
      # -------------------------------
      # CASO 2: ratio continua
      # -------------------------------
    } else {
      
      if (is.null(numerator) || is.null(denominator)) {
        rlang::abort("For continuous ratios, `numerator` and `denominator` must be provided.")
      }
      if (!numerator %in% vars || !denominator %in% vars) {
        rlang::abort("Numerator or denominator not found in data.")
      }
      if (numerator == denominator) {
        rlang::abort("Numerator and denominator must be different variables.")
      }
      
      compute_ratio <- function(svy) {
        
        r <- survey::svyratio(
          stats::as.formula(paste0("~", numerator)),
          stats::as.formula(paste0("~", denominator)),
          design = svy,
          na.rm = na_rm
        )
        
        est <- as.numeric(coef(r))
        se  <- as.numeric(sqrt(vcov(r)))
        
        tibble::tibble(estimate = est, se = se, cv = se / est)
      }
      
      ratio_label <- paste0(numerator, "_over_", denominator)
    }
    
    # ejecutar (común)
    if (is.null(keys)) {
      res <- compute_ratio(svy_obj)
    } else {
      res <- purrr::map_dfr(seq_len(nrow(keys)), function(i) {
        row <- keys[i, , drop = FALSE]
        dplyr::bind_cols(
          row,
          compute_ratio(subset_design_by_row(svy_obj, by, row))
        )
      })
    }
    
    # IMPORTANTÍSIMO: asignar a res (te faltaba)
    res <- res %>%
      dplyr::mutate(
        lci = estimate - z * se,
        uci = estimate + z * se,
        estimator = "ratio",
        variable = ratio_label
      )
    
    # ==================================================
    # QUANTILE (survey)
    # ==================================================
  } else if (estimator == "quantile") {
    
    if (!is.character(variable) || length(variable) != 1 || !variable %in% vars) {
      rlang::abort("`variable` must be a valid variable name for quantiles.")
    }
    
    probs <- sort(unique(probs))
    if (any(probs <= 0 | probs >= 1)) {
      rlang::abort("`probs` must be strictly between 0 and 1.")
    }
    
    keys <- domain_keys(design$variables, by)
    
    compute_quantile <- function(svy) {
      q <- survey::svyquantile(
        stats::as.formula(paste0("~", variable)),
        design = svy,
        quantiles = probs,
        na.rm = na_rm,
        ci = TRUE
      )
      qdf <- as.data.frame(q[[1]])
      
      tibble::tibble(
        quantile = probs,
        estimate = qdf[, "quantile"],
        se = qdf[, "se"],
        cv = qdf[, "se"] / qdf[, "quantile"]
      )
    }
    
    if (is.null(keys)) {
      res <- compute_quantile(svy_obj)
    } else {
      res <- purrr::map_dfr(seq_len(nrow(keys)), function(i) {
        row <- keys[i, , drop = FALSE]
        dplyr::bind_cols(
          row,
          compute_quantile(subset_design_by_row(svy_obj, by, row))
        )
      })
    }
    
    res <- res %>%
      dplyr::mutate(
        lci = estimate - z * se,
        uci = estimate + z * se,
        estimator = "quantile",
        variable = variable
      )
    
  } else {
    rlang::abort("Unsupported estimator.")
  }
  
  dplyr::relocate(res, variable, estimator)
}




estimate_survey2 <- function(
    design,
    variable = NULL,
    estimator = c("mean", "total", "prop", "ratio", "quantile"),
    by = NULL,
    na_rm = TRUE,
    conf_level = 0.95,
    numerator = NULL,
    denominator = NULL,
    probs = c(0.25, 0.5, 0.75)
) {
  
  estimator <- match.arg(estimator)
  
  # ==================================================
  # Validaciones base
  # ==================================================
  if (!inherits(design, "tbl_svy")) {
    rlang::abort("`design` must be a tbl_svy object.")
  }
  
  vars <- names(design$variables)
  
  if (!is.null(by)) {
    if (!is.character(by)) {
      rlang::abort("`by` must be a character vector.")
    }
    missing_by <- setdiff(by, vars)
    if (length(missing_by) > 0) {
      rlang::abort(
        paste("Grouping variables not found:", paste(missing_by, collapse = ", "))
      )
    }
  }
  
  alpha <- 1 - conf_level
  z <- stats::qnorm(1 - alpha / 2)
  
  # ==================================================
  # Helpers
  # ==================================================
  
  # claves de dominio
  domain_keys <- function(df, by) {
    if (is.null(by) || length(by) == 0) return(NULL)
    dplyr::distinct(df, dplyr::across(dplyr::all_of(by)))
  }
  
  # subset survey.design por fila de dominio (base R)
  subset_design_by_row <- function(svy, by, row) {
    if (is.null(by) || length(by) == 0) return(svy)
    
    conds <- lapply(by, function(v) {
      call("==", as.name(v), row[[v]][[1]])
    })
    cond <- Reduce(function(a, b) call("&", a, b), conds)
    
    subset(svy, eval(cond, svy$variables, parent.frame()))
  }
  
  # survey.design base
  svy_obj <- srvyr::as_survey_design(design)
  
  # ==================================================
  # MEAN / TOTAL / PROP  (srvyr)
  # ==================================================
  if (estimator %in% c("mean", "total", "prop")) {
    
    if (!is.character(variable) || length(variable) != 1 || !variable %in% vars) {
      rlang::abort("`variable` must be a single valid variable name.")
    }
    
    var_sym  <- rlang::sym(variable)
    var_data <- design$variables[[variable]]
    
    design_grp <- design
    if (!is.null(by) && length(by) > 0) {
      design_grp <- design_grp %>%
        srvyr::group_by(dplyr::across(dplyr::all_of(by)))
    }
    
    if (estimator == "mean") {
      
      res <- design_grp %>%
        srvyr::summarise(
          estimate = srvyr::survey_mean(
            !!var_sym, vartype = c("se", "cv"), na.rm = na_rm
          )
        )
      
    } else if (estimator == "total") {
      
      res <- design_grp %>%
        srvyr::summarise(
          estimate = srvyr::survey_total(
            !!var_sym, vartype = c("se", "cv"), na.rm = na_rm
          )
        )
      
    } else { # prop
      
      uniq <- unique(stats::na.omit(var_data))
      
      # binaria
      if (is.logical(var_data) || length(uniq) == 2) {
        
        res <- design_grp %>%
          srvyr::summarise(
            estimate = srvyr::survey_mean(
              !!var_sym, vartype = c("se", "cv"), na.rm = na_rm
            )
          )
        
      } else {
        
        # categórica: long explícito
        levs <- levels(as.factor(var_data))
        
        res <- purrr::map_dfr(levs, function(lv) {
          
          tmp <- design_grp %>%
            dplyr::mutate(.ind = (!!var_sym) == lv) %>%
            srvyr::summarise(
              estimate = srvyr::survey_mean(
                .ind, vartype = c("se", "cv"), na.rm = na_rm
              )
            )
          
          tmp[[variable]] <- lv
          tmp
        })
      }
    }
    
    res <- res %>%
      dplyr::rename(se = estimate_se, cv = estimate_cv) %>%
      dplyr::mutate(
        lci = estimate - z * se,
        uci = estimate + z * se,
        estimator = estimator,
        variable = variable
      )
    
    # ==================================================
    # RATIO  (survey)
    # ==================================================
  }else if (estimator == "ratio") {
    
    is_cat <- is.factor(design$variables[[variable]]) ||
      is.character(design$variables[[variable]])
    
    # ===============================
    # CASO 1: RATIO CATEGÓRICA
    # ===============================
    if (is_cat) {
      
      levels_var <- unique(stats::na.omit(design$variables[[variable]]))
      
      if (is.null(ratio_num_level) || is.null(ratio_den_level)) {
        rlang::abort(
          "For categorical ratios, `ratio_num_level` and `ratio_den_level` must be specified."
        )
      }
      
      if (!ratio_num_level %in% levels_var ||
          !ratio_den_level %in% levels_var) {
        rlang::abort(
          "Selected ratio levels are not present in the variable."
        )
      }
      
      if (ratio_num_level == ratio_den_level) {
        rlang::abort(
          "Numerator and denominator categories must be different."
        )
      }
      
      compute_ratio <- function(svy) {
        
        svy_tmp <- update(
          svy,
          I_num = as.numeric(get(variable) == ratio_num_level),
          I_den = as.numeric(get(variable) == ratio_den_level)
        )
        
        r <- survey::svyratio(
          ~I_num,
          ~I_den,
          design = svy_tmp,
          na.rm = na_rm
        )
        
        est <- as.numeric(coef(r))
        se  <- sqrt(vcov(r))
        
        tibble::tibble(
          estimate = est,
          se = se,
          cv = se / est
        )
      }
      
      ratio_label <- paste0(variable, ": ", ratio_num_level, "/", ratio_den_level)
      
      # ===============================
      # CASO 2: RATIO CONTINUA
      # ===============================
    } else {
      
      compute_ratio <- function(svy) {
        
        r <- survey::svyratio(
          stats::as.formula(paste0("~", numerator)),
          stats::as.formula(paste0("~", denominator)),
          design = svy,
          na.rm = na_rm
        )
        
        est <- as.numeric(coef(r))
        se  <- sqrt(vcov(r))
        
        tibble::tibble(
          estimate = est,
          se = se,
          cv = se / est
        )
      }
      
      ratio_label <- paste0(numerator, "_over_", denominator)
    }
    
    if (is.null(keys)) {
      
      res <- compute_ratio(svy_obj)
      
    } else {
      
      res <- purrr::map_dfr(seq_len(nrow(keys)), function(i) {
        
        row <- keys[i, , drop = FALSE]
        
        dplyr::bind_cols(
          row,
          compute_ratio(
            subset_design_by_row(svy_obj, by, row)
          )
        )
      })
    }
    
    res %>%
      dplyr::mutate(
        lci = estimate - z * se,
        uci = estimate + z * se,
        estimator = "ratio",
        variable = ratio_label
      )
  
  
    # ==================================================
    # QUANTILE  (survey)
    # ==================================================
  } else if (estimator == "quantile") {
    
    if (!is.character(variable) || !variable %in% vars) {
      rlang::abort("`variable` must be a valid variable name for quantiles.")
    }
    
    probs <- sort(unique(probs))
    if (any(probs <= 0 | probs >= 1)) {
      rlang::abort("`probs` must be strictly between 0 and 1.")
    }
    
    keys <- domain_keys(design$variables, by)
    
    compute_quantile <- function(svy) {
      q <- survey::svyquantile(
        stats::as.formula(paste0("~", variable)),
        design = svy,
        quantiles = probs,
        na.rm = na_rm,
        ci = TRUE
      )
      qdf <- as.data.frame(q[[1]])
      tibble::tibble(
        quantile = probs,
        estimate = qdf[, "quantile"],
        se = qdf[, "se"],
        cv = qdf[, "se"] / qdf[, "quantile"]
      )
    }
    
    if (is.null(keys)) {
      res <- compute_quantile(svy_obj)
    } else {
      res <- purrr::map_dfr(seq_len(nrow(keys)), function(i) {
        row <- keys[i, , drop = FALSE]
        dplyr::bind_cols(
          row,
          compute_quantile(subset_design_by_row(svy_obj, by, row))
        )
      })
    }
    
    res <- res %>%
      dplyr::mutate(
        lci = estimate - z * se,
        uci = estimate + z * se,
        estimator = "quantile",
        variable = variable
      )
    
  } else {
    rlang::abort("Unsupported estimator.")
  }
  
  dplyr::relocate(res, variable, estimator)
}



