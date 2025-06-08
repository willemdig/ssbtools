ssb_get_csv <- function(table_id,
                        folder = "csv/ssb",
                        json_folder = "JSON",
                        language = "no") {
  
  if (!dir.exists(folder)) dir.create(folder, recursive = TRUE)
  
  json_path  <- file.path(json_folder, paste0("ssbapi_table_", table_id, ".json"))
  url        <- paste0("https://data.ssb.no/api/v0/", language, "/table/", table_id, "/")
  csv_path   <- file.path(folder, paste0("ssb_table_", table_id, ".csv"))
  hash_path  <- file.path(folder, paste0("ssb_table_", table_id, ".hash"))
  
  query_obj <- jsonlite::read_json(json_path)$queryObj
  res       <- httr::POST(url, body = query_obj, encode = "json")
  raw_text  <- httr::content(res, as = "text", encoding = "UTF-8")
  new_hash  <- digest::digest(raw_text)
  
  if (file.exists(hash_path)) {
    old_hash <- readLines(hash_path, warn = FALSE)
    if (new_hash == old_hash && file.exists(csv_path)) {
      message(glue::glue("✔ Table {table_id}: no change — using cached CSV"))
      return(readr::read_csv(csv_path, show_col_types = FALSE))
    }
  }
  
  df_parsed <- rjstat::fromJSONstat(raw_text)
  df <- if (is.data.frame(df_parsed)) {
    df_parsed
  } else if (is.list(df_parsed) && is.data.frame(df_parsed[[1]])) {
    df_parsed[[1]]
  } else {
    stop(glue::glue("❌ Unexpected format returned by fromJSONstat(): {class(df_parsed)}"))
  }
  
  readr::write_csv(df, csv_path)
  writeLines(new_hash, hash_path)
  message(glue::glue("⬇ Table {table_id}: data updated and written to CSV"))
  
  return(df)
}
