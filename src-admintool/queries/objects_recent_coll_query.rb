class ObjectsRecentCollQuery < ObjectsQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams, 'modified')
    @coll = CGI.unescape(get_param('coll', '0')).to_i
  end

  def get_title
    "Recently Modified Objects for collection: #{@coll}"
  end

  def get_params
    [@coll]
  end

  def get_where
    %{
      where exists (
        select 1
        from 
          inv.inv_collections_inv_objects icio
        where
          o.id = icio.inv_object_id
        and 
          icio.inv_collection_id = ?
      )
    }
  end

end
