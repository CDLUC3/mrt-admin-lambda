class ProducerFilesQuery < S3AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
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
        loc.local_id
      from 
        inv.inv_objects o 
      inner join inv.inv_files f 
        on f.inv_object_id = o.id and source = 'producer'
      inner join inv.inv_versions v
        on f.inv_version_id = v.id
      left join inv.inv_localids loc
        on o.ark = loc.inv_object_ark
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

  def get_headers(results)
    ['Ark', 'Version', 'Path', 'Bytes', 'Digest', 'Created', 'Local Id']
  end

  def get_types(results)
    ['ark', '', 'name', 'bytes', 'name', 'datetime', 'name']
  end

end