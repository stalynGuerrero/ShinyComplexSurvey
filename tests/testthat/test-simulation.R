test_that("simulation passes validation", {
  
  data <- generate_example_data(n_upm = 20, seed = 123)
  res <- validate_simulation(data)
  
  expect_true(all(res$passed))
})