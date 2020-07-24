class ObjectsByLocalIdQuery < ObjectsQuery
  def initialize(client, path, myparams)
    super(client, path, myparams)
    @localid = myparams.key?('localid') ? myparams['localid'].strip : ''
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
