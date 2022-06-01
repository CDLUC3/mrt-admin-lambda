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

  def is_pie_chart
    true
  end

  def get_pie_chart(data, types, headers)
    cmap = {}

    data.each do |r|
      cmap[r[0]] = cmap.fetch(r[0], 0) + r[3]
    end

    clabels = []
    cdata = []

    cmap.keys.each do |k|
      clabels.append(k)
      cdata.append(cmap[k])
    end

    {
      type: 'pie',
      data: {
        labels: clabels,
        datasets: [{
          label: get_title,
          data: cdata,
          backgroundColor: colors(cdata.length)
        }]
      },
      options: {}
    };

  end

end
