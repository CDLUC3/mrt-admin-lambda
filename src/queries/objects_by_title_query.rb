class ObjectsByTitleQuery < ObjectsQuery
  def initialize(query_factory, path, myparams)
    super(query_factory , path, myparams)
    @title = get_param('title', '')
  end

  def get_title
    "Objects By Title Query: #{@title}"
  end

  def get_params
    [@title]
  end

  def get_where
    'where o.erc_what like ?'
  end
end
