class ObjectsByTitleQuery < ObjectsQuery
  def initialize(client, path, myparams)
    super(client, path, myparams)
    @title = myparams.key?('title') ? myparams['title'].strip : ''
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
