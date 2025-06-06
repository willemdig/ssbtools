#' Retrieve metadata (variables and codes) for an SSB table
#'
#' This function queries Statistics Norway’s (SSB) JSON-stat API to return
#' metadata for a given table. The metadata includes variable codes,
#' descriptions, and possible values for use in dynamic query construction.
#'
#' @param table_id A string representing the SSB table ID, e.g. `"12030"`.
#' @param language Two-letter language code: `"en"` for English or `"no"` for Norwegian (default: `"en"`).
#'
#' @return A list of variables, each containing:
#'   \itemize{
#'     \item \code{code}: Variable ID used in queries
#'     \item \code{text}: Human-readable label
#'     \item \code{values}: Valid value codes
#'     \item \code{valueTexts}: Human-readable value labels
#'   }
#' @export
#'
#' @examples
#' # Fetch metadata for table 12030 in English
#' meta <- ssb_get_metadata("12030")
#'
#' # Fetch metadata in Norwegian
#' meta_no <- ssb_get_metadata("12030", language = "no")
ssb_get_metadata <- function(table_id, language = "en") {
  # Build metadata URL
  base_url <- paste0("https://data.ssb.no/api/v0/", language, "/table/", table_id)
  
  # Fetch metadata from SSB
  res <- httr::GET(base_url)
  
  # Check response status
  if (res$status_code != 200) {
    stop(glue::glue("Failed to retrieve metadata for table {table_id} (HTTP {res$status_code})"))
  }
  
  # Parse JSON response
  metadata <- jsonlite::fromJSON(httr::content(res, "text", encoding = "UTF-8"))
  
  return(metadata$variables)
}
