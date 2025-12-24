#' Load survey microdata from different formats
#'
#' @param path Character. Path to the data file.
#'
#' @return A tibble with source metadata stored as attributes.
#' @export
load_survey_data <- function(path) {
  
  if (!file.exists(path)) {
    rlang::abort(
      message = paste("File does not exist:", path),
      class = "shinycomplexsurvey_file_not_found"
    )
  }
  
  ext <- tools::file_ext(path) |>
    stringr::str_to_lower()
  
  data <- dplyr::case_when(
    ext == "csv"  ~ list(readr::read_csv(path, show_col_types = FALSE)),
    ext == "xlsx" ~ list(readxl::read_xlsx(path)),
    ext == "sav"  ~ list(haven::read_sav(path)),
    ext == "dta"  ~ list(haven::read_dta(path)),
    ext == "rds"  ~ list(readRDS(path)),
    TRUE ~ list(
      rlang::abort(
        message = paste("Unsupported file format: .", ext),
        class = "shinycomplexsurvey_unsupported_format"
      )
    )
  )[[1]]
  
  if (!tibble::is_tibble(data)) {
    data <- tibble::as_tibble(data)
  }
  
  attr(data, "source_path")   <- normalizePath(path)
  attr(data, "source_format") <- ext
  attr(data, "n_rows")        <- nrow(data)
  attr(data, "n_cols")        <- ncol(data)
  
  data
}
