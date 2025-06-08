#' Download and cache data from Statistics Norway (SSB) using a saved JSON query
#'
#' @param table_id A string representing the SSB table ID, e.g. "12030".
#' @param folder Folder path for readable CSV files (default: "csv/ssb").
#' @param json_folder Folder path for saved JSON queries (default: "JSON").
#' @param cache_dir Hidden folder path for cache storage (default: ".cache/ssb").
#' @param language Language code: "no" (default) or "en".
#'
#' @return A tibble with data from SSB, either freshly downloaded or cached.
#' @export
ssb_get_csv <- function(table_id,
                        folder = "csv/ssb",
                        json_folder = "JSON",
                        cache_dir = ".cache/ssb",
                        language = "no") {
  
  if (!dir.exists(folder))     dir.create(folder, recursive = TRUE)
  if (!dir.exists(cache_dir))  dir.create(cache_dir, recursive = TRUE)
  
  # Paths and request body
  json_path <- file.path(json_folder, paste0("ssbapi_table_", table_id, ".json"))
  url       <- paste0("https://data.ssb.no/api/v0/", language, "/table/", table_id, "/")
  
  query_obj <- jsonlite::read_json(json_path)$queryObj
  request_body <- list(query = query_obj, response = list(format = "json-stat2"))
  body_hash    <- digest::digest(request_body)
  
  # Cache paths
  cache_csv  <- file.path(cache_dir, paste0("ssb_", table_id, "_", body_hash, ".csv"))
  cache_hash <- file.path(cache_dir, paste0("ssb_", table_id, "_", body_hash, ".hash"))
  
  # Readable output CSV
  output_csv <- file.path(folder, paste0("ssb_table_", table_id, ".csv"))
  
  # Fetch data
  res       <- httr::POST(url, body = request_body, encode = "json")
  raw_text  <- httr::content(res, as = "text", encoding = "UTF-8")
  new_hash  <- digest::digest(raw_text)
  
  # Cache hit
  if (file.exists(cache_hash)) {
    old_hash <- readLines(cache_hash, warn = FALSE)
    if (new_hash == old_hash && file.exists(cache_csv)) {
      message(glue::glue("✔ Table {table_id}: no change — loading from cache"))
      file.copy(cache_csv, output_csv, overwrite = TRUE)
      return(readr::read_csv(output_csv, show_col_types = FALSE))
    }
  }
  
  # Cache miss: write updated CSV and hash
  df <- rjstat::fromJSONstat(raw_text)
  readr::write_csv(df, cache_csv)
  readr::write_csv(df, output_csv)
  writeLines(new_hash, cache_hash)
  message(glue::glue("⬇ Table {table_id}: data updated and saved to cache and CSV"))
  
  return(df)
}
