#' Fetch the full SSB table by requesting all combinations of values (with smart caching)
#'
#' @param table_id Table number, e.g. "12030"
#' @param language Language code: "no" (default) or "en"
#' @param cache_dir Directory to store cache files (default: ".cache/ssb")
#'
#' @return A data frame with all data from the table (from API or cache)
#' @export
ssb_get_full_table <- function(table_id, language = "no", cache_dir = ".cache/ssb") {
  if (!dir.exists(cache_dir)) dir.create(cache_dir, recursive = TRUE)
  
  message(glue::glue("🔄 Henter alle data fra SSB-tabell {table_id} ({language})"))
  
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
  
  # Hash the full request body to use as a cache key
  query_hash <- digest::digest(body)
  csv_path   <- file.path(cache_dir, paste0("ssb_full_", table_id, "_", query_hash, ".csv"))
  hash_path  <- file.path(cache_dir, paste0("ssb_full_", table_id, "_", query_hash, ".hash"))
  
  # Send request and compute hash
  res <- httr::POST(url_meta, body = body, encode = "json")
  raw_text <- httr::content(res, as = "text", encoding = "UTF-8")
  new_hash <- digest::digest(raw_text)
  
  # If unchanged, load cached data
  if (file.exists(hash_path)) {
    old_hash <- readLines(hash_path, warn = FALSE)
    if (new_hash == old_hash && file.exists(csv_path)) {
      message("✔ Ingen endringer – laster fra cache")
      return(readr::read_csv(csv_path, show_col_types = FALSE))
    }
  }
  
  # If changed or no cache, save everything
  df <- rjstat::fromJSONstat(raw_text)
  readr::write_csv(df, csv_path)
  writeLines(new_hash, hash_path)
  message("⬇ Data oppdatert og lagret i cache")
  
  return(df)
}
