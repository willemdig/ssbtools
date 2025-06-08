#' Fetch and cache SSB table from saved JSON query
#'
#' @param table_id Table number, e.g. "12030"
#' @param folder Output folder for the user-facing CSV (default: "csv/ssb")
#' @param json_folder Folder where the saved JSON query is stored (default: "JSON")
#' @param cache_dir Internal cache directory for hash and versioned CSV (default: ".cache/ssb")
#' @param language Language for API URL, default "no"
#'
#' @return A data frame with data from the table (cached or freshly downloaded)
#' @export
ssb_get_csv <- function(table_id,
                        folder = "csv/ssb",
                        json_folder = "JSON",
                        cache_dir = ".cache/ssb",
                        language = "no") {
  
  if (!dir.exists(folder)) dir.create(folder, recursive = TRUE)
  if (!dir.exists(cache_dir)) dir.create(cache_dir, recursive = TRUE)
  
  json_path <- file.path(json_folder, paste0("ssbapi_table_", table_id, ".json"))
  url       <- paste0("https://data.ssb.no/api/v0/", language, "/table/", table_id, "/")
  query_obj <- jsonlite::read_json(json_path)$queryObj
  
  # Use full POST body to compute query hash
  full_body <- list(query = query_obj, response = list(format = "json-stat2"))
  query_hash <- digest::digest(full_body)
  
  # Define cache and output paths
  cache_csv  <- file.path(cache_dir, paste0("ssb_query_", table_id, "_", query_hash, ".csv"))
  hash_path  <- file.path(cache_dir, paste0("ssb_query_", table_id, "_", query_hash, ".hash"))
  output_csv <- file.path(folder, paste0("ssb_table_", table_id, ".csv"))
  
  # Submit request
  res <- httr::POST(url, body = full_body, encode = "json")
  raw_text <- httr::content(res, as = "text", encoding = "UTF-8")
  new_hash <- digest::digest(raw_text)
  
  # If unchanged, load from cache
  if (file.exists(hash_path)) {
    old_hash <- readLines(hash_path, warn = FALSE)
    if (new_hash == old_hash && file.exists(cache_csv)) {
      message(glue::glue("✔ Table {table_id}: no change — using cached CSV"))
      file.copy(cache_csv, output_csv, overwrite = TRUE)
      return(readr::read_csv(output_csv, show_col_types = FALSE))
    }
  }
  
  # Parse the JSON-stat response
  df_parsed <- rjstat::fromJSONstat(raw_text)
  df <- if (is.data.frame(df_parsed)) {
    df_parsed
  } else if (is.list(df_parsed) && is.data.frame(df_parsed[[1]])) {
    df_parsed[[1]]
  } else {
    stop(glue::glue("❌ Unexpected format returned by fromJSONstat(): {class(df_parsed)}"))
  }
  
  # Save cache and output
  readr::write_csv(df, cache_csv)
  readr::write_csv(df, output_csv)
  writeLines(new_hash, hash_path)
  message(glue::glue("⬇ Table {table_id}: data updated and written to CSV"))
  
  return(df)
}
