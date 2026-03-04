build_case_when <- function(x, rules) {
  
  dplyr::case_when(
    !!!purrr::map(rules, function(r) {
      
      cond <- switch(
        r$op,
        lt  = x <  r$v1,
        le  = x <= r$v1,
        gt  = x >  r$v1,
        ge  = x >= r$v1,
        eq  = x == r$v1,
        between = x >= r$v1 & x <= r$v2
      )
      
      rlang::expr(!!cond ~ !!r$label)
    })
  )
}
