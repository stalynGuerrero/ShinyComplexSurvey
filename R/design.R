#' Create a complex survey design object
#'
#' Constructs a survey design object from microdata using sampling weights,
#' and optionally stratification, clustering (PSU), and finite population
#' correction (FPC). The output is returned as a \code{tbl_svy} object
#' compatible with \pkg{srvyr}.
#'
#' @param data A tibble containing survey microdata.
#' @param weight Character. Name of the sampling weight variable.
#' @param strata Optional character. Name of the stratification variable.
#' @param cluster Optional character. Name of the cluster (PSU) variable.
#' @param fpc Optional character. Name of the finite population correction variable.
#' @param nest Logical. Whether PSUs are nested within strata. Default is \code{TRUE}.
#' @param check_psu Logical. If TRUE, validates that PSUs are not shared across strata.
#'
#' @return A \code{tbl_svy} object.
#'
#' @details
#' The function wraps \code{survey::svydesign()} and converts the result
#' to a \code{srvyr} object using \code{srvyr::as_survey()}.
#'
#' Supported configurations:
#' \itemize{
#'   \item Simple random sampling (weights only)
#'   \item Stratified designs
#'   \item Clustered designs
#'   \item Stratified multistage designs
#'   \item Designs with finite population correction (FPC)
#' }
#'
#' If \code{cluster = NULL}, a single-stage design is assumed.
#'
#' @examples
#' data <- generate_example_data(n_upm = 30)
#'
#' # Full design
#' design <- as_survey_design_tbl(
#'   data,
#'   weight = "weight",
#'   strata = "strata",
#'   cluster = "upm"
#' )
#'
#' # Without stratification
#' design2 <- as_survey_design_tbl(
#'   data,
#'   weight = "weight",
#'   cluster = "upm"
#' )
#'
#' # Weights only (SRS approximation)
#' design3 <- as_survey_design_tbl(
#'   data,
#'   weight = "weight"
#' )
#'
#' @export
#' 
as_survey_design_tbl <- function(
    data,
    weight,
    strata = NULL,
    cluster = NULL,
    fpc = NULL,
    nest = TRUE,
    check_psu = TRUE
) {
  
  # ---------------------------------------------------------
  # 1. Input validation
  # ---------------------------------------------------------
  if (!tibble::is_tibble(data)) {
    rlang::abort("`data` must be a tibble.")
  }
  
  if (!is.character(weight) || length(weight) != 1) {
    rlang::abort("`weight` must be a single character string.")
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
  
  # ---------------------------------------------------------
  # 2. Weight checks
  # ---------------------------------------------------------
  if (any(is.na(data[[weight]]))) {
    rlang::abort("Weights contain missing values.")
  }
  
  if (any(data[[weight]] <= 0)) {
    rlang::abort("Weights must be strictly positive.")
  }
  
  # ---------------------------------------------------------
  # 3. PSU–strata consistency check (mejora agregada)
  # ---------------------------------------------------------
  if (check_psu && !is.null(cluster) && !is.null(strata)) {
    
    psu_check <- data |>
      dplyr::distinct(
        .data[[cluster]],
        .data[[strata]]
      ) |>
      dplyr::count(.data[[cluster]])
    
    if (any(psu_check$n > 1) && !nest) {
      warning(
        "Some PSUs appear in multiple strata. ",
        "Consider setting `nest = TRUE`."
      )
    }
  }
  
  # ---------------------------------------------------------
  # 4. Build formulas
  # ---------------------------------------------------------
  w  <- stats::as.formula(paste0("~", weight))
  id <- if (!is.null(cluster)) stats::as.formula(paste0("~", cluster)) else ~1
  st <- if (!is.null(strata))  stats::as.formula(paste0("~", strata))  else NULL
  fp <- if (!is.null(fpc))     stats::as.formula(paste0("~", fpc))     else NULL
  
  # ---------------------------------------------------------
  # 5. Build survey design
  # Lonely PSU option: when a stratum has a single PSU, variance
  # is approximated by centering at the stratum mean ("adjust").
  # ---------------------------------------------------------
  old_opt <- getOption("survey.lonely.psu")
  if (is.null(old_opt) || old_opt == "fail") {
    options(survey.lonely.psu = "adjust")
  }

  design <- survey::svydesign(
    ids     = id,
    strata  = st,
    weights = w,
    fpc     = fp,
    data    = data,
    nest    = nest
  )
  
  # ---------------------------------------------------------
  # 6. Convert to srvyr
  # ---------------------------------------------------------
  design_tbl <- srvyr::as_survey(design)
  
  # ---------------------------------------------------------
  # 7. Metadata
  # ---------------------------------------------------------
  attr(design_tbl, "design_vars") <- list(
    weight  = weight,
    strata  = strata,
    cluster = cluster,
    fpc     = fpc,
    nest    = nest
  )
  
  design_tbl
}


#' Describe a complex survey design
#'
#' Provides basic diagnostics for a complex survey design, including
#' sample size, number of strata and clusters, and summary statistics
#' of sampling weights.
#'
#' @param design A \code{tbl_svy} object.
#'
#' @return A tibble with design diagnostics.
#' @export
#'
#' @examples
#' data <- generate_example_data(30)
#' design <- as_survey_design_tbl(
#'   data,
#'   weight = "weight",
#'   strata = "strata",
#'   cluster = "upm"
#' )
#' describe_survey_design(design)
describe_survey_design <- function(design) {
  
  # ---------------------------------------------------------
  # 1. Validation
  # ---------------------------------------------------------
  if (!inherits(design, "tbl_svy")) {
    rlang::abort("`design` must be a srvyr tbl_svy object.")
  }
  
  # metadata del diseño
  design_vars <- attr(design, "design_vars")
  
  if (is.null(design_vars)) {
    rlang::abort(
      "Design metadata not found. Use `as_survey_design_tbl()`."
    )
  }
  
  data <- design$variables
  
  weight_var  <- design_vars$weight
  strata_var  <- design_vars$strata
  cluster_var <- design_vars$cluster
  
  # ---------------------------------------------------------
  # 2. Weights
  # ---------------------------------------------------------
  w <- data[[weight_var]]
  
  # ---------------------------------------------------------
  # 3. Dimensions
  # ---------------------------------------------------------
  n_obs <- nrow(data)
  
  n_strata <- if (!is.null(strata_var)) {
    dplyr::n_distinct(data[[strata_var]])
  } else {
    NA_integer_
  }
  
  n_clusters <- if (!is.null(cluster_var)) {
    dplyr::n_distinct(data[[cluster_var]])
  } else {
    NA_integer_
  }
  
  # ---------------------------------------------------------
  # 4. Weight diagnostics
  # ---------------------------------------------------------
  weight_min  <- min(w, na.rm = TRUE)
  weight_max  <- max(w, na.rm = TRUE)
  weight_mean <- mean(w, na.rm = TRUE)
  weight_cv   <- stats::sd(w, na.rm = TRUE) / weight_mean
  
  # ---------------------------------------------------------
  # 5. Output
  # ---------------------------------------------------------
  tibble::tibble(
    n_obs        = n_obs,
    n_strata     = n_strata,
    n_clusters   = n_clusters,
    weight_min   = weight_min,
    weight_max   = weight_max,
    weight_mean  = weight_mean,
    weight_cv    = weight_cv
  )
}