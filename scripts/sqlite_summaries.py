import sqlite3, sys
from sqlite3 import Error

def create_connection(db_file):
    conn = None
    try:
        conn = sqlite3.connect(db_file)
    except Error as e:
        print(e)

    return conn


if __name__ == '__main__':
    (sqlite_file, from_date, to_date) = (sys.argv[1], sys.argv[2], sys.argv[3])
    conn = create_connection(sqlite_file)
    cur = conn.cursor()

    print("-----------\n- Summary -\n-----------")
    cur.execute(f"SELECT count(*) FROM reads WHERE DATE(first_public) < DATE('{to_date}')")
    all_count = cur.fetchone()[0]
    cur.execute(f"SELECT count(*) FROM reads WHERE DATE(first_public) < DATE('{from_date}')")
    old_count = cur.fetchone()[0]
    perc_incr = round(((float(all_count)/float(old_count))*100)-100, 1)
    print(f"* read count before {from_date}: {old_count}; all reads count: {all_count}; % increase: {perc_incr}")

    cur.execute("SELECT COUNT(DISTINCT(country)) FROM reads WHERE country NOT IN ('not collected', '')")
    country_count = cur.fetchone()[0]

    print(f"* Update on mobilisation of raw reads, now totaling sequencing data sets from {all_count} viral raw read sets from {country_count} countries, a {perc_incr}% increase since the previous report.")

    cur.execute("select count(*) from reads where instrument_platform = 'OXFORD_NANOPORE'")
    all_ont = cur.fetchone()[0]
    cur.execute("select count(*) from analyses where platform = 'OXFORD_NANOPORE'")
    analysed_ont = cur.fetchone()[0]
    print(f"* The variant calling workflow for the Oxford Nanopore data has been implemented and {analysed_ont} samples of the total {all_ont} have been processed so far.")

    print("\n---------------------\n- Data mobilisation -\n---------------------")
    cur.execute("select max(date(first_public)) from reads")
    max_public_date = cur.fetchone()[0]
    print(f"* data freeze: {max_public_date}")

    cur.execute("select report_platform, count(*) from reads group by report_platform")
    p = cur.fetchall()
    platforms = {q[0]:q[1] for q in p}
    platforms['TOTAL'] = sum(platforms.values())
    print("* Raw data sets\n\t- {}".format("\n\t- ".join(["{}: {}".format(k, platforms[k]) for k in ('TOTAL', 'ILLUMINA', 'OXFORD_NANOPORE', 'OTHER')])))
    print(f"* Countries: {country_count}")

    print("\n------------\n- Figure 1 -\n------------")
    cur.execute("select substr(experiment_accession, 1, 3), count(*) from reads group by substr(experiment_accession, 1, 3)")
    insdc = {r[0]:r[1] for r in cur.fetchall()}
    total_insdc = sum(insdc.values())
    ena_data_perc = round((float(insdc['ERX'])/total_insdc)*100, 1)
    other_insdc_perc = round((float(insdc['DRX'] + insdc['SRX'])/total_insdc)*100, 1)
    print(f"* {ena_data_perc}% of global data have been routed through the SARS-CoV-2 Data Hubs, with the remaining {other_insdc_perc}% arriving into the platform from collaborators in the US and Asia")

    print("\n------------\n- Figure 2 -\n------------")
    print(f"* since {from_date}")

    print("\n------------\n- Figure 3 -\n------------")
    cur.execute("select count(*), min(date(first_public)), max(date(first_public)) from analyses")
    (analyses_count, min_analysis_date, max_analysis_date) = cur.fetchone()
    print(f"* Geographical sources of analysed raw data comprising {analyses_count} data sets spanning the period of data first published from {min_analysis_date} to {max_analysis_date}\n")
