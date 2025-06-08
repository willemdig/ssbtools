#' Download and cache data from Statistics Norway (SSB)
#'
#' Downloads a table from the SSB StatBank API using a saved JSON query,
#' stores it as a CSV file, and caches the result using a content hash to
#' avoid redundant API calls.
#'
#' @param table_id A string representing the SSB table ID, e.g. `"12030"`.
#' @param folder Folder path where CSV files are stored (default: `"csv/ssb"`).
#' @param json_folder Folder path where saved JSON query files are stored (default: `"JSON"`).
#' @param cache_dir Folder path for hash cache (default: `.cache/ssb`).
#' @param language The language code for the API query. Either `"no"` (default) or `"en"`.
#'
#' @return A tibble containing the data from SSB, either freshly downloaded or cached.
#' @export
ssb_get_csv <- function(table_id,
                        folder = "csv/ssb",
                        json_folder = "JSON",
                        cache_dir = ".cache/ssb",
                        language = "no") {
  
  if (!dir.exists(folder))    dir.create(folder, recursive = TRUE)
  if (!dir.exists(cache_dir)) dir.create(cache_dir, recursive = TRUE)
  
  # Paths
  json_path  <- file.path(json_folder, paste0("ssbapi_table_", table_id, ".json"))
  url        <- paste0("https://data.ssb.no/api/v0/", language, "/table/", table_id, "/")
  csv_path   <- file.path(folder, paste0("ssb_table_", table_id, ".csv"))
  hash_path  <- file.path(cache_dir, paste0("ssb_table_", table_id, ".hash"))
  
  # Read saved JSON and validate
  query_obj <- tryCatch({
    parsed <- jsonlite::read_json(json_path, simplifyVector = FALSE)
    obj <- parsed[["queryObj"]]
    if (!is.list(obj)) stop("queryObj is not a list")
    obj
  }, error = function(e) {
    stop(glue::glue("❌ Could not load or parse JSON file for table {table_id}: {e$message}"))
  })
  
  # Send API request
  res <- tryCatch({
    httr::POST(url, body = query_obj, encode = "json")
  }, error = function(e) {
    stop(glue::glue("❌ API request failed for table {table_id}: {e$message}"))
  })
  
  raw_text <- httr::content(res, as = "text", encoding = "UTF-8")
  new_hash <- digest::digest(raw_text)
  
  # Load from cache if same hash
  if (file.exists(hash_path)) {
    old_hash <- readLines(hash_path, warn = FALSE)
    if (new_hash == old_hash && file.exists(csv_path)) {
      message(glue::glue("✔ Table {table_id}: no change — using cached CSV"))
      return(readr::read_csv(csv_path, show_col_types = FALSE))
    }
  }
  
  # Parse response
  df_parsed <- tryCatch({
    rjstat::fromJSONstat(raw_text)
  }, error = function(e) {
    stop(glue::glue("❌ Could not parse JSON-stat response: {e$message}"))
  })
  
  df <- if (is.data.frame(df_parsed)) {
    df_parsed
  } else if (is.list(df_parsed) && is.data.frame(df_parsed[[1]])) {
    df_parsed[[1]]
  } else {
    stop(glue::glue("❌ Unexpected format returned by fromJSONstat(): {class(df_parsed)}"))
  }
  
  # Save to disk
  readr::write_csv(df, csv_path)
  writeLines(new_hash, hash_path)
  message(glue::glue("⬇ Table {table_id}: data updated and written to CSV"))
  
  return(df)
}
