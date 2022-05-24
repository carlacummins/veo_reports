# VEO Report Workflow

## Setup and dependencies

- [SQLite](https://www.sqlite.org/index.html) required for generating report summaries
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install-sdk#installing_the_latest_version) required for querying BigQuery database
    - initialise with project `prj-int-dev-covid19-nf-gls`
    - you can skip setting default zones as these are only relevant if using compute
- Several python modules required:
```
pip install -r requirements.txt
```

## Running the workflow

Provide report directory name and a date range. Dates should be in `YYYY-MM-DD` format with a `:` separator. Generally, I use the date of the previous snapshot to today.
```
sh generate_VEO_report.sh <REPORT_DIR> <DATE_RANGE>

# example
sh generate_VEO_report.sh Report100 2021-06-14:2021-07-10
```

## Description of outputs

#### Metadata dumps
- `all_metadata.post_2022.csv` : all metadata pulled from the BigQuery db
- `all_metadata.csv` : concatenation of `all_metadata.pre_2022.csv` and `all_metadata.post_2022.csv`
- `reads.ena_as.custom_fields.tsv` : ENA Advanced Search output - all SARS-CoV-2 read metadata to date 

#### Summary files 
- `VEO_report.sql` : SQL file to load all metadata into an SQLite db, format it and produce summaries required downstream
- `sqlite_db` : a copy of the above database - can be loaded/manipulated at a later date to produce additional stats
- `report_text.txt` : a 'page-by-page' of all the stats that need to be updated as standard in each VEO report
- `counts_per_*.tsv` : summaries required as input for generating figures

#### Figures
Each of the 3 figures are provided as a subdirectory of individual parts, along with a `.png` image of all parts stitched together
