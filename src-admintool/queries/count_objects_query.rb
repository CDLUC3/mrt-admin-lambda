# frozen_string_literal: true

# Query class - see config/reports.yml for description
class CountObjectsQuery < AdminQuery
  def get_title
    'Object Counts by Collection'
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

  def get_headers(_results)
    ['Group', 'CollId', 'Collection', 'Object Count']
  end

  def get_types(_results)
    %w[ogroup colllist name dataint]
  end

  def is_pie_chart
    true
  end

  def get_data_col
    3
  end
end
