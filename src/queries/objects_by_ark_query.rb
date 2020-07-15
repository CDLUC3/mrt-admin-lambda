class ObjectsByArkQuery < ObjectsQuery
  def initialize(client, path, params)
    super(client, path, params)
    @ark = params.key?('ark') ? params['ark'] : ''
  end

  def get_title
    "Objects By Ark Query: #{@ark}"
  end

  def get_params
    [@ark]
  end

  def get_where
    'o.ark like ?'
  end
end
