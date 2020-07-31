class CountObjectsQuery < AdminQuery
  def get_title
    "Object Counts by Collection"
  end

  def get_filter_col
    1
  end

  def get_sql
    %{
      select
        'ZZZ' as ogroup,
        '-- Grand Total --' as collection_name,
        sum(count_objects) as count_objects
      from
        owner_collections_objects

      union

      select
        ogroup,
        collection_name,
        sum(count_objects) as count_objects
      from
        owner_collections_objects
      group by
        ogroup,
        collection_name

      union

      select
        ogroup,
        '-- Total --' as collection_name,
        sum(count_objects) as count_objects
      from
        owner_collections_objects
    }
  end

  def get_headers(results)
    ['Group', 'Collection', 'Object Count']
  end

  def get_types(results)
    ['ogroup', 'name', 'dataint']
  end

end
