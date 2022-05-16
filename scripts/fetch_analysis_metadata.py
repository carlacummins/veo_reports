import requests, json, sys
import pprint
pp = pprint.PrettyPrinter(indent=4)

fields = ['ena_run', 'experiment_accession', 'sample_accession', 'clean_country', 'instrument_platform', 'first_public']
print("run_id\texperiment_accession\tsample_accession\tcountry\tinstrument_platform\tfirst_public")
skip, limit = 0, 10000
data_empty = False
while not data_empty:
    url = "https://kooplex-ebi.vo.elte.hu/api/meta/?skip={}&limit={}".format(skip, limit)
    response = requests.get(url)
    data = json.loads(response.content)
    if data == []:
        data_empty = True
        pass

    for d in data:
        tsv_row = [d[f] if d[f] else '' for f in fields]
        print("\t".join(tsv_row))

    skip += limit
    sys.stderr.write("Fetched {} rows\r".format(skip))
sys.stderr.write("\n")
