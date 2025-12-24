test_that("estimate_survey computes a mean correctly", {
  
  data <- tibble::tibble(
    w = c(1, 1, 1, 1),
    y = c(10, 20, 30, 40)
  )
  
  design <- build_survey_design(
    data,
    weight = "w"
  )
  
  res <- estimate_survey(
    design = design,
    variable = "y",
    estimator = "mean"
  )
  
  expect_s3_class(res, "tbl_df")
  expect_equal(res$estimate, mean(data$y))
  expect_true(res$lci < res$estimate)
  expect_true(res$uci > res$estimate)
})
