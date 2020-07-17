class CollectionsByTimeQuery < AdminQuery
  def initialize(client, path, myparams, col)
    super(client, path, myparams)
    @col = (col == 'count_files' || col == 'billable_size') ? col : 'count_files'
    @start=2013
    @end=Time.now.year
  end

  def get_filter_col
    2
  end

  def get_title
    "Collection #{@col} Over Time"
  end

  def get_sql
    %{
      select distinct
        oc.ogroup,
        oc.inv_collection_id,
        oc.collection_name,
        sum(#{@col})
      from
        owner_collections oc
      left join owner_coll_mime_use_details ocmud
        on
          oc.ogroup = ocmud.ogroup
        and
          oc.inv_collection_id = ocmud.inv_collection_id
        and
          date_added >= ?
        and
          date_added <= ?
      group by
        ogroup,
        inv_collection_id
      union
      select distinct
        oc.ogroup,
        0 as inv_collection_id,
        '-- Total --' as collection_name,
        sum(#{@col})
      from
        owner_collections oc
      left join owner_coll_mime_use_details ocmud
        on
          oc.ogroup = ocmud.ogroup
        and
          date_added >= ?
        and
          date_added <= ?
      group by
        ogroup,
        inv_collection_id
      union
      select distinct
        'ZZ' as ogroup,
        0 as inv_collection_id,
        '-- Grand Total --' collection_name,
        sum(#{@col})
      from
        owner_coll_mime_use_details
      where
        date_added >= ?
      and
        date_added <= ?
      order by
        ogroup,
        inv_collection_id
    }
  end

  def run_sql
    stmt = @client.prepare(get_sql)
    params = [
      "#{@start}-01-01", "#{@end}-12-31",
      "#{@start}-01-01", "#{@end}-12-31",
      "#{@start}-01-01", "#{@end}-12-31"
    ]
    results = stmt.execute(*params)
    types = get_types(results)
    combined_data = get_result_data(results, types)

    for yr in @start..@end do
      params = [
        "#{yr}-01-01", "#{yr}-12-31",
        "#{yr}-01-01", "#{yr}-12-31",
        "#{yr}-01-01", "#{yr}-12-31"
      ]
      results = stmt.execute(*params)
      data = get_result_data(results, types)
      data.each_with_index do |r, i|
        combined_data[i].insert(-2, r[3])
      end
    end
    {
      title: get_title,
      headers: get_headers(results),
      types: types,
      data: combined_data,
      filter_col: get_filter_col
    }
  end

  def get_headers(results)
    heads = ['Group', 'Collection Id', 'Collection Name']
    for yr in @start..@end do
      heads.push(yr)
    end
    heads.push('Total')
    heads
  end

  def get_types(results)
    types = ['ogroup', 'coll', 'name']
    for yr in @start..@end+1 do
      types.push('dataint')
    end
    types
  end

end
