class CountObjectsQuery < AdminQuery
  def get_title
    "Object Counts by Collection"
  end

  def get_filter_col
    1
  end

  def get_sql
    if is_total
      get_total_sql
    else
      get_group_sql
    end
  end

  def get_iterative_sql
    get_campus_and_total_query
  end

  def resolve_params
    if is_total
      []
    else
      [ @itparam1 ]
    end
  end

  def get_total_sql
    %{
      select
        'ZZZ' as ogroup,
        '-- Grand Total --' as collection_name,
        sum(count_objects) as count_objects
      from
        owner_collections_objects
    }
  end


  def get_group_sql
    if @itparam2.to_i == 1
      %{
        select
          ogroup,
          collection_name,
          sum(count_objects) as count_objects
        from
          owner_collections_objects
        where
          ogroup = ?
        group by
          ogroup,
          collection_name
      }
    else
      %{
        select
          ogroup,
          '-- Total --' as collection_name,
          sum(count_objects) as count_objects
        from
          owner_collections_objects
        where
          ogroup = ?
      }
    end
  end

  def get_headers(results)
    ['Group', 'Collection', 'Object Count']
  end

  def get_types(results)
    ['ogroup', 'name', 'dataint']
  end

end
