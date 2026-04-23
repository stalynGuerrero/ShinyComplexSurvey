#' Estimate survey statistics under complex sampling designs
#'
#' Computes design-based estimators for complex survey data using
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
#'         binary or categorical variables.
#'   \item \strong{Ratio} (\code{"ratio"}): ratio of two population totals.
#'   \item \strong{Quantile} (\code{"quantile"}): weighted quantiles.
#' }
#'
#' All estimators account for the complex sampling design. Variance estimation
#' is based on Taylor linearization or the methods implemented in the
#' \pkg{survey} package.
#'
#' @param design A \code{tbl_svy} object created with
#'   \code{as_survey_design_tbl()}, containing weights, strata and clusters.
#'
#' @param variable Character string indicating the variable of interest.
#'   Required for \code{"mean"}, \code{"total"}, \code{"prop"} and
#'   \code{"quantile"}. Ignored when \code{estimator = "ratio"}.
#'
#' @param estimator Character string specifying the estimator.
#'   One of \code{"mean"}, \code{"total"}, \code{"prop"}, \code{"ratio"},
#'   or \code{"quantile"}.
#'
#' @param by Optional character vector of domain variables.
#'
#' @param na_rm Logical. Whether to remove missing values. Default is \code{TRUE}.
#'
#' @param conf_level Confidence level for interval estimation.
#'
#' @param numerator Character string for numerator variable in ratio estimation.
#'
#' @param denominator Character string for denominator variable in ratio estimation.
#'
#' @param ratio_num_level Character. Category used as numerator when the numerator
#'   variable is categorical.
#'
#' @param ratio_den_level Character. Category used as denominator when the denominator
#'   variable is categorical.
#'
#' @param probs Numeric vector of probabilities in (0,1) for quantiles.
#'
#' @details
#'
#' \strong{Mean}
#'
#' The population mean is estimated as:
#'
#' \deqn{
#' \hat{\bar{X}} = \frac{\sum_{i \in s} w_i y_i}{\sum_{i \in s} w_i}
#' }
#'
#' where \eqn{w_i} are sampling weights and \eqn{y_i} the observed values.
#'
#' \strong{Total}
#'
#' The population total is estimated using the Horvitz--Thompson estimator:
#'
#' \deqn{
#' \hat{T} = \sum_{i \in s} w_i y_i
#' }
#'
#'
#' \strong{Proportions}
#'
#' For binary variables:
#'
#' \deqn{
#' \hat{P} = \frac{\sum_{i \in s} w_i y_i}{\sum_{i \in s} w_i}
#' }
#'
#' where \eqn{y_i \in \{0,1\}}.
#'
#' For categorical variables, proportions are computed by defining indicator
#' variables:
#'
#' \deqn{
#' I(y_i = k)
#' }
#'
#' and estimating each category separately.
#'
#' \strong{Ratios}
#'
#' The ratio estimator is defined as:
#'
#' \deqn{
#' \hat{R} = \frac{\sum_{i \in s} w_i y_i}{\sum_{i \in s} w_i x_i}
#' }
#'
#' When variables are categorical, indicator variables are constructed
#' for the specified categories.
#'
#' Variance estimation is based on first-order Taylor linearization using
#' \code{survey::svyratio()}.
#'
#' \strong{Quantiles}
#'
#' Quantiles are defined from the weighted empirical distribution function:
#'
#' \deqn{
#' \hat{F}(q) = \frac{\sum_{i \in s} w_i I(y_i \leq q)}{\sum_{i \in s} w_i}
#' }
#'
#' The \eqn{p}-th quantile is the smallest \eqn{q} such that:
#'
#' \deqn{
#' \hat{F}(q) \geq p
#' }
#'
#'
#' \strong{Domain estimation}
#'
#' Estimation is performed within domains defined by \code{by}. Variance
#' estimation accounts for the complex design structure within each domain.
#'
#' \strong{Confidence intervals}
#'
#' Confidence intervals are constructed as:
#'
#' \deqn{
#' \hat{\theta} \pm z_{1-\alpha/2} \cdot SE(\hat{\theta})
#' }
#'
#' assuming asymptotic normality.
#'
#' @return
#' A tibble containing:
#'
#' \itemize{
#'   \item \code{estimate}: point estimate
#'   \item \code{se}: standard error
#'   \item \code{cv}: coefficient of variation
#'   \item \code{deff}: design effect
#'   \item \code{lci}: lower confidence interval
#'   \item \code{uci}: upper confidence interval
#' }
#'
#' Additional columns identify domains, variables and estimator type.
#'
#' @seealso
#' \code{\link[srvyr]{survey_mean}},
#' \code{\link[srvyr]{survey_total}},
#' \code{\link[survey]{svyratio}},
#' \code{\link[survey]{svyquantile}}
#'
#' @examples
#' # ---------------------------------------------------------
#' # Generate example data
#' # ---------------------------------------------------------
#' data <- generate_example_data(n_upm = 30, seed = 123)
#'
#' # Build survey design
#' design <- srvyr::as_survey_design(
#'   data,
#'   ids = upm,
#'   strata = strata,
#'   weights = weight
#' )
#'
#' # ---------------------------------------------------------
#' # Mean estimation
#' # ---------------------------------------------------------
#' estimate_survey(
#'   design,
#'   variable = "ingreso_pc",
#'   estimator = "mean"
#' )
#'
#' # By domain
#' estimate_survey(
#'   design,
#'   variable = "ingreso_pc",
#'   estimator = "mean",
#'   by = "region"
#' )
#'
#' # ---------------------------------------------------------
#' # Total estimation
#' # ---------------------------------------------------------
#' estimate_survey(
#'   design,
#'   variable = "ingreso_pc",
#'   estimator = "total"
#' )
#'
#' # ---------------------------------------------------------
#' # Proportion (binary)
#' # ---------------------------------------------------------
#' estimate_survey(
#'   design,
#'   variable = "pobre",
#'   estimator = "prop"
#' )
#'
#' # Proportion (categorical)
#' estimate_survey(
#'   design,
#'   variable = "empleo",
#'   estimator = "prop"
#' )
#'
#' # ---------------------------------------------------------
#' # Ratio estimation (numeric)
#' # ---------------------------------------------------------
#' estimate_survey(
#'   design,
#'   estimator = "ratio",
#'   numerator = "ingreso_pc",
#'   denominator = "gasto_pc"
#' )
#'
#' # Ratio with domains
#' estimate_survey(
#'   design,
#'   estimator = "ratio",
#'   numerator = "ingreso_pc",
#'   denominator = "gasto_pc",
#'   by = "region"
#' )
#'
#' # ---------------------------------------------------------
#' # Ratio (categorical vs categorical)
#' # Example: proportion of Formal vs Informal
#' # ---------------------------------------------------------
#' estimate_survey(
#'   design,
#'   estimator = "ratio",
#'   numerator = "empleo",
#'   denominator = "empleo",
#'   ratio_num_level = "Formal",
#'   ratio_den_level = "Informal"
#' )
#'
#' # ---------------------------------------------------------
#' # Quantiles
#' # ---------------------------------------------------------
#' estimate_survey(
#'   design,
#'   variable = "ingreso_pc",
#'   estimator = "quantile",
#'   probs = c(0.25, 0.5, 0.75)
#' )
#'
#' @references
#' Cochran (1977); Särndal et al. (1992); Lohr (2019); Lumley (2010)
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
  
  # ----------------------------------------------------------
  # Helpers
  # ----------------------------------------------------------
  
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
  
  # ==========================================================
  # MEAN / TOTAL / PROP
  # ==========================================================
  
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
      
      if (!is.numeric(var_data)) {
        rlang::abort("Mean requires numeric variable.")
      }
      
      res <- design_grp %>%
        srvyr::summarise(
          estimate = srvyr::survey_mean(
            !!var_sym, vartype = c("se", "cv"), na.rm = na_rm, deff = TRUE
          )
        )
      
    } else if (estimator == "total") {
      
      if (!is.numeric(var_data)) {
        rlang::abort("Total requires numeric variable.")
      }
      
      res <- design_grp %>%
        srvyr::summarise(
          estimate = srvyr::survey_total(
            !!var_sym, vartype = c("se", "cv"), na.rm = na_rm, deff = TRUE
          )
        )
      
    } else {

      uniq <- unique(stats::na.omit(var_data))
      is_binary <- is.logical(var_data) ||
        (is.numeric(var_data) && all(uniq %in% c(0, 1)))

      if (is_binary) {

        res <- design_grp %>%
          srvyr::summarise(
            estimate = srvyr::survey_mean(
              !!var_sym, vartype = c("se", "cv"), na.rm = na_rm, deff = TRUE
            )
          )

      } else {

        levs <- levels(as.factor(var_data))

        res <- purrr::map_dfr(levs, function(lv) {

          tmp <- design_grp %>%
            dplyr::mutate(.ind = (!!var_sym) == lv) %>%
            srvyr::summarise(
              estimate = srvyr::survey_mean(
                .ind, vartype = c("se", "cv"), na.rm = na_rm, deff = TRUE
              )
            )

          tmp[[variable]] <- lv
          tmp
        })
      }
    }
    
    res <- res %>%
      dplyr::rename(se = estimate_se, cv = estimate_cv, 
                    deff = estimate_deff) %>%
      dplyr::mutate(
        lci = estimate - z * se,
        uci = estimate + z * se,
        estimator = estimator,
        variable = variable
      )
    
    # ==========================================================
    # RATIO
    # ==========================================================
    
  } else if (estimator == "ratio") {
    
    if (is.null(numerator) || is.null(denominator)) {
      rlang::abort("Both numerator and denominator must be provided.")
    }
    
    if (!numerator %in% vars || !denominator %in% vars) {
      rlang::abort("Numerator or denominator not found in data.")
    }
    
    num_data <- design$variables[[numerator]]
    den_data <- design$variables[[denominator]]
    
    num_is_num <- is.numeric(num_data)
    den_is_num <- is.numeric(den_data)
    num_is_cat <- is.factor(num_data) || is.character(num_data)
    den_is_cat <- is.factor(den_data) || is.character(den_data)
    
    if (num_is_num && den_is_num) {
      
      if (numerator == denominator) {
        rlang::abort("Continuous ratios require different variables.")
      }
      
      compute_ratio <- function(svy) {
        
        r <- survey::svyratio(
          stats::as.formula(paste0("~", numerator)),
          stats::as.formula(paste0("~", denominator)),
          design = svy,
          na.rm  = na_rm
        )
        
        est <- as.numeric(coef(r))
        se  <- as.numeric(survey::SE(r))
        
        tibble::tibble(
          estimate = est,
          se       = se,
          cv       = ifelse(abs(est) < .Machine$double.eps, NA_real_, se / est),
          deff = NA_real_
        )
      }
      
    } else {
      
      if (num_is_cat && is.null(ratio_num_level)) {
        rlang::abort("Category for numerator must be specified.")
      }
      if (den_is_cat && is.null(ratio_den_level)) {
        rlang::abort("Category for denominator must be specified.")
      }
      
      compute_ratio <- function(svy) {
        
        svy_tmp <-stats::update(
          svy,
          .num = if (num_is_cat) {
            as.numeric(get(numerator) == ratio_num_level)
          } else {
            get(numerator)
          },
          .den = if (den_is_cat) {
            as.numeric(get(denominator) == ratio_den_level)
          } else {
            get(denominator)
          }
        )
      
        r <- survey::svyratio(~.num, ~.den, design = svy_tmp, na.rm = na_rm)
        
        est <- as.numeric(coef(r))
        se  <- as.numeric(survey::SE(r))
        
        tibble::tibble(
          estimate = est,
          se       = se,
          cv       = ifelse(abs(est) < .Machine$double.eps, NA_real_, se / est),
          deff = NA_real_
        )
      }
    }
    
    keys <- domain_keys(design$variables, by)
    
    if (is.null(keys)) {
      res <- compute_ratio(design)
    } else {
      res <- purrr::map_dfr(seq_len(nrow(keys)), function(i) {
        row <- keys[i, , drop = FALSE]
        dplyr::bind_cols(
          row,
          compute_ratio(subset_design_by_row(design, by, row))
        )
      })
    }
    
    res <- res %>%
      dplyr::mutate(
        lci = estimate - z * se,
        uci = estimate + z * se,
        estimator = "ratio",
        variable = paste0(numerator, "_over_", denominator)
      )
    
    # ==========================================================
    # QUANTILE
    # ==========================================================
    
  } else {
    
    if (!is.character(variable) || length(variable) != 1 || !variable %in% vars) {
      rlang::abort("`variable` must be valid for quantiles.")
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
        se       = qdf[, "se"],
        cv       = ifelse(
          abs(qdf[, "quantile"]) < .Machine$double.eps,
          NA_real_,
          qdf[, "se"] / qdf[, "quantile"]
        ),
        deff = NA_real_
      )
    }
    
    if (is.null(keys)) {
      res <- compute_quantile(design)
    } else {
      res <- purrr::map_dfr(seq_len(nrow(keys)), function(i) {
        row <- keys[i, , drop = FALSE]
        dplyr::bind_cols(
          row,
          compute_quantile(subset_design_by_row(design, by, row))
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
  }
  
  dplyr::relocate(res, variable, estimator) %>%
    dplyr::mutate(
      quality = dplyr::case_when(
        is.na(cv)  ~ NA_character_,
        cv < 0.05  ~ "Very high precision",
        cv < 0.10  ~ "High precision",
        cv < 0.20  ~ "Acceptable precision",
        cv < 0.30  ~ "Use with caution",
        TRUE       ~ "Low precision"
      )
    )
}



