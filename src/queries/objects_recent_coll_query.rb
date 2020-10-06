class ObjectsRecentCollQuery < ObjectsQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams, 'modified')
    @coll = CGI.unescape(get_param('coll', '0')).to_i
  end

  def get_title
    "Recently Modified Objects for collection: #{@coll}"
  end

  def get_params(total = true)
    [@coll]
  end

  def get_where
    'where c.id = ?'
  end

  def get_limit
    10
  end
end
