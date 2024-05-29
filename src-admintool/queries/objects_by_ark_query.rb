# frozen_string_literal: true

# Query class - see config/reports.yml for description
class ObjectsByArkQuery < ObjectsQuery
  def initialize(query_factory, path, myparams)
    super
    @ark = CGI.unescape(get_param('ark', ''))
  end

  def get_title
    "Objects By Ark Query: #{@ark}"
  end

  def get_params
    [@ark]
  end

  def get_where
    'where o.ark like ?'
  end
end
