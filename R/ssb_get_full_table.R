#' Fetch the full SSB table by requesting all combinations of values
#'
#' @param table_id Table number, e.g. "12030"
#'
#' @return A data frame with all data from the table
#' @export
ssb_get_full_table <- function(table_id) {
  message(glue::glue("🔄 Attempting to fetch ALL data from SSB table {table_id}"))
  
  url_meta <- paste0("https://data.ssb.no/api/v0/no/table/", table_id)
  meta_res <- httr::GET(url_meta)
  meta <- httr::content(meta_res, as = "parsed")
  
  # Build a query with "all" values for each variable
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
  
  res <- httr::POST(url_meta, body = body, encode = "json")
  raw_text <- httr::content(res, as = "text", encoding = "UTF-8")
  
  df <- rjstat::fromJSONstat(raw_text)
  return(df)
}
