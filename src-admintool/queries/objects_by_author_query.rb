# frozen_string_literal: true

# Query class - see config/reports.yml for description
class ObjectsByAuthorQuery < ObjectsQuery
  def initialize(query_factory, path, myparams)
    super
    @author = CGI.unescape(get_param('author', ''))
  end

  def get_title
    "Objects By Author Query: #{@author}"
  end

  def get_params
    [@author]
  end

  def get_where
    'where o.erc_who like ?'
  end
end
