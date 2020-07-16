class ObjectsByArkQuery < ObjectsQuery
  def initialize(client, path, myparams)
    super(client, path, myparams)
    @ark = myparams.key?('ark') ? myparams['ark'].strip : ''
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
