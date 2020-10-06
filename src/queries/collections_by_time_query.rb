require 'date'
class CollectionsByTimeQuery < AdminQuery
  def initialize(query_factory, path, myparams, col, source)
    super(query_factory, path, myparams)
    @col = (col == 'count_files' || col == 'billable_size') ? col : 'count_files'
    @source_clause = (source == 'producer') ? " and source='producer'" : ""
    @interval = get_param('interval', '')
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

  def get_base_sql
    %{
      select distinct
        oc.ogroup as ogroup,
        oc.inv_collection_id as ocid,
        oc.collection_name as ocname,
        (
          select
            sum(#{@col})
          from
            owner_coll_mime_use_details ocmud
          where
            oc.ogroup = ocmud.ogroup
          and
            oc.inv_collection_id = ocmud.inv_collection_id
          and
            date_added >= ?
          and
            date_added < ?
          #{@source_clause}
        ) as sumval
      from
        owner_collections oc
      group by
        ogroup,
        ocid,
        ocname
     }
  end
  
  def get_union_sql
    %{
      union
      select distinct
        'ZZ' as ogroup,
        0 as ocid,
        '-- Grand Total --' as ocname,
        sum(#{@col})
      from
        owner_coll_mime_use_details
      where
        date_added >= ?
      and
        date_added < ?
      #{@source_clause}

      union

      select distinct
        oc.ogroup as ogroup,
        0 as ocid,
        '-- Total --' as ocname,
        (
          select
            sum(#{@col})
          from
            owner_coll_mime_use_details ocmud
          where
            oc.ogroup = ocmud.ogroup
          and
            date_added >= ?
          and
            date_added < ?
          #{@source_clause}
        ) as sumval
      from
        owner_collections oc
      group by
        ogroup,
        ocid,
        ocname
    }
  end 

  def get_order_sql
    %{
      order by
        ogroup,
        ocid,
        ocname
    }
  end

  def get_query_params(pstart, pend)
    if @totals == 'Y'
      [
        pstart, pend,
        pstart, pend,
        pstart, pend
      ]
    else
      [
        pstart, pend
      ]
    end
  end

  def run_query_sql
    stmt = @client.prepare(get_sql(@totals == 'Y'))
    params = get_query_params(@start, @end)

    results = stmt.execute(*params)
    types = get_types(results)
    combined_data = get_result_data(results, types)

    @ranges.each do |range|
      params = get_query_params(range[0], range[1])
      results = stmt.execute(*params)
      data = get_result_data(results, types)
      data.each_with_index do |r, i|
        combined_data[i].insert(-2, r[3])
      end
    end
    format_result_json(types, combined_data, get_headers(results))
  end


end
