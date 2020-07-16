require_relative 'query'
require_relative 'collection_query'
require_relative 'owner_query'
require_relative 'objects_query'
require_relative 'objects_by_ark_query'

class QueryFactory
  def initialize(client)
    @client = client
  end

  def get_query_for_path(path, myparams)
    if path == 'owners'
      OwnerQuery.new(@client, path, myparams)
    elsif path == 'collections'
      CollectionQuery.new(@client, path, myparams)
    elsif path == 'objects_by_ark'
      ObjectsByArkQuery.new(@client, path, myparams)
    else
      AdminQuery.new(@client, path, myparams)
    end
  end
end
