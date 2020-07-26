require 'date'
class CollectionsByTimeQuery < AdminQuery
  def initialize(query_factory, path, myparams, col)
    super(query_factory, path, myparams)
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

  def get_iterative_sql
    %{
      select
        distinct ogroup,
        inv_collection_id as ocid
      from
        owner_collections
      union
      select
        distinct ogroup,
        0 as ocid
      from
        owner_collections
      union
      select
        'ZZ' as ogroup,
        0 as ocid
      order by
        ogroup,
        ocid
    }
  end

  def get_sql
    if is_total
      get_total_sql
    else
      get_group_sql
    end
  end

  def get_total_sql
    %{
      select distinct
        'ZZ' as og,
        0 as ocid,
        '-- Grand Total --' as ocname,
        sum(#{@col})
      from
        owner_coll_mime_use_details
      where
        date_added >= ?
      and
        date_added <= ?
    }
  end

  def get_group_sql
    if @itparam2 != 0 and @itparam2 != '0'
      %{
        select distinct
          oc.ogroup as og,
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
              date_added <= ?
          ) as sumval
        from
          owner_collections oc
        where
          ogroup = ?
        and
          oc.inv_collection_id = ?
      }
    else
      %{
        select distinct
          oc.ogroup as og,
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
              date_added <= ?
          ) as sumval
        from
          owner_collections oc
        where
          ogroup = ?
      }
    end
  end

  def get_query_params(pstart, pend, pitparam1, pitparam2)
    if is_total
      [ pstart, pend ]
    elsif pitparam2 == 0 or pitparam2 == '0'
      [ pstart, pend, pitparam1 ]
    else
      [ pstart, pend, pitparam1, pitparam2 ]
    end
  end

  def run_query_sql
    stmt = @client.prepare(get_sql)
    params = get_query_params(@start, @end, @itparam1, @itparam2)

    results = stmt.execute(*params)
    types = get_types(results)
    combined_data = get_result_data(results, types)

    @ranges.each do |range|
      params = get_query_params(range[0], range[1], @itparam1, @itparam2)
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
