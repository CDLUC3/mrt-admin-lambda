# Explicitly include all parent classes
require_relative 'query'
require_relative 'objects_query'
require_relative 'files_query'

# Include all Query classes
Dir[File.dirname(__FILE__) + '/*query.rb'].each {|file| require file }

class QueryFactory
  def initialize(client, merritt_path)
    @client = client
    @merritt_path = merritt_path
  end

  def client
    @client
  end

  def merritt_path
    @merritt_path
  end

  def get_query_for_path(path, myparams)
    if path == 'owners'
      OwnerQuery.new(self, path, myparams)
    elsif path == 'collections'
      CollectionQuery.new(self, path, myparams)
    elsif path == 'mimes'
      MimeQuery.new(self, path, myparams)
    elsif path == 'nodes'
      NodesQuery.new(self, path, myparams)
    elsif path == 'objects_by_ark'
      ObjectsByArkQuery.new(self, path, myparams)
    elsif path == 'objects_by_title'
      ObjectsByTitleQuery.new(self, path, myparams)
    elsif path == 'objects_by_local_id'
      ObjectsByLocalIdQuery.new(self, path, myparams)
    elsif path == 'objects_by_author'
      ObjectsByAuthorQuery.new(self, path, myparams)
    elsif path == 'objects_large'
      ObjectsLargeQuery.new(self, path, myparams)
    elsif path == 'objects_many_files'
      ObjectsManyFilesQuery.new(self, path, myparams)
    elsif path == 'objects_recent'
      ObjectsRecentQuery.new(self, path, myparams)
    elsif path == 'files_by_name_coll'
      FilesByNameCollQuery.new(self, path, myparams)
    elsif path == 'count_objects'
      CountObjectsQuery.new(self, path, myparams)
    elsif path == 'collections_by_node'
      CollectionsByNodeQuery.new(self, path, myparams)
    elsif path == 'collections_by_owner'
      CollectionsByOwnerQuery.new(self, path, myparams)
    elsif path == 'collections_by_mime_type'
      CollectionsByMimeQuery.new(self, path, myparams, 'mime_type')
    elsif path == 'collections_by_mime_group'
      CollectionsByMimeQuery.new(self, path, myparams, 'mime_group')
    elsif path == 'collections_by_time_count'
      CollectionsByTimeQuery.new(self, path, myparams, 'count_files')
    elsif path == 'collections_by_time_size'
      CollectionsByTimeQuery.new(self, path, myparams, 'billable_size')
    elsif path == 'collection_details'
      CollectionDetailsQuery.new(self, path, myparams, 'inv_collection_id')
    elsif path == 'collection_group_details'
      CollectionDetailsQuery.new(self, path, myparams, 'ogroup')
    elsif path == 'invoices'
      InvoicesQuery.new(self, path, myparams)
    elsif path == 'audit_status'
      AuditStatusQuery.new(self, path, myparams)
    elsif path == 'audit_oldest'
      AuditOldestQuery.new(self, path, myparams)
    elsif path == 'audit_processed'
      AuditProcessedQuery.new(self, path, myparams)
    elsif path == 'replication_needed'
      ReplicationNeededQuery.new(self, path, myparams)
    else
      AdminQuery.new(self, path, myparams)
    end
  end
end
