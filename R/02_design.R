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
  
  design <- srvyr::as_survey_design(
    data = data,
    weights = !!rlang::sym(weight),
    strata  = if (!is.null(strata))  !!rlang::sym(strata)  else NULL,
    ids     = if (!is.null(cluster)) !!rlang::sym(cluster) else ~1,
    fpc     = if (!is.null(fpc))     !!rlang::sym(fpc)     else NULL,
    nest    = nest
  )
  
  attr(design, "design_spec") <- list(
    weight  = weight,
    strata  = strata,
    cluster = cluster,
    fpc     = fpc,
    nest    = nest
  )
  
  design
}



#' Describe a survey design
#'
#' @param design A tbl_svy object
#'
#' @return Tibble with basic design diagnostics
#' @export
describe_survey_design <- function(design) {
  
  if (!inherits(design, "tbl_svy")) {
    rlang::abort("`design` must be a srvyr survey object.")
  }
  
  data <- design$variables
  spec <- attr(design, "design_spec")
  
  tibble::tibble(
    n_obs        = nrow(data),
    n_strata     = if (!is.null(spec$strata))
      dplyr::n_distinct(data[[spec$strata]])
    else NA_integer_,
    n_clusters   = if (!is.null(spec$cluster))
      dplyr::n_distinct(data[[spec$cluster]])
    else NA_integer_,
    weight_min   = min(data[[spec$weight]], na.rm = TRUE),
    weight_mean  = mean(data[[spec$weight]], na.rm = TRUE),
    weight_max   = max(data[[spec$weight]], na.rm = TRUE)
  )
}
