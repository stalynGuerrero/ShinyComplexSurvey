#' Format survey estimation results for presentation
#'
#' @param results Tibble returned by estimate_survey().
#' @param digits Integer. Number of decimal places.
#'
#' @return A formatted tibble.
#' @export
format_results_table <- function(results, digits = 2) {
  
  required_cols <- c(
    "variable", "estimator", "estimate", "se",
    "lci", "uci", "conf_level", "n_obs"
  )
  
  missing <- setdiff(required_cols, names(results))
  if (length(missing) > 0) {
    rlang::abort(
      message = paste("Missing required columns:", paste(missing, collapse = ", "))
    )
  }
  
  results |>
    dplyr::mutate(
      dplyr::across(
        c(estimate, se, lci, uci),
        ~ round(.x, digits)
      ),
      conf_level = paste0(conf_level * 100, "%")
    )
}



#' Plot survey estimation results as a bar chart with confidence interval
#'
#' @param results Tibble returned by estimate_survey().
#'
#' @return A ggplot object.
#' @export
plot_results_bar <- function(results) {
  
  required_cols <- c("estimate", "lci", "uci", "variable")
  missing <- setdiff(required_cols, names(results))
  
  if (length(missing) > 0) {
    rlang::abort(
      message = paste("Missing required columns:", paste(missing, collapse = ", "))
    )
  }
  
  ggplot2::ggplot(
    results,
    ggplot2::aes(x = variable, y = estimate)
  ) +
    ggplot2::geom_col(fill = "steelblue", width = 0.6) +
    ggplot2::geom_errorbar(
      ggplot2::aes(ymin = lci, ymax = uci),
      width = 0.2
    ) +
    ggplot2::labs(
      x = NULL,
      y = "Estimate"
    ) +
    ggplot2::theme_minimal()
}
