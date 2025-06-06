#' ssbtools: Tools for accessing and caching data from Statistics Norway (SSB)
#'
#' This package simplifies downloading, caching, and working with data
#' from [SSB StatBank](https://www.ssb.no/en/statbank). You can save
#' your JSON queries from the SSB web UI and load them directly via
#' `ssb_get_csv()` or pull the entire dataset with `ssb_get_full_table()`.
#'
#' @import httr jsonlite rjstat digest readr glue
#' @seealso \code{\link{ssb_get_csv}}, \code{\link{ssb_get_full_table}}, \code{\link{ssb_get_metadata}}
#' @keywords package
"_PACKAGE"
