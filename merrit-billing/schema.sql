/*
   This table replicates the CSV files generated once per day in the old Merritt Billing process.
   Records will be added to this table based on the inv.inv_files.created field.
 */
/*
DROP TABLE IF EXISTS daily_billing;
*/
CREATE TABLE daily_billing (
  id int unsigned NOT NULL AUTO_INCREMENT PRIMARY KEY,
  billing_totals_date date,
  inv_owner_id smallint unsigned,
  inv_collection_id smallint unsigned not null,
  billable_size bigint unsigned NOT NULL DEFAULT '0',
  INDEX billing_totals_date (billing_totals_date),
  UNIQUE INDEX collection_daily (billing_totals_date, inv_collection_id, inv_owner_id),
  INDEX inv_owner_id (inv_owner_id),
  INDEX inv_collection_id (inv_collection_id)
);

/*
   This table is designed to optimized mime_type reporting in the Merritt Admin tool.
   Records will be added to this table based on the inv.inv_files.created field.
 */
/* 
DROP TABLE IF EXISTS daily_mime_use_details;
*/
CREATE TABLE daily_mime_use_details (
  date_added date,
  mime_type varchar(255),
  inv_owner_id int,
  inv_collection_id int,
  source enum('consumer','producer','system'),
  count_files bigint,
  full_size bigint,
  billable_size bigint,
  INDEX date_added(date_added),
  INDEX mime_type(mime_type),
  INDEX collection_id(inv_collection_id),
  INDEX owner_id(inv_owner_id),
  UNIQUE INDEX daily(date_added, mime_type, inv_collection_id, inv_owner_id, source)
);

/*
DROP TABLE IF EXISTS billing_owner_exemptions;
*/
CREATE TABLE billing_owner_exemptions (
  inv_owner_id int,
  exempt_bytes bigint
);

/*
DROP TABLE IF EXISTS object_size;
*/
CREATE TABLE object_size (
  inv_object_id int,
  file_count bigint,
  billable_size bigint,
  updated datetime,
  INDEX object_id(inv_object_id)
);

/*
DROP TABLE IF EXISTS audits_processed;
*/
CREATE TABLE audits_processed (
  audit_date date,
  all_files bigint,
  online_files bigint,
  online_bytes bigint,
  s3_files bigint,
  s3_bytes bigint,
  glacier_files bigint,
  glacier_bytes bigint,
  sdsc_files bigint,
  sdsc_bytes bigint,
  wasabi_files bigint,
  wasabi_bytes bigint,
  other_files bigint,
  other_bytes bigint,
  INDEX audit_date(audit_date)
);

/*
DROP TABLE IF EXISTS ingests_completed;
*/
CREATE TABLE ingests_completed (
  ingest_date date,
  profile varchar(255), 
  batch_id varchar(255),
  object_count int, 
  INDEX ingest_date(ingest_date)
);
  