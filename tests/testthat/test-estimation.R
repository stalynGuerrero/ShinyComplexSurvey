test_that("estimate_survey computes mean correctly", {
  
  data <- tibble::tibble(
    w = c(1, 1, 1, 1),
    y = c(10, 20, 30, 40),
    region = c("A", "A", "B", "B")
  )
  
  design <- as_survey_design_tbl(
    data,
    weight = "w"
  )
  
  res <- estimate_survey(
    design = design,
    variable = "y",
    estimator = "mean"
  )
  
  expect_s3_class(res, "tbl_df")
  expect_true(all(c("estimate","se","cv","lci","uci") %in% names(res)))
  
  expect_equal(res$estimate, mean(data$y))
  expect_true(res$lci < res$estimate)
  expect_true(res$uci > res$estimate)
})

test_that("estimate_survey works with domains", {
  
  data <- tibble::tibble(
    w = c(1, 1, 1, 1),
    y = c(10, 20, 30, 40),
    region = c("A", "A", "B", "B")
  )
  
  design <- as_survey_design_tbl(data, weight = "w")
  
  res <- estimate_survey(
    design,
    variable = "y",
    estimator = "mean",
    by = "region"
  )
  
  expect_equal(nrow(res), 2)
})