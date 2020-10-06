class OwnerQuery < AdminQuery
  def get_title
    "File Counts by Owner"
  end

  def get_filter_col
    2
  end

  def get_base_sql
    %{
      select
        ogroup,
        inv_owner_id as owner_id,
        own_name,
        sum(count_files) files,
        sum(billable_size) size
      from
        owner_coll_mime_use_details
      group by
        ogroup,
        owner_id,
        own_name
    }
  end

  def get_union_sql
    %{
      union
      select
        ogroup,
        max(0) as owner_id,
        max('-- Total --') as own_name,
        sum(count_files) files,
        sum(billable_size) size
      from
        owner_coll_mime_use_details
      group by
        ogroup
        union
      select
        max('ZZZ') as ogroup,
        max(0) as owner_id,
        max('-- Grand Total --') as own_name,
        sum(count_files) files,
        sum(billable_size) size
      from
        owner_coll_mime_use_details
    }
  end 

  def get_order_sql
    %{
      order by
        ogroup,
        own_name
    }
  end

  def get_headers(results)
    ['Group', 'Owner Id','Owner', 'File Count', 'Billable Size']
  end

  def get_types(results)
    ['ogroup', 'own', 'name', 'dataint', 'dataint']
  end

end
