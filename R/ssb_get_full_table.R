#' Fetch full table from SSB using table ID (all variables, all values)
#'
#' @param table_id The table ID as a string (e.g. "12030")
#' @param language "en" (English) or "no" (Norwegian). Default is "en"
#'
#' @return A data frame containing the full table (or as much as SSB allows)
#' @export
ssb_get_full_table <- function(table_id, language = "en") {
  library(httr)
  library(jsonlite)
  library(rjstat)
  library(glue)
  
  message(glue("⚠ Attempting to fetch ALL data from SSB table {table_id} — may take time or fail if table is large."))
  
  # Step 1: Fetch metadata
  metadata_url <- paste0("https://data.ssb.no/api/v0/", language, "/table/", table_id)
  meta_res <- GET(metadata_url)
  if (meta_res$status_code != 200) {
    stop(glue("Failed to retrieve metadata for table {table_id} (HTTP {meta_res$status_code})"))
  }
  metadata <- fromJSON(content(meta_res, "text", encoding = "UTF-8"))
  
  # Step 2: Build query object using all values for each variable
  query_obj <- list(
    query = lapply(metadata$variables, function(var) {
      list(
        code = var$code,
        selection = list(
          filter = "item",
          values = var$values
        )
      )
    }),
    response = list(format = "json-stat2")
  )
  
  # Step 3: Send POST request with full query
  query_url <- paste0("https://data.ssb.no/api/v0/", language, "/table/", table_id)
  res <- POST(query_url, body = query_obj, encode = "json")
  if (res$status_code != 200) {
    stop(glue("Failed to retrieve data from table {table_id} (HTTP {res$status_code})"))
  }
  
  # Step 4: Parse JSON-stat response
  df <- fromJSONstat(content(res, "text", encoding = "UTF-8"))
  
  return(df)
}
