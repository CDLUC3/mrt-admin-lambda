class ObjectsMultipleCollQuery < ObjectsQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams, 'modified')
  end

  def get_title
    "Objects linked to multiple collections"
  end

  def get_where
    %{
      where o.id in (
        select
          inv_object_id
        from 
          inv.inv_collections_inv_objects
        group by
          inv_object_id
        having 
          count(*) > 1
      )
    }
  end

end
