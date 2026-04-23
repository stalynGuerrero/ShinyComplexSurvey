#' Read survey microdata from multiple file formats
#'
#' Reads microdata commonly used in official statistics and survey analysis
#' from a local file path. Supported formats include CSV, Excel, SPSS, Stata,
#' and R serialized objects (RDS).
#'
#' The function returns a tibble and attaches source metadata as attributes,
#' facilitating traceability and reproducibility in downstream workflows.
#'
#' @param path Character. File path to the dataset.
#' @param col_types Optional. Passed to \code{readr::read_csv()}.
#' @param guess_max Integer. Maximum rows used for type guessing (CSV only).
#' @param encoding Character. File encoding (CSV only). Default \code{"UTF-8"}.
#'
#' @return A tibble with attributes:
#' \itemize{
#'   \item \code{source_path}: normalized file path
#'   \item \code{source_format}: file extension
#'   \item \code{n_rows}: number of rows
#'   \item \code{n_cols}: number of columns
#' }
#'
#' @details
#' Supported formats:
#' \itemize{
#'   \item \code{.csv} via \code{readr}
#'   \item \code{.xlsx} via \code{readxl}
#'   \item \code{.sav} via \code{haven} (SPSS)
#'   \item \code{.dta} via \code{haven} (Stata)
#'   \item \code{.rds} via base R
#' }
#'
#' The function ensures the output is a tibble and preserves metadata
#' for reproducibility. For large files, consider pre-specifying column
#' types to avoid costly type inference.
#'
#' @examples
#' \dontrun{
#' # CSV
#' df <- read_survey_data("data/sample.csv")
#'
#' # SPSS
#' df <- read_survey_data("data/sample.sav")
#'
#' # Inspect metadata
#' attr(df, "source_path")
#' attr(df, "n_rows")
#' }
#'
#' @export
read_survey_data <- function(
    path,
    col_types = NULL,
    guess_max = 10000,
    encoding = "UTF-8"
) {
  
  # ---------------------------------------------------------
  # 1. Input validation
  # ---------------------------------------------------------
  if (!is.character(path) || length(path) != 1) {
    rlang::abort("`path` must be a single character string.")
  }
  
  if (!file.exists(path)) {
    rlang::abort(
      message = paste("File does not exist:", path),
      class = "shinycomplexsurvey_file_not_found"
    )
  }
  
  ext <- tolower(tools::file_ext(path))
  
  # ---------------------------------------------------------
  # 2. Reader dispatch
  # ---------------------------------------------------------
  data <- switch(
    ext,
    "csv" = readr::read_csv(
      path,
      col_types = col_types,
      guess_max = guess_max,
      locale = readr::locale(encoding = encoding),
      show_col_types = FALSE,
      progress = FALSE
    ),
    
    "xlsx" = readxl::read_xlsx(path),
    
    "sav" = haven::read_sav(path),
    
    "dta" = haven::read_dta(path),
    
    "rds" = readRDS(path),
    
    rlang::abort(
      message = paste0("Unsupported file format: .", ext),
      class = "shinycomplexsurvey_unsupported_format"
    )
  )
  
  # ---------------------------------------------------------
  # 3. Coercion to tibble
  # ---------------------------------------------------------
  if (!tibble::is_tibble(data)) {
    data <- tibble::as_tibble(data)
  }
  
  # ---------------------------------------------------------
  # 4. Metadata
  # ---------------------------------------------------------
  attr(data, "source_path")   <- normalizePath(path, winslash = "/", mustWork = FALSE)
  attr(data, "source_format") <- ext
  attr(data, "n_rows")        <- nrow(data)
  attr(data, "n_cols")        <- ncol(data)
  
  # ---------------------------------------------------------
  # 5. Return
  # ---------------------------------------------------------
  data
}