class CountObjectsQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
  end

  def get_title
    "Object Counts by Collection"
  end

  def get_filter_col
    1
  end

  def get_group_col
    0
  end

  def get_sql
    %{
      select
        ogroup,
        inv_collection_id,
        collection_name,
        sum(count_objects) as count_objects
      from
        owner_collections_objects
      group by
        ogroup,
        inv_collection_id,
        collection_name
    }
  end

  def get_headers(results)
    ['Group', 'CollId', 'Collection', 'Object Count']
  end

  def get_types(results)
    ['ogroup', 'colllist', 'name', 'dataint']
  end

end
