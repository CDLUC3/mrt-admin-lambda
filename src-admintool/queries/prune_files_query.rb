# frozen_string_literal: true

# Query class - see config/reports.yml for description
class PruneCandidateFilesQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
    @mnemonic = get_param('mnemonic', 'merritt_demo')
  end

  def get_title
    "Prune Candidate Files for Mnemonic #{@mnemonic}"
  end

  def get_sql
    %{
    select distinct
      o.ark,
      o.version_number,
      substring_index(f.pathname, '?', 1) norm,
      max(v.number),
      count(distinct f.pathname),
      count(distinct digest_value)
    from
      inv.inv_objects o
    inner join
      inv.inv_files f
    on
      f.inv_object_id = o.id
    inner join
      inv.inv_versions v
    on
      f.inv_version_id = v.id
    where exists (
      select 1
      from
        inv.inv_collections_inv_objects icio
      inner join
        inv.inv_collections c
      on
        c.id = icio.inv_collection_id
      and
        c.mnemonic= ?
      where
        icio.inv_object_id=o.id
    )
    and
      f.pathname like 'producer/%'
    group by
      ark,version_number,norm
    having
      count(distinct f.pathname) > 1
    and
      count(distinct digest_value) > 1
    union
    select distinct
      o.ark,
      o.version_number,
      substring_index(f.pathname, '?', 1) norm,
      max(v.number),
      count(distinct f.pathname),
      count(distinct digest_value)
    from
      inv.inv_objects o
    inner join
       inv.inv_files f
    on
      f.inv_object_id = o.id
    inner join
      inv.inv_versions v
    on
      f.inv_version_id = v.id
    where exists (
      select 1
      from
        inv.inv_collections_inv_objects icio
      inner join
        inv.inv_collections c
      on
        c.id = icio.inv_collection_id
      and
        c.mnemonic= ?
      where
       icio.inv_object_id=o.id
    )
    and
      f.pathname like 'producer/%'
    group by
      ark,version_number,norm
    having
      count(distinct f.pathname) = 1
    and
      max(v.number) < o.version_number;
    }
  end

  def get_params
    [@mnemonic, @mnemonic]
  end

  def get_headers(_results)
    ['Ark', 'Version', 'Path', 'Max Ver', 'Path Count', 'Digest Count']
  end

  def get_types(_results)
    ['ark', '', 'name', '', '', '']
  end
end
