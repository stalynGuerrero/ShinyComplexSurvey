test_that("format_results_table returns formatted tibble", {
  
  res <- tibble::tibble(
    variable = "y",
    estimator = "mean",
    estimate = 10.1234,
    se = 1.234,
    lci = 8.1,
    uci = 12.9,
    conf_level = 0.95,
    n_obs = 100
  )
  
  out <- format_results_table(res, digits = 1)
  
  expect_equal(out$estimate, 10.1)
  expect_equal(out$conf_level, "95%")
})
