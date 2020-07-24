class ObjectsQuery < AdminQuery
  def initialize(query_factory, path, myparams, sort='id')
    super(query_factory, path, myparams)
    if sort == 'created'
      @sort = 'o.created desc'
    else
      @sort = 'o.id asc'
    end
  end

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
        o.erc_who,
        o.erc_where,
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
        ) as billable_size,
        date(o.created) as created
      from
        inv.inv_objects o
      inner join inv.inv_collections_inv_objects icio
        on o.id = icio.inv_object_id
      inner join inv.inv_collections c
        on icio.inv_collection_id = c.id
    } + get_where +
    %{
      order by #{@sort}
      limit 50;
    }
  end

  def get_headers(results)
    ['Object Id','Ark', 'Title', 'Author', 'Local Id', 'Version', 'Coll Id', 'Collection', 'File Count', 'Billable Size', 'Created']
  end

  def get_types(results)
    ['', 'ark', 'name', '', '', '', 'coll', 'mnemonic', 'dataint', 'dataint', '']
  end

end
