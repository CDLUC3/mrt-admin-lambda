# frozen_string_literal: true

require 'date'

# Query class - see config/reports.yml for description
class CollectionObjectsByTimeQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
    @interval = get_param('interval', '')
    @interval = @interval == 'years' || @interval == 'days' || @interval == 'weeks' ? @interval : 'years'
    @ranges = []

    if @interval == 'days'
      @end = Date.today + 1
      @start = @end - 7
      rstart = @start
      while rstart < @end
        @ranges.push([rstart, rstart + 1])
        rstart += 1
      end
    elsif @interval == 'weeks'
      @end = Date.today - Date.today.cwday + 7
      @start = @end - 28
      rstart = @start
      while rstart < @end
        @ranges.push([rstart, rstart + 7])
        rstart += 7
      end
    else
      @end = Date.today.next_year.prev_month(Date.today.month - 1) - Date.today.mday + 1
      @start = Date.new(2013, 0o1, 0o1)
      rstart = @start
      while rstart < @end
        @ranges.push([rstart, rstart.next_year])
        rstart = rstart.next_year
      end
    end
    @headers = ['Group', 'Collection Id', 'Collection Name']
    @types = %w[ogroup colllist name]
    @ranges.each do |range|
      @headers.push(range[0])
      @types.push('dataint')
    end
    @headers.push('Total')
    @types.push('dataint')
  end

  def get_headers(_results)
    @headers
  end

  def get_types(_results)
    @types
  end

  def get_filter_col
    2
  end

  def get_group_col
    0
  end

  def get_title
    "Collection Objects Over Time (#{@start} - #{@end})"
  end

  def get_sql
    %{
      select distinct
        oc.ogroup as ogroup,
        oc.inv_collection_id as ocid,
        oc.collection_name as ocname,
        (
          select
            count(inv_object_id)
          from
            inv.inv_collections_inv_objects icio
          inner join inv.inv_objects o
            on o.id = icio.inv_object_id
          where
            oc.inv_collection_id = icio.inv_collection_id
          and
            o.created >= ?
          and
            o.created < ?
        ) as sumval
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
    [
      pstart, pend
    ]
  end

  def run_query_sql
    stmt = @client.prepare(get_sql)
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
