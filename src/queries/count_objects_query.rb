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

  def resolve_params
    [ @itparam1, @itparam1 ]
  end

  def get_total_sql
    %{
      select
        max('ZZZ') as ogroup,
        max('-- Grand Total --') as collection_name,
        sum(count_objects) as count_objects
      from
        owner_collections_objects
    }
  end

  def get_group_sql
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
      union
      select
        ogroup,
        max('-- Total --') as collection_name,
        sum(count_objects) as count_objects
      from
        owner_collections_objects
      where
        ogroup = ?
      order by
        ogroup,
        collection_name
    }
  end

  def get_headers(results)
    ['Group', 'Collection', 'Object Count']
  end

  def get_types(results)
    ['ogroup', 'name', 'dataint']
  end

end
