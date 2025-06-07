# ssbtools

**ssbtools** is a lightweight R package that simplifies retrieving, caching, and reusing data from [Statistics Norway (SSB)](https://www.ssb.no)'s JSON-stat API.

It is especially useful when working with saved queries from SSB's StatBank and when you want to avoid re-downloading large datasets unnecessarily.

## Installation (from the R console)

```r
# Install devtools if you haven't already
install.packages("devtools")

# Install ssbtools from GitHub
devtools::install_github("willemdig/ssbtools")
```

## Usage

### `ssb_get_csv(table_id)`
1. Save your query as a `.json` file from [SSB StatBank](https://www.ssb.no/en/statbank).
(Alternatively, if you know the data table, you can get queries from [https://data.ssb.no/api/v0/no/console](https://data.ssb.no/api/v0/no/console))
3. Place the file inside a `JSON/` folder in your project directory.
4. Use this naming format for the file:

```
JSON/ssbapi_table_<table_id>.json
```

**Example directory structure:**

```
your-project/
├── JSON/
│   └── ssbapi_table_12030.json
```

4. In your R script:

```r
library(ssbtools)

df <- ssb_get_csv("12030")
```

This will:
- Load the query from `JSON/ssbapi_table_12030.json`
- Download fresh data from SSB (only if the content has changed)
- Save or reuse the result at `csv/ssb/ssb_table_12030.csv`

## Function Reference

### `ssb_get_csv(table_id)`
Retrieves data from SSB using a saved JSON query file, and caches the result as a CSV. Uses hashing to avoid redundant downloads.

### `ssb_get_metadata(table_id)`
Fetches metadata (dimensions and values) for a given SSB table. Useful for understanding the structure before building a query.

### `ssb_get_full_table(table_id)`
Builds a complete query using **all** values for all variables in the table and retrieves the entire dataset. ⚠️ May return a large result.

## Smart Caching

The first time you run `ssb_get_csv()`, the dataset is fetched from SSB and saved locally.  
On later runs, the content is compared using a hash and only updated if it has changed.

`ssb_get_full_table()` doesn't have this functionality yet, but I'll get back to it.

## License

This package is licensed under the MIT License and provided without warranty.  
It was developed independently using open data from Statistics Norway (SSB).
