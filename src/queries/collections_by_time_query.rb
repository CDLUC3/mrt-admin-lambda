require 'date'
class CollectionsByTimeQuery < AdminQuery
  def initialize(client, path, myparams, col)
    super(client, path, myparams)
    @col = (col == 'count_files' || col == 'billable_size') ? col : 'count_files'
    @interval = myparams.key?('interval') ? myparams['interval'].strip : ''
    @interval = (@interval == 'years' || @interval == 'days' || @interval == 'weeks') ? @interval : 'years'
    @ranges = []

    if (@interval == 'days')
      @end = Date.today + 1
      @start=@end - 7
      rstart = @start
      while rstart < @end do
        @ranges.push([rstart, rstart+1])
        rstart = rstart + 1
      end
    elsif (@interval == 'weeks')
      @end = Date.today - Date.today.cwday + 7
      @start=@end - 28
      rstart = @start
      while rstart < @end do
        @ranges.push([rstart, rstart+7])
        rstart = rstart + 7
      end
    else
      @end = Date.today.next_year.prev_month(Date.today.month - 1) - Date.today.mday + 1
      @start=Date.new(2013,01,01)
      rstart = @start
      while rstart < @end do
        @ranges.push([rstart, rstart.next_year])
        rstart = rstart.next_year
      end
    end
    @headers = ['Group', 'Collection Id', 'Collection Name']
    @types = ['ogroup', 'coll', 'name']
    @ranges.each do |range|
      @headers.push(range[0])
      @types.push('dataint')
    end
    @headers.push('Total')
    @types.push('dataint')
  end

  def get_headers(results)
    @headers
  end

  def get_types(results)
    @types
  end

  def get_filter_col
    2
  end

  def get_title
    "Collection #{@col} Over Time (#{@start} - #{@end})"
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
      @start, @end,
      @start, @end,
      @start, @end
    ]
    results = stmt.execute(*params)
    types = get_types(results)
    combined_data = get_result_data(results, types)

    @ranges.each do |range|
      params = [
        range[0], range[1],
        range[0], range[1],
        range[0], range[1]
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


end
