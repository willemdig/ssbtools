#' Download and cache data from Statistics Norway (SSB)
#'
#' Downloads a table from the SSB StatBank API using a saved JSON query,
#' stores it as a CSV file, and caches the result using a content hash to
#' avoid redundant API calls. Caches are stored in a hidden directory.
#'
#' @param table_id A string representing the SSB table ID, e.g. `"12030"`.
#' @param folder Folder path where readable CSV files are stored (default: `"csv/ssb"`).
#' @param json_folder Folder path where saved JSON query files are stored (default: `"JSON"`).
#' @param cache_dir Folder path for cache (default: `".cache/ssb"`)
#' @param language The language code for the API query. Either `"no"` (default) or `"en"`.
#'
#' @return A tibble containing the data from SSB, either freshly downloaded or cached.
#' @export
#'
#' @examples
#' df <- ssb_get_csv("12030")
#' df_en <- ssb_get_csv("12030", language = "en")
ssb_get_csv <- function(table_id,
                        folder = "csv/ssb",
                        json_folder = "JSON",
                        cache_dir = ".cache/ssb",
                        language = "no") {
  
  # Ensure folders exist
  if (!dir.exists(folder))     dir.create(folder, recursive = TRUE)
  if (!dir.exists(cache_dir))  dir.create(cache_dir, recursive = TRUE)
  
  # Paths
  json_path <- file.path(json_folder, paste0("ssbapi_table_", table_id, ".json"))
  url       <- glue::glue("https://data.ssb.no/api/v0/{language}/table/{table_id}/")
  
  query_obj <- jsonlite::read_json(json_path)$queryObj
  request_body <- list(query = query_obj, response = list(format = "json-stat2"))
  body_hash <- digest::digest(request_body)
  
  # Cache file paths
  cache_csv  <- file.path(cache_dir, paste0("ssb_", table_id, "_", body_hash, ".csv"))
  cache_hash <- file.path(cache_dir, paste0("ssb_", table_id, "_", body_hash, ".hash"))
  
  # User-facing CSV path
  output_csv <- file.path(folder, paste0("ssb_table_", table_id, ".csv"))
  
  # Fetch from API
  res       <- httr::POST(url, body = request_body, encode = "json")
  raw_text  <- httr::content(res, as = "text", encoding = "UTF-8")
  new_hash  <- digest::digest(raw_text)
  
  # Load from cache if no change
  if (file.exists(cache_hash)) {
    old_hash <- readLines(cache_hash, warn = FALSE)
    if (new_hash == old_hash && file.exists(cache_csv)) {
      message(glue::glue("✔ Tabell {table_id}: ingen endring — bruker cache"))
      file.copy(cache_csv, output_csv, overwrite = TRUE)
      return(readr::read_csv(output_csv, show_col_types = FALSE))
    }
  }
  
  # Save new data
  df <- rjstat::fromJSONstat(raw_text)
  readr::write_csv(df, cache_csv)
  readr::write_csv(df, output_csv)
  writeLines(new_hash, cache_hash)
  message(glue::glue("⬇ Tabell {table_id}: data oppdatert og skrevet til cache og CSV"))
  
  return(df)
}
