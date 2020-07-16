class ObjectsQuery < AdminQuery
  def get_title
    "Object Query"
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
        ) as obj_count,
        (
          select
            sum(f.billable_size)
          from
            inv.inv_files f
          where
            f.inv_object_id=o.id
        ) as billable_size
      from
        inv.inv_objects o
      inner join inv.inv_collections_inv_objects icio
        on o.id = icio.inv_object_id
      inner join inv.inv_collections c
        on icio.inv_collection_id = c.id
      where
    } + get_where +
    %{
      order by o.id asc
      limit 20;
    }
  end

  def get_headers(results)
    ['Object Id','Ark', 'Title', 'Version', 'Coll Id', 'Collection', 'File Count', 'Billable Size']
  end

  def get_types(results)
    ['', 'ark', 'name', '', 'coll', 'mnemonic', 'dataint', 'dataint']
  end

end
