test_that("build_survey_design creates a tbl_svy object", {
  
  data <- tibble::tibble(
    w = c(1, 2, 1.5),
    strata = c(1, 1, 2),
    psu = c(1, 2, 3),
    y = c(10, 20, 30)
  )
  
  design <- build_survey_design(
    data,
    weight = "w",
    strata = "strata",
    cluster = "psu"
  )
  
  expect_s3_class(design, "tbl_svy")
})
