class ObjectsByContainerNameQuery < ObjectsQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
    @container = CGI.unescape(get_param('container', ''))
  end

  def get_title
    "Objects By Container Name: #{@container}"
  end

  def get_params
    [@container]
  end

  def get_where
  %{
    where exists  (
      select 
        1
      from 
        inv.inv_ingests ing
      where 
        ing.filename = ? 
      and
        ing.inv_object_id = o.id
    ) 
  }
  end
end
