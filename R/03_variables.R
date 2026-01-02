#' Add derived variables to survey data
#'
#' @param data Tibble with survey microdata.
#' @param definitions Named list of formulas defining new variables.
#'
#' @return Tibble with new variables added.
#' @export
add_survey_variables <- function(data, definitions) {
  
  if (!tibble::is_tibble(data)) {
    rlang::abort("`data` must be a tibble.")
  }
  
  if (!is.list(definitions) || is.null(names(definitions))) {
    rlang::abort("`definitions` must be a named list.")
  }
  
  if (any(names(definitions) == "")) {
    rlang::abort("All variable definitions must be named.")
  }
  
  # convertir fórmulas ~ expr en expresiones evaluables
  quos <- purrr::imap(
    definitions,
    function(def, name) {
      
      if (!inherits(def, "formula")) {
        rlang::abort(
          message = paste("Definition for", name, "must be a formula (~ expr).")
        )
      }
      
      rlang::new_quosure(
        rlang::f_rhs(def),
        env = rlang::caller_env()
      )
    }
  )
  
  dplyr::mutate(data, !!!quos)
}
