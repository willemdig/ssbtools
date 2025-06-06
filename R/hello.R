# Hello, world!
#
# This is an example function named 'hello'
# which prints 'Hello, world!'.
#
# You can learn more about package authoring with RStudio at:
#
#   https://r-pkgs.org
#
# Some useful keyboard shortcuts for package authoring:
#
#   Install Package:           'Ctrl + Shift + B'
#   Check Package:             'Ctrl + Shift + E'
#   Test Package:              'Ctrl + Shift + T'


#' Download or load SSB table as CSV with caching
#'
#' @param table_id The table ID as string, e.g., "12030"
#' @param folder Where to save/read CSV files (default: "csv/ssb")
#' @param json_folder Folder containing query JSON files (default: "JSON")
#'
#' @return A data frame (tibble) from the API or CSV
#' @export
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

