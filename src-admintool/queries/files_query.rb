class FilesQuery < AdminQuery
  def get_title
    "File Query"
  end

  def get_where
    ""
  end

  def get_sql
    %{
      select
        o.id,
        o.ark,
        o.erc_what,
        o.version_number,
        c.id as collection_id,
        c.mnemonic,
        (
          select
            count(f.id)
          from
            inv.inv_files f
          where
            f.inv_object_id=o.id
        ),
        (
          select
            sum(f.billable_size)
          from
            inv.inv_files f
          where
            f.inv_object_id=o.id
        )
      from
        inv.inv_objects o
      inner join inv.inv_collections_inv_objects icio
        on icio.inv_object_id = o.id
      inner join inv.inv_collections c
        on icio.inv_collection_id = c.id
      inner join inv.inv_files f
        on f.inv_object_id = o.id
    } + get_where +
    %{
      order by o.id asc
      limit #{get_limit};
    }
  end

  def get_headers(results)
    ['Object Id','Ark', 'Title', 'Version', 'Coll Id', 'Collection', 'File Count', 'Billable Size']
  end

  def get_types(results)
    ['', 'ark', '', '', 'coll', 'mnemonic', 'dataint', 'bytes']
  end

  def get_alternative_queries
    get_alternative_limit_queries
  end

end
