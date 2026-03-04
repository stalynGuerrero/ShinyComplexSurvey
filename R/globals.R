# Global variable bindings for NSE (Non-Standard Evaluation)
# Required to avoid R CMD check notes related to dplyr/srvyr/ggplot2 usage

utils::globalVariables(c(
  
  # Common tidy evaluation pronouns
  ".data",
  ".ind",
  
  # Survey design variables
  "estrato",
  "upm",
  "w",
  
  # Sociodemographic variables (example dataset)
  "sexo",
  "region",
  "etnia",
  "dam",
  "ingreso",
  "miembros",
  
  # Estimation outputs
  "estimate",
  "se",
  "cv",
  "lci",
  "uci",
  "estimate_se",
  "estimate_cv",
  "estimator",
  "variable",
  "ic",
  
  # Ratio-specific variables
  "ratio_num_level",
  "ratio_den_level",
  
  # Helper variables used inside pipelines
  "n_distinct"
))

# Explicit imports required by R CMD check

#' @importFrom stats coef vcov update weights rlnorm runif
#' @importFrom utils head
#' @importFrom magrittr %>%
#' @importFrom dplyr n_distinct
NULL