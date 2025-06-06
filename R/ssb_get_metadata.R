#' Fetch metadata (variables and codes) for a given SSB table
#'
#' @param table_id The SSB table ID (e.g., "12030")
#' @param language Two-letter code: "en" (English) or "no" (Norwegian). Default: "en"
#'
#' @return A list of variables with their codes and allowed values
#' @export
ssb_get_metadata <- function(table_id, language = "en") {
  library(httr)
  library(jsonlite)
  
  # Build metadata URL
  base_url <- paste0("https://data.ssb.no/api/v0/", language, "/table/", table_id)
  
  # Try to fetch the metadata
  res <- GET(base_url)
  
  if (res$status_code != 200) {
    stop(glue::glue("Failed to retrieve metadata for table {table_id} (HTTP {res$status_code})"))
  }
  
  metadata <- fromJSON(content(res, "text", encoding = "UTF-8"))
  
  # Return only the variable section
  return(metadata$variables)
}
