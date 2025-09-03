# mod_logging.R
# Registro de eventos simple (JSON lines) en carpeta logs/
log_event <- function(action, user = 'local', details = list()){ 
  dir.create('logs', showWarnings = FALSE)
  entry <- list(time = format(Sys.time(), tz = 'UTC'), user = user, action = action, details = details)
  con <- file('logs/app_log.jsonl', open = 'a')
  writeLines(jsonlite::toJSON(entry, auto_unbox = TRUE), con)
  close(con)
}
