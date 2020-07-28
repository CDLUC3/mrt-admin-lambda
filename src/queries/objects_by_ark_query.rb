class ObjectsByArkQuery < ObjectsQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
    @ark = get_param('ark', '')
  end

  def get_title
    "Objects By Ark Query: #{@ark}"
  end

  def get_params
    [@ark]
  end

  def get_where
    'where o.ark like ?'
  end
end
