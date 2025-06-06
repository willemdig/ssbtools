# ssbtools

**ssbtools** is a lightweight R package that makes it easy to retrieve, cache, and reuse data from [Statistics Norway (SSB)](https://www.ssb.no)'s JSON-stat API.

It is especially useful when working with saved SSB queries and when you want to avoid re-downloading large datasets unnecessarily.

## Installation (from the R console)

```r
# Install devtools if you haven't already
install.packages("devtools")

# Install ssbtools from GitHub
devtools::install_github("willemdig/ssbtools")
```

## Usage

1. Save your query as a `.json` file via SSB's StatBank.
2. Place the file in a `JSON/` folder inside your project directory.
3. The file must follow this naming format:

```
JSON/ssbapi_table_<table_id>.json
```

**Example:**

```
your-project/
├── JSON/
│   └── ssbapi_table_12030.json
```

4. Use `ssb_get_csv()` in your R script:

```r
library(ssbtools)

df <- ssb_get_csv("12030")
```

This function will:
- Read the query from `JSON/ssbapi_table_12030.json`
- Download fresh data from SSB (only if it has changed since last time)
- Save or reuse the result at `csv/ssb/ssb_table_12030.csv`

## Function Reference

### `ssb_get_csv(table_id)`
Retrieves data from SSB using a saved JSON query file, and caches the result in a CSV. Uses hashing to avoid redundant downloads.

### `ssb_get_metadata(table_id)`
Fetches the full metadata (dimensions and allowed values) for a given SSB table as a list. Useful for inspecting structure before building a query.

### `ssb_get_full_table(table_id)`
Automatically constructs a full query using **all** possible values for all dimensions in a table, and returns the entire dataset (⚠️ may be large).

## Smart Caching

The first time `ssb_get_csv()` or `ssb_get_full_table()` runs, it fetches the dataset and saves it locally.  
On subsequent runs, it checks whether the data has changed using a content-based hash — and only re-downloads if necessary.

## License

This package is licensed under the MIT License and provided without warranty.  
It was developed independently using open public data from Statistics Norway (SSB).
