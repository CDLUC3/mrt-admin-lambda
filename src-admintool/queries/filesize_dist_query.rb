class FilesizeDistributionQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
  end

  def get_title
    "Producer File size distribution summary"
  end

  def get_iterative_sql
    %{
    select 
      'Under 1k', 
      0, 
      1000
    union
    select 
      '1K - 1M', 
      1000, 
      1000000
    union
    select 
      '1M - 10M', 
      1000000, 
      10000000
    union
    select 
      '10M-100M', 
      10000000, 
      100000000
    union
    select 
      '100M-1G', 
      100000000, 
      1000000000
    union
    select 
      '1G-10G', 
      1000000000, 
      10000000000
    union
    select 
      '10G-100G', 
      10000000000, 
      100000000000
    union
    select 
      '100G-200G', 
      100000000000, 
      200000000000
    union
    select 
      '200G-300G', 
      200000000000, 
      300000000000
    union
    select 
      '300G-400G', 
      300000000000, 
      400000000000
    }
  end

  def get_sql
    %{
      select
        ?,
        count(*)
      from
        inv.inv_files
      where
        source='producer'
      and
        billable_size >= ?
      and
        billable_size < ?
      and 
        billable_size = full_size
      ;
    }
  end

  def get_headers(results)
    [
      'Label',
      'File Count'
   ]
  end

  def get_types(results)
    [
      '', 
      'dataint'
    ]
  end

end
