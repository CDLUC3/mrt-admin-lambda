class FilesizeQuery < AdminQuery
  def get_title
    "File size summary"
  end

  def get_sql
    %{
      select
        max(billable_size) max_size,
        min(billable_size) min_size,
        avg(billable_size) avg_size,
        count(*) num_files,
        sum(if(billable_size < 1000, 1, 0)) num_under_1k,
        sum(if(billable_size >= 1000 and billable_size < 1000000, 1, 0)) num_1k_to_1m,
        sum(if(billable_size >= 1000000 and billable_size < 10000000, 1, 0)) num_1m_to_10m,
        sum(if(billable_size >= 10000000 and billable_size < 100000000, 1, 0)) num_10m_to_100m,
        sum(if(billable_size >= 100000000 and billable_size < 1000000000, 1, 0)) num_100m_to_1g,
        sum(if(billable_size >= 1000000000 and billable_size < 10000000000, 1, 0)) num_1g_to_10g,
        sum(if(billable_size >= 10000000000 and billable_size < 100000000000, 1, 0)) num_10g_to_100g,
        sum(if(billable_size >= 100000000000, 1, 0)) num_100g_plus
      from
        inv_files
      where
        source='producer'
      ;
    }
  end

  def get_headers(results)
    [
      'Max Size',
      'Min Size',
      'Avg Size',
      'Num files',
      'Num (<1K)',
      'Num (1K-1M)',
      'Num (1M-10M)',
      'Num (10M-100M)',
      'Num (100M-1G)',
      'Num (1G-10G)',
      'Num (10G-100G)',
      'Num (>100G)'
   ]
  end

  def get_types(results)
    [
      'dataint', 
      'dataint', 
      'dataint', 
      'dataint', 
      'dataint', 
      'dataint', 
      'dataint', 
      'dataint', 
      'dataint', 
      'dataint', 
      'dataint', 
      'dataint'
    ]
  end

end
