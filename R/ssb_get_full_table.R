#' Fetch the full SSB table by requesting all combinations of values (with smart caching)
#'
#' @param table_id Table number, e.g. "12030"
#' @param language Language code: "no" (default) or "en"
#' @param cache_dir Directory to store internal cache files (default: ".cache/ssb")
#' @param folder Directory to store the user-facing CSV file (default: "csv/ssb")
#'
#' @return A data frame with all data from the table (from API or cache)
#' @export
ssb_get_full_table <- function(table_id,
                               language = "no",
                               cache_dir = ".cache/ssb",
                               folder = "csv/ssb") {
  if (!dir.exists(cache_dir)) dir.create(cache_dir, recursive = TRUE)
  if (!dir.exists(folder))    dir.create(folder, recursive = TRUE)
  
  message(glue::glue("🔄 Fetching full data from SSB table {table_id} ({language})"))
  
  url_meta <- glue::glue("https://data.ssb.no/api/v0/{language}/table/{table_id}")
  meta_res <- httr::GET(url_meta)
  meta <- httr::content(meta_res, as = "parsed")
  
  # Build full query
  query_list <- lapply(meta$variables, function(var) {
    list(
      code = var$code,
      selection = list(
        filter = "item",
        values = var$values
      )
    )
  })
  
  body <- list(
    query = query_list,
    response = list(format = "json-stat2")
  )
  
  # Hash to identify unique API request
  query_hash <- digest::digest(body)
  cache_csv  <- file.path(cache_dir, paste0("ssb_full_", table_id, "_", query_hash, ".csv"))
  hash_path  <- file.path(cache_dir, paste0("ssb_full_", table_id, "_", query_hash, ".hash"))
  
  # User-facing export path
  output_csv <- file.path(folder, paste0("ssb_table_", table_id, "_full.csv"))
  
  # Fetch and hash content
  res <- httr::POST(url_meta, body = body, encode = "json")
  raw_text <- httr::content(res, as = "text", encoding = "UTF-8")
  new_hash <- digest::digest(raw_text)
  
  # Use cached CSV if data hasn't changed
  if (file.exists(hash_path)) {
    old_hash <- readLines(hash_path, warn = FALSE)
    if (new_hash == old_hash && file.exists(cache_csv)) {
      message("✔ No change – loading from cache")
      file.copy(cache_csv, output_csv, overwrite = TRUE)
      return(readr::read_csv(output_csv, show_col_types = FALSE))
    }
  }
  
  # Save fresh data to both locations
  df <- rjstat::fromJSONstat(raw_text)
  readr::write_csv(df, cache_csv)
  readr::write_csv(df, output_csv)
  writeLines(new_hash, hash_path)
  message("⬇ Data updated and saved to cache and CSV")
  
  return(df)
}
