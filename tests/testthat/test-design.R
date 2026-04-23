test_that("as_survey_design_tbl creates a valid tbl_svy object", {
  
  data <- tibble::tibble(
    w = c(1, 2, 1.5),
    strata = c(1, 1, 2),
    psu = c(1, 2, 3),
    y = c(10, 20, 30)
  )
  
  design <- as_survey_design_tbl(
    data,
    weight = "w",
    strata = "strata",
    cluster = "psu"
  )
  
  # clase
  expect_s3_class(design, "tbl_svy")
  
  # metadata
  meta <- attr(design, "design_vars")
  expect_equal(meta$weight, "w")
  expect_equal(meta$strata, "strata")
  expect_equal(meta$cluster, "psu")
  
  # dimensiones
  expect_equal(nrow(design$variables), 3)
})