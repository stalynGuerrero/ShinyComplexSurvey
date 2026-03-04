#' Build a complex survey design
#'
#' @param data Tibble with survey microdata
#' @param weight Weight variable name
#' @param strata Strata variable name (optional)
#' @param cluster Cluster (PSU) variable name (optional)
#' @param fpc Finite population correction variable (optional)
#' @param nest Logical. Whether PSUs are nested within strata
#'
#' @return A tbl_svy object
#' @export

build_survey_design <- function(
    data,
    weight,
    strata = NULL,
    cluster = NULL,
    fpc = NULL,
    nest = TRUE
) {
  
  if (!tibble::is_tibble(data)) {
    rlang::abort("`data` must be a tibble.")
  }
  
  vars_required <- c(weight, strata, cluster, fpc)
  vars_required <- vars_required[!is.null(vars_required)]
  
  missing_vars <- setdiff(vars_required, names(data))
  if (length(missing_vars) > 0) {
    rlang::abort(
      message = paste(
        "Missing design variables:",
        paste(missing_vars, collapse = ", ")
      ),
      class = "shinycomplexsurvey_missing_design_vars"
    )
  }
  
  # ---- construir fórmulas ----
  w  <- stats::as.formula(paste0("~", weight))
  id <- if (!is.null(cluster)) stats::as.formula(paste0("~", cluster)) else ~1
  st <- if (!is.null(strata))  stats::as.formula(paste0("~", strata))  else NULL
  fp <- if (!is.null(fpc))     stats::as.formula(paste0("~", fpc))     else NULL
  
  design <- survey::svydesign(
    ids     = id,
    strata  = st,
    weights = w,
    fpc     = fp,
    data    = data,
    nest    = nest
  )
  
  srvyr::as_survey(design)
}


#' Describe a complex survey design
#'
#' @param design A tbl_svy object.
#'
#' @return A tibble with basic design diagnostics.
#' @export
describe_survey_design <- function(design) {
  
  if (!inherits(design, "tbl_svy")) {
    rlang::abort("`design` must be a srvyr tbl_svy object.")
  }
  
  svy <- design
  w   <- as.numeric(weights(svy))
  
  # data del diseño (modelo)
  mf <- stats::model.frame(svy)
  
  # número de estratos
  n_strata <- if (!is.null(svy$strata)) {
    dplyr::n_distinct(svy$strata)
  } else {
    NA_integer_
  }
  

  n_clusters <- if (!is.null(design$cluster)) {
    n_distinct(design$cluster[[1]])
  } else {
    NA_integer_
  }
  
  
  tibble::tibble(
    n_obs       = nrow(mf),
    n_strata    = n_strata,
    n_clusters  = n_clusters,
    weight_min  = min(w, na.rm = TRUE),
    weight_max  = max(w, na.rm = TRUE),
    weight_mean = mean(w, na.rm = TRUE)
  )
}
