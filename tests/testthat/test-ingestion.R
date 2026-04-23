test_that("read_survey_data returns tibble with metadata", {
  
  tmp <- tempfile(fileext = ".csv")
  readr::write_csv(tibble::tibble(x = 1:5), tmp)
  
  data <- read_survey_data(tmp)
  
  expect_s3_class(data, "tbl_df")
  expect_equal(attr(data, "n_rows"), 5)
  expect_equal(attr(data, "source_format"), "csv")
})