test_that("add_survey_variables creates new variables", {
  
  data <- tibble::tibble(
    ingreso = c(100, 200),
    miembros = c(2, 4)
  )
  
  out <- add_survey_variables(
    data,
    definitions = list(
      ingreso_pc = ~ ingreso / miembros
    )
  )
  
  expect_true("ingreso_pc" %in% names(out))
  expect_equal(out$ingreso_pc, c(50, 50))
})
