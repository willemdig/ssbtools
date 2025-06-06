Installation

To install the ssbtools package directly from the R-console:

# Install devtools if you haven't already
install.packages("devtools")

# Install ssbtools from GitHub
devtools::install_github("willemdig/ssbtools")

Usage

Save your SSB query as a .json file via SSB's StatBank, and place it in a JSON/ folder in your project.

The filename must follow this format:

ssbapi_table_<table_id>.json

Example:

JSON/ssbapi_table_12030.json

Use the function ssb_get_csv() in your R script:

library(ssbtools)

# This will:
# - Read the query from JSON/ssbapi_table_12030.json
# - Download fresh data from SSB (only if it has changed)
# - Cache the result as csv/ssb/ssb_table_12030.csv
df <- ssb_get_csv("12030")

The first time it runs, it fetches data from SSB.
On subsequent runs, it checks if the content has changed (via hash) and reuses the cached CSV if it hasn't.
