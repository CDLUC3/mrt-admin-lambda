require_relative 'query'
require_relative 'collection_query'
require_relative 'owner_query'

class QueryFactory
  def initialize(client)
    @client = client
  end

  def get_query_for_path(path)
    if path == 'owners'
      OwnerQuery.new(@client)
    elsif path == 'collections'
      CollectionQuery.new(@client)
    else
      AdminQuery.new(@client)
    end
  end
end
