class ObjectsLocalidNeededQuery < ObjectsQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams, sort='modified')
  end

  def get_title
    "Objects Missing a Local Id"
  end

  def get_params
    @ids
  end

  def get_where
    %{
      where not exists (
        select 
          1
        from 
          inv.inv_localids loc
        where
          o.ark = loc.inv_object_ark
      ) 
      and 
        erc_where != concat(o.ark, ' ; (:unas)')   
    }
  end

  def get_max_limit
    500
  end

  def page_size
    get_limit
  end

  def get_alternative_queries
    [
      {
        label: "Count Objects missing localid", 
        url: "path=con_localid"
      },
    ]
  end

end
