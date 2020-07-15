class OwnerQuery < AdminQuery
  def get_title
    "Object Counts by Owner"
  end

  def get_filter_col
    1
  end

  def get_sql
    %{
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
        max('-- Total --') as collection_name,
        sum(count_objects) as count_objects
      from
        owner_collections_objects
      group by
        ogroup
      union
      select
        max('ZZZ') as ogroup,
        max('-- Grand Total --') as collection_name,
        sum(count_objects) as count_objects
      from
        owner_collections_objects
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
