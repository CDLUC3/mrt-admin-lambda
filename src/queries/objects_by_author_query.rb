class ObjectsByAuthorQuery < ObjectsQuery
  def initialize(client, path, myparams)
    super(client, path, myparams)
    @author = myparams.key?('author') ? myparams['author'] : ''
  end

  def get_title
    "Objects By Author Query: #{@author}"
  end

  def get_params
    [@author]
  end

  def get_where
    'o.erc_who like ?'
  end
end
