test_that("mutate_survey_data works correctly", {
  
  data <- tibble::tibble(
    ingreso = c(100, 200),
    miembros = c(2, 4)
  )
  
  res <- mutate_survey_data(
    data,
    list(
      ingreso_pc = ~ ingreso / miembros
    )
  )
  
  expect_true("ingreso_pc" %in% names(res))
  expect_equal(res$ingreso_pc, c(50, 50))
})