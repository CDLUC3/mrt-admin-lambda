class FilesizeQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
  end

  def get_title
    "Producer File size summary"
  end

  def get_sql
    %{
      select
        max(billable_size) max_size,
        min(billable_size) min_size,
        avg(billable_size) avg_size,
        count(*) num_files
      from
        inv.inv_files
      where
        source='producer'
      and
        billable_size = full_size
      ;
    }
  end

  def get_headers(results)
    [
      'Max Size',
      'Min Size',
      'Avg Size',
      'Num files'
   ]
  end

  def get_types(results)
    [
      'bytes', 
      'bytes', 
      'bytes', 
      'dataint'
    ]
  end

end
