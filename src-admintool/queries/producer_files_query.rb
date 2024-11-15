# frozen_string_literal: true

# Query class - see config/reports.yml for description
class ProducerFilesQuery < S3AdminQuery
  def initialize(query_factory, path, myparams)
    super
    @mnemonic = get_param('mnemonic', 'merritt_demo')
  end

  def get_title
    "Producer Files by Mnemonic #{@mnemonic} - #{num_format(@csvlen)} records"
  end

  def get_sql
    %{
      select
        distinct o.ark,
        v.number,
        substr(f.pathname, 10) as fname,
        billable_size,
        digest_value,
        f.created,
        loc.loc_id_agg
      from
        inv.inv_objects o
      inner join inv.inv_files f
        on f.inv_object_id = o.id and source = 'producer'
      inner join inv.inv_versions v
        on f.inv_version_id = v.id
      left join
        (
          select inv_object_ark, group_concat(local_id) as loc_id_agg
          from inv.inv_localids
          group by inv_object_ark
        ) loc
        on o.ark = inv_object_ark
      where exists (
        select 1
        from
          inv.inv_collections_inv_objects icio
        where
          icio.inv_object_id = o.id
        and
          icio.inv_collection_id = (
            select
              id
            from
              inv.inv_collections c
            where
              c.mnemonic = ?
          )
        )
      order by
        o.ark,
        fname
      ;
    }
  end

  def get_params
    [@mnemonic]
  end

  def get_headers(_results)
    ['Ark', 'Version', 'Path', 'Bytes', 'Digest', 'Created', 'Local Id']
  end

  def get_types(_results)
    ['ark', '', 'name', 'bytes', 'name', 'datetime', 'name']
  end
end

# Query class - see config/reports.yml for description
class UCSCObjectsQuery < S3AdminQuery
  def initialize(query_factory, path, myparams)
    super
    @mnemonic = get_param('mnemonic', 'merritt_demo')
  end

  def get_title
    "UCSC Objects by Mnemonic #{@mnemonic} - #{num_format(@csvlen)} records"
  end

  def get_sql
    %{
      select
        distinct o.ark,
        loc.loc_id_agg,
        replace(o.erc_what, '"', "'") as erc_what,
        replace(o.erc_when, '"', "'") as erc_when,
        replace(o.erc_who, '"', "'") as erc_who,
        (
          select count(*)
          from inv.inv_versions v
          inner join inv.inv_files f
            on f.inv_object_id = o.id and f.inv_version_id = v.id
            and f.source='producer' and o.version_number = v.number
          where v.inv_object_id = o.id
        ) as file_count,
        os.billable_size,
        concat('http://n2t.net/', o.ark) as permalink,
        (
          select group_concat(distinct f.mime_type)
          from inv.inv_files f
          where inv_object_id=o.id and source='producer'
        ) as mimetypes
      from
        inv.inv_objects o
      inner join billing.object_size os
        on os.inv_object_id = o.id
      left join
        (
          select inv_object_ark, group_concat(local_id) as loc_id_agg
          from inv.inv_localids
          group by inv_object_ark
        ) loc
        on o.ark = inv_object_ark
      where exists (
        select 1
        from
          inv.inv_collections_inv_objects icio
        where
          icio.inv_object_id = o.id
        and
          icio.inv_collection_id = (
            select
              id
            from
              inv.inv_collections c
            where
              c.mnemonic = ?
          )
        )
      order by
        o.ark
      ;
    }
  end

  def get_params
    [@mnemonic]
  end

  def get_headers(_results)
    [
      'Ark', 'Local Id', 'erc_what', 'erc_when', 'erc_who', 'producer file count', 'billable_size', 'permalink',
      'mimetypes'
]
  end

  def get_types(_results)
    ['ark', 'name', 'name', '', '', 'data', 'bytes', '', '']
  end
end
