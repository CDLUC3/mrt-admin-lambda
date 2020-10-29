require 'date'
class CollectionsByTimeCumulativeQuery < AdminQuery
  def initialize(query_factory, path, myparams, col, source)
    super(query_factory, path, myparams)
    @col = (col == 'count_files' || col == 'billable_size') ? col : 'count_files'
    @source_clause = (source == 'producer') ? " and source='producer'" : ""
    @ranges = []

    @end = Date.today.next_year.next_year.prev_month(Date.today.month - 1) - Date.today.mday + 1
    @start=Date.new(2013,01,01)
    rstart = @start
    while rstart < @end do
      @ranges.push([@start, rstart.next_year])
      rstart = rstart.next_year
    end

    @headers = ['Group', 'Collection Id', 'Collection Name']
    @types = ['ogroup', 'coll', 'name']
    @ranges.each do |range|
      @headers.push(range[1])
      @types.push('dataint')
    end
    @headers.push('Actual Total')
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

  def get_group_col
    0
  end

  def get_title
    "Collection Cumulative #{@col} Over Time (#{@start} - #{@end})"
  end

  def get_sql
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
        ) + (
          select
            ? * sum(#{@col}) / 730
          from
            owner_coll_mime_use_details ocmud
          where
            oc.ogroup = ocmud.ogroup
          and
            oc.inv_collection_id = ocmud.inv_collection_id
          and
            date_added >= date_add(now(), interval - 730 day)
          #{@source_clause}
        )
        as sumval
      from
        owner_collections oc
      group by
        ogroup,
        ocid,
        ocname
      order by
        ogroup,
        ocid,
        ocname
    }
  end

  def get_query_params(pstart, pend)
    x = (pend - Date.today).to_i
    x = 0 if (x < 0)
    [
      pstart, pend, x
    ]
  end

  def run_query_sql
    stmt = @client.prepare(get_sql)
    params = get_query_params(@start, Date.today)

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
