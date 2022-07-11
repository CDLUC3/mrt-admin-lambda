class UpdateBillingDatabaseQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
    stmt = @client.prepare("call update_object_size()")
    results = stmt.execute()
    stmt = @client.prepare("call update_node_counts()")
    results = stmt.execute()
  end

  def get_title
    "Update Billing Database Tables"
  end

  def get_sql
    %{
      select 
        'Object Count', (select count(*) from object_size) as data
      union
      select
        'File Count - All nodes', (select sum(file_count) from node_counts) as data
      union
      select
        'Billable Size - All nodes', (select sum(billable_size) from node_counts) as data
      ;
    }
  end

  def get_headers(results)
    ['Category', 'Count']
  end

  def get_types(results)
    ['','dataint']
  end

end
