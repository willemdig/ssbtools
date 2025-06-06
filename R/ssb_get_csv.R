#' Download and cache data from Statistics Norway (SSB)
#'
#' Downloads a table from the SSB StatBank API using a saved JSON query,
#' stores it as a CSV file, and caches the result using a content hash to
#' avoid redundant API calls.
#'
#' The function checks if the previously downloaded content has changed.
#' If unchanged, it loads the data from the existing CSV instead of
#' querying the API again.
#'
#' @param table_id A string representing the SSB table ID, e.g. `"12030"`.
#' @param folder Folder path where CSV files are stored (default: `"csv/ssb"`).
#' @param json_folder Folder path where saved JSON query files are stored (default: `"JSON"`).
#'
#' @return A tibble containing the data from SSB, either freshly downloaded or cached.
#' @export
#'
#' @examples
#' # Example usage (requires JSON/ssbapi_table_12030.json to exist):
#' df <- ssb_get_csv("12030")
ssb_get_csv <- function(table_id,
                        folder = "csv/ssb",
                        json_folder = "JSON") {
  
  # Ensure output folder exists
  if (!dir.exists(folder)) dir.create(folder, recursive = TRUE)
  
  # Construct paths
  json_path  <- file.path(json_folder, paste0("ssbapi_table_", table_id, ".json"))
  url        <- paste0("https://data.ssb.no/api/v0/en/table/", table_id, "/")
  csv_path   <- file.path(folder, paste0("ssb_table_", table_id, ".csv"))
  hash_path  <- file.path(folder, paste0("ssb_table_", table_id, ".hash"))
  
  # Read query and fetch response
  query_obj <- read_json(json_path)$queryObj
  res       <- POST(url, body = query_obj, encode = "json")
  raw_text  <- content(res, as = "text", encoding = "UTF-8")
  
  # Compute hash of the current API result
  new_hash <- digest(raw_text)
  
  # Compare with existing hash, if available
  if (file.exists(hash_path)) {
    old_hash <- readLines(hash_path, warn = FALSE)
    if (new_hash == old_hash) {
      message(glue::glue("✔ Table {table_id}: no change — using cached CSV"))
      return(read_csv(csv_path, show_col_types = FALSE))
    }
  }
  
  # If hash differs or no hash file, update everything
  df <- fromJSONstat(raw_text)
  write_csv(df, csv_path)
  writeLines(new_hash, hash_path)
  message(glue::glue("⬇ Table {table_id}: data updated and written to CSV"))
  
  return(df)
}
