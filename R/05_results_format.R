#' Format survey results as a table
#'
#' @param results Tibble returned by estimate_survey().
#' @param digits Number of decimal places.
#'
#' @return A formatted tibble.
#' @export
format_results_table <- function(results, digits = 2) {
  
  required <- c("estimate", "se", "cv", "lci", "uci")
  
  missing <- setdiff(required, names(results))
  if (length(missing) > 0) {
    rlang::abort(
      paste("Missing required columns:", paste(missing, collapse = ", "))
    )
  }
  
  # identificar columnas de dominio
  meta_cols <- c("variable", "estimator", required)
  domain_cols <- setdiff(names(results), meta_cols)
  
  results %>%
    dplyr::mutate(
      estimate = round(estimate, digits),
      se       = round(se, digits),
      cv       = round(cv * 100, digits),
      lci      = round(lci, digits),
      uci      = round(uci, digits),
      ic       = paste0("[", lci, ", ", uci, "]")
    ) %>%
    dplyr::select(
      dplyr::all_of(domain_cols),
      variable,
      estimator,
      estimate,
      se,
      cv,
      ic
    ) %>%
    dplyr::rename(`CV (%)` = cv)
}



#' Plot survey estimates as bar chart
#'
#' @param results Tibble returned by estimate_survey().
#'
#' @return ggplot object.
#' @export
plot_results_bar <- function(results) {
  
  required <- c("estimate", "lci", "uci")
  if (!all(required %in% names(results))) {
    rlang::abort("Results must include estimate, lci and uci.")
  }
  
  # detectar dominios
  meta_cols <- c("variable", "estimator", "estimate", "se", "cv", "lci", "uci")
  domain_cols <- setdiff(names(results), meta_cols)
  
  if (length(domain_cols) == 0) {
    rlang::abort("No domain variables found to plot.")
  }
  
  x_var <- domain_cols[1]
  fill_var <- if (length(domain_cols) >= 2) domain_cols[2] else NULL
  
  p <- ggplot2::ggplot(
    results,
    ggplot2::aes(
      x = .data[[x_var]],
      y = estimate,
      fill = if (!is.null(fill_var)) .data[[fill_var]] else NULL
    )
  ) +
    ggplot2::geom_col(position = ggplot2::position_dodge(width = 0.9)) +
    ggplot2::geom_errorbar(
      ggplot2::aes(ymin = lci, ymax = uci),
      position = ggplot2::position_dodge(width = 0.9),
      width = 0.2
    ) +
    ggplot2::labs(
      x = x_var,
      y = "Estimate",
      fill = fill_var
    ) +
    ggplot2::theme_minimal()
  
  # proporciones → eje [0,1]
  if (unique(results$estimator) == "prop") {
    p <- p + ggplot2::scale_y_continuous(limits = c(0, 1))
  }
  
  p
}
