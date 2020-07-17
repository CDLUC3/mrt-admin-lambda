# Explicitly include all parent classes
require_relative 'query'
require_relative 'objects_query'
require_relative 'files_query'

# Include all Query classes
Dir[File.dirname(__FILE__) + '/*query.rb'].each {|file| require file }

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
    elsif path == 'objects_recent'
      ObjectsRecentQuery.new(@client, path, myparams)
    elsif path == 'files_by_name_coll'
      FilesByNameCollQuery.new(@client, path, myparams)
    elsif path == 'count_objects'
      CountObjectsQuery.new(@client, path, myparams)
    elsif path == 'collections_by_node'
      CollectionsByNodeQuery.new(@client, path, myparams)
    elsif path == 'collections_by_owner'
      CollectionsByOwnerQuery.new(@client, path, myparams)
    elsif path == 'collections_by_mime_type'
      CollectionsByMimeQuery.new(@client, path, myparams, 'mime_type')
    elsif path == 'collections_by_mime_group'
      CollectionsByMimeQuery.new(@client, path, myparams, 'mime_group')
    elsif path == 'collections_by_time_count'
      CollectionsByTimeQuery.new(@client, path, myparams, 'count_files')
    elsif path == 'collections_by_time_size'
      CollectionsByTimeQuery.new(@client, path, myparams, 'billable_size')
    elsif path == 'collection_details'
      CollectionDetailsQuery.new(@client, path, myparams, 'inv_collection_id')
    elsif path == 'collection_group_details'
      CollectionDetailsQuery.new(@client, path, myparams, 'ogroup')
    elsif path == 'invoices'
      InvoicesQuery.new(@client, path, myparams)
    else
      AdminQuery.new(@client, path, myparams)
    end
  end
end
