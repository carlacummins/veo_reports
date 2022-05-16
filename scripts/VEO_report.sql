-- setup import mode
.mode csv

-- create analyses table and import
-- create table analyses(run_id, platform, model, country, first_public, first_created, collection_date); -- Report <11 (Alexey's) format
-- create table analyses(run_accession, sample_accession, instrument_platform, instrument_model, first_public, country, collection_date); -- Report 11 format
create table analyses(run_id, platform, model, country, first_public, first_created, collection_date, snapshot_date); -- Report 12+ (BigQuery) format
.import ReportX/all_metadata.csv analyses

-- create read table and import
.separator "\t"
create table reads(run_accession, experiment_accession, collection_date, instrument_platform, instrument_model, sample_accession, first_public, country);
.import ReportX/reads.ena_as.custom_fields.tsv reads

-- fix data : trim region from countries, update first_public format
delete from reads where country='country';
update reads set country = substr(country, 1, instr(country, ':')-1) where country like '%:%';
alter table reads add column report_platform;
update reads set report_platform = case instrument_platform when 'ILLUMINA' then 'ILLUMINA' when 'OXFORD_NANOPORE' then 'OXFORD_NANOPORE' else 'OTHER' end;

delete from analyses where country='country';
update analyses set country = substr(country, 1, instr(country, ':')-1) where country like '%:%';

-- generate outputs
.once ReportX/counts_per_country.tsv
select country, count(*) from reads where country not in ('not collected', '') group by country;

.once ReportX/counts_per_month.tsv
select substr(first_public, 1, 7) as month, count(*) from reads group by substr(first_public, 1, 7);

-- save database, just incase
.save ReportX/sqlite_db
