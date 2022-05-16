# fetch and verify inputs
export REPORT_DIR=$1
export DATE_RANGE=$2

# helptext
if  test -z "$REPORT_DIR" || test -z "$DATE_RANGE"
then 
    echo "Usage: sh generate_VEO_report.sh <REPORT_DIR> <DATE_RANGE>\n"
    echo "Example: sh generate_VEO_report.sh Report100 2021-06-14:2021-07-10\n"
    exit
fi

# split date range
export FROM_DATE=$(echo $DATE_RANGE | awk -F: '{print $1}')
export TO_DATE=$(echo $DATE_RANGE | awk -F: '{print $2}')

# make the report directory if it doesn't already exist
if [ ! -d "$REPORT_DIR" ]
then
    mkdir -p $REPORT_DIR
fi

# handle analysis metadata
export META_FILE="$REPORT_DIR/all_metadata.csv"
if [ -e $META_FILE ]
then
    echo "Analysis metadata found"
    if ! head -1 $META_FILE | grep 'country' > /dev/null
    then
        echo "---> Detected missing header line... adding"
        export META_HEADER='run_accession,sample_accession,instrument_platform,instrument_model,first_public,country,collection_date'
        echo "$(echo $META_HEADER; cat $META_FILE)" > $META_FILE
    fi
else
    # copy early snapshot metadata from file
    # cp all_metadata.pre_2022.csv $META_FILE

    # get analysis metadata from BigQuery db
    echo "Fetching analysis metadata from BigQuery DB.."
    export BQ_SQL="SELECT run_id, platform, model, country, first_public, first_created, collection_date, snapshot_date FROM prj-int-dev-covid19-nf-gls.sarscov2_metadata.submission_metadata GROUP BY run_id, platform, model, country, first_public, first_created, collection_date, snapshot_date"
    bq query --format=csv --use_legacy_sql=false --max_rows=100000000 $BQ_SQL > $REPORT_DIR/all_metadata.post_2022.csv

    head -1 all_metadata.pre_2022.csv > $META_FILE # write header
    cat all_metadata.pre_2022.csv $REPORT_DIR/all_metadata.post_2022.csv | grep -v country >> $META_FILE # all data without headers
fi
echo "---> $(wc -l $META_FILE | awk '{print $1}') rows in $META_FILE"

echo ""

# fetch ENA Advanced Search output
export READ_FILE="$REPORT_DIR/reads.ena_as.custom_fields.tsv"
if [ -e $READ_FILE ]
then
    echo "Read metadata found"
else
    echo "Fetching reads from ENA Advanced Search.."
    curl -X POST -H "Content-Type: application/x-www-form-urlencoded" -d 'result=read_run&query=tax_tree(2697049)&fields=run_accession,experiment_accession,collection_date,instrument_platform,instrument_model,sample_accession,first_public,country&limit=0&format=tsv' "https://www.ebi.ac.uk/ena/portal/api/search" > $READ_FILE
fi
echo "---> $(wc -l $READ_FILE | awk '{print $1}') rows in $READ_FILE"


echo ""

# run sqlite counts
echo "Creating SQLite database and generating data summaries.."
export FULL_REPORT_DIR="$PWD/$REPORT_DIR"
sed s+ReportX+$FULL_REPORT_DIR+ scripts/VEO_report.sql > $REPORT_DIR/VEO_report.sql # use + as sed delimiter as / is used in path 
sqlite3 veo_report_db ".read $REPORT_DIR/VEO_report.sql"
rm veo_report_db

# generate report text
python scripts/sqlite_summaries.py $REPORT_DIR/sqlite_db $FROM_DATE $TO_DATE | tee $REPORT_DIR/report_text.txt

# format output files
echo "$(echo 'month\tcount'; cat $REPORT_DIR/counts_per_month.tsv)" > $REPORT_DIR/counts_per_month.tsv

echo ""
echo "Generating figures"

# Figure 1
echo "Figure 1.."
mkdir -p $REPORT_DIR/Figure1
echo "---> generating cumulative data plot"
python scripts/plotly_cumulative_data.py -i $REPORT_DIR/counts_per_month.tsv -o $REPORT_DIR/Figure1/cumulative_read_count.png
echo "---> generating maps of all reads"
python scripts/plotly_map_advanced_search.py --tsv $REPORT_DIR/reads.ena_as.custom_fields.tsv --out $REPORT_DIR/Figure1/map.all_reads.global.png
python scripts/plotly_map_advanced_search.py --tsv $REPORT_DIR/reads.ena_as.custom_fields.tsv --out $REPORT_DIR/Figure1/map.all_reads.eu.png --region EU
echo "---> stitch images together into Figure1.png"
python scripts/generate_figure.py -i $REPORT_DIR/Figure1/cumulative_read_count.png,$REPORT_DIR/Figure1/map.all_reads.global.png,$REPORT_DIR/Figure1/map.all_reads.eu.png -o $REPORT_DIR/Figure1.png

# Figure 2
echo "Figure 2.."
mkdir -p $REPORT_DIR/Figure2
echo "---> generating maps of new data ($DATE_RANGE)"
python scripts/plotly_map_advanced_search.py --tsv $REPORT_DIR/reads.ena_as.custom_fields.tsv --out $REPORT_DIR/Figure2/map.new_reads.global.png --date_type first_public --date_range $DATE_RANGE
python scripts/plotly_map_advanced_search.py --tsv $REPORT_DIR/reads.ena_as.custom_fields.tsv --out $REPORT_DIR/Figure2/map.new_reads.eu.png --date_type first_public --date_range $DATE_RANGE --region EU
echo "---> stitch images together into Figure2.png"
python scripts/generate_figure.py -i $REPORT_DIR/Figure2/map.new_reads.global.png,$REPORT_DIR/Figure2/map.new_reads.eu.png -o $REPORT_DIR/Figure2.png

# Figure 3
echo "Figure 3.."
mkdir -p $REPORT_DIR/Figure3
echo "---> generating maps of analysed data"
python scripts/plotly_map_advanced_search.py --csv $REPORT_DIR/all_metadata.csv --out $REPORT_DIR/Figure3/map.analysed.global.png
python scripts/plotly_map_advanced_search.py --csv $REPORT_DIR/all_metadata.csv --out $REPORT_DIR/Figure3/map.analysed.eu.png --region EU
echo "---> stitch images together into Figure3.png"
python scripts/generate_figure.py -i $REPORT_DIR/Figure3/map.analysed.global.png,$REPORT_DIR/Figure3/map.analysed.eu.png -o $REPORT_DIR/Figure3.png
