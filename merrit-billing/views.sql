/*
  Roll up Merritt Owner objects to each campus + CDL.
  Other views will re-use this mapping.
 */
drop view if exists owner_list;
create view owner_list as
  select distinct
    CASE
      WHEN own.name REGEXP '^(CDL|UC3)' THEN 'CDL'
      WHEN own.name REGEXP '(^UCB |Berkeley)' THEN 'UCB'
      WHEN own.name REGEXP '(^UCD)' THEN 'UCD'
      WHEN own.name REGEXP '(^UCLA)' THEN 'UCLA'
      WHEN own.name REGEXP '(^UCSB)' THEN 'UCSB'
      WHEN own.name REGEXP '(^UCI)' THEN 'UCI'
      WHEN own.name REGEXP '(^UCM)' THEN 'UCM'
      WHEN own.name REGEXP '(^UCR)' THEN 'UCR'
      WHEN own.name REGEXP '(^UCSC)' THEN 'UCSC'
      WHEN own.name REGEXP '(^UCSD)' THEN 'UCSD'
      WHEN own.name REGEXP '(^UCSF)' THEN 'UCSF'
      ELSE 'Other'
    END as ogroup,
    CASE
      WHEN own.name is null and own.id = 42 THEN 'Dryad'
      WHEN own.name is null THEN '(No name specified)'
      ELSE own.name
    END as own_name,
    own.id as inv_owner_id
  from
    inv.inv_owners own
;

/*
  Roll up mime types into logical groupings reported to the Digital Preservation working group.
  By default, the first part of the mime type will be used as a grouping.
  Regular expressions are applied first in order to handle excpetion types.
  Other views will re-use this mapping.
 */
drop view if exists owner_coll_mime_use_details;
create view owner_coll_mime_use_details as
  select
    ol.ogroup,
    ol.own_name,
    c.name as collection_name,
    c.mnemonic,
    dmud.date_added,
    dmud.mime_type,
    CASE
      WHEN mime_type = 'text/csv' THEN 'data'
      WHEN mime_type = 'plain/turtle' THEN 'data'
      WHEN mime_type REGEXP '^application/(json|atom\.xml|marc|mathematica|x-hdf|x-matlab-data|x-sas|x-sh$|x-sqlite|x-stata)' THEN 'data'
      WHEN mime_type REGEXP '^application/.*(zip|gzip|tar|compress|zlib)' THEN 'container'
      WHEN mime_type REGEXP '^application/(x-font|x-web)' THEN 'web'
      WHEN mime_type REGEXP '^application/(x-dbf|vnd\.google-earth)' THEN 'geo'
      WHEN mime_type REGEXP '^application/vnd\.(rn-real|chipnuts)' THEN 'audio'
      WHEN mime_type REGEXP '^application/mxf' THEN 'video'
      WHEN mime_type REGEXP '^(message|model)/' THEN 'text'
      WHEN mime_type REGEXP '^(multipart|text/x-|application/java|application/x-executable|application/x-shockwave-flash)' THEN 'software'
      WHEN mime_type REGEXP '^application/' THEN 'text'
      ELSE substring_index(mime_type, '/', 1)
    END as mime_group,
    dmud.inv_owner_id,
    dmud.inv_collection_id,
    dmud.source,
    dmud.count_files,
    dmud.full_size,
    dmud.billable_size
  from
    owner_list ol
  inner join daily_mime_use_details dmud
    on dmud.inv_owner_id = ol.inv_owner_id
  inner join inv.inv_collections c
    on c.id = dmud.inv_collection_id
  inner join inv.inv_objects o 
    on c.inv_object_id = o.id and o.aggregate_role = 'MRT-collection'
;

/*
  Aggregate mime type usage by owner and collection
 */
drop view if exists mime_use_details;
create view mime_use_details as
select
  mime_type,
  mime_group,
  inv_owner_id,
  inv_collection_id,
  source,
  sum(count_files) as count_files,
  sum(full_size) as full_size,
  sum(billable_size) as billable_size
from
  owner_coll_mime_use_details
group by
  mime_type,
  mime_group,
  inv_owner_id,
  inv_collection_id,
  source
;

/*
  Aggregate mime type usage by campus. Also include collection name.
 */
drop view if exists owner_collections;
create view owner_collections as
  select distinct
    dmud.ogroup,
    dmud.own_name,
    c.name as collection_name,
    c.mnemonic,
    dmud.inv_owner_id,
    dmud.inv_collection_id
  from
    inv.inv_collections c
  inner join owner_coll_mime_use_details dmud
    on dmud.inv_collection_id = c.id
;


/*
  Aggregate object counts by campus, owner and collection.
 */
drop view if exists owner_collections_objects;
create view owner_collections_objects as
  select
    ol.ogroup,
    ol.own_name as own_name,
    c.name as collection_name,
    ol.inv_owner_id,
    c.id as inv_collection_id,
    count(o.id) count_objects
  from
    inv.inv_collections c
  inner join inv.inv_objects o2
    on c.inv_object_id = o2.id and o2.aggregate_role = 'MRT-collection'
  inner join inv.inv_collections_inv_objects icio
    on c.id = icio.inv_collection_id
  inner join inv.inv_objects o
    on o.id = icio.inv_object_id
  inner join owner_list ol
    on o.inv_owner_id = ol.inv_owner_id
  group by
    ogroup,
    collection_name,
    inv_owner_id,
    inv_collection_id
;

drop view if exists node_counts;
create view node_counts as
  select
    inv_node_id,
    number,
    object_count,
    object_count_primary,
    object_count_secondary,
    file_count,
    billable_size
  from 
    daily_node_counts
  where
    as_of_date = (
      select
        max(as_of_date)
      from 
        daily_node_counts
    )
;