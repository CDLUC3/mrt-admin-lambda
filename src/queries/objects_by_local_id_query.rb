class ObjectsByLocalIdQuery < ObjectsQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
    @localid = get_param('localid', '')
  end

  def get_title
    "Objects By Local Id Query: #{@localid}"
  end

  def get_params
    [@localid]
  end

  def get_where
    'where o.erc_where like ?'
  end
end