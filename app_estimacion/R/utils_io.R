# utils_io.R
read_any <- function(path, ext = tools::file_ext(path)){
  ext <- tolower(ext)
  switch(ext,
         rds = readRDS(path),
         rdata = { e <- new.env(); load(path, envir = e); e[[ls(e)[1]]] },
         csv = readr::read_csv(path, show_col_types = FALSE),
         txt = readr::read_delim(path, delim = '	', show_col_types = FALSE),
         dta = haven::read_dta(path),
         xlsx = readxl::read_xlsx(path),
         xls = readxl::read_xls(path),
         sas7bdat = haven::read_sas(path),
         stop('Formato no soportado: ', ext)
  )
}

clean_haven <- function(df){
  df <- df %>% 
    mutate(across(where(haven::is.labelled), haven::as_factor))
  return(df)
}
