# frozen_string_literal: true

# Query class - see config/reports.yml for description
class ObjectsByTitleQuery < ObjectsQuery
  def initialize(query_factory, path, myparams)
    super
    @title = CGI.unescape(get_param('title', ''))
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
