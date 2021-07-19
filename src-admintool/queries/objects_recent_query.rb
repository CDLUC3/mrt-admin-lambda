class ObjectsRecentQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
  end

  def get_title
    "Most Recent Update by Collection"
  end

  def get_sql
    %{
      select
        c.id,
        c.name,
        (
          select
            max(o.modified)
          from
            inv.inv_objects o
          inner join inv.inv_collections_inv_objects icio
            on o.id = icio.inv_object_id
          where
            c.id = icio.inv_collection_id
        ) as modified
      from
        inv.inv_collections c
      order by
        modified desc
      ;
    }
  end

  def get_headers(results)
    ['Collection Id', 'Name', 'Last Ingest']
  end

  def get_types(results)
    ['coll-date', 'name', 'datetime']
  end

end
