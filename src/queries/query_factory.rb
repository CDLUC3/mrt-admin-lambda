require_relative 'query'
require_relative 'collection_query'
require_relative 'owner_query'
require_relative 'mime_query'
require_relative 'nodes_query'
require_relative 'objects_query'
require_relative 'objects_by_ark_query'
require_relative 'objects_by_title_query'
require_relative 'objects_by_author_query'
require_relative 'objects_large_query'
require_relative 'objects_many_files_query'
require_relative 'files_query'
require_relative 'files_by_name_coll_query'
require_relative 'invoices_query'

class QueryFactory
  def initialize(client)
    @client = client
  end

  def get_query_for_path(path, myparams)
    if path == 'owners'
      OwnerQuery.new(@client, path, myparams)
    elsif path == 'collections'
      CollectionQuery.new(@client, path, myparams)
    elsif path == 'mimes'
      MimeQuery.new(@client, path, myparams)
    elsif path == 'nodes'
      NodesQuery.new(@client, path, myparams)
    elsif path == 'objects_by_ark'
      ObjectsByArkQuery.new(@client, path, myparams)
    elsif path == 'objects_by_title'
      ObjectsByTitleQuery.new(@client, path, myparams)
    elsif path == 'objects_by_author'
      ObjectsByAuthorQuery.new(@client, path, myparams)
    elsif path == 'objects_large'
      ObjectsLargeQuery.new(@client, path, myparams)
    elsif path == 'objects_many_files'
      ObjectsManyFilesQuery.new(@client, path, myparams)
    elsif path == 'files_by_name_coll'
      FilesByNameCollQuery.new(@client, path, myparams)
    elsif path == 'invoices'
      InvoicesQuery.new(@client, path, myparams)
    else
      AdminQuery.new(@client, path, myparams)
    end
  end
end
