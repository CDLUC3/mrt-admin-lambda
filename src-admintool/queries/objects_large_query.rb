# frozen_string_literal: true

# Query class - see config/reports.yml for description
class ObjectsLargeQuery < ObjectsQuery
  def initialize(query_factory, path, myparams)
    super
    subsql = %(
      select
        inv_object_id
      from
        object_size os
      inner join
        inv.inv_objects o
      on
        os.inv_object_id = o.id
      order by
        billable_size desc
      limit #{get_limit.to_i} offset #{get_offset.to_i};
    )
    stmt = @client.prepare(subsql)
    results = stmt.execute
    @ids = [-1]
    @qs = ['?']
    results.each do |r|
      @ids.push(r.values[0])
      @qs.push('?')
    end
    @sort = 'size'
  end

  def get_title
    'Largest Objects'
  end

  def get_params
    @ids
  end

  # @qs was generated from a database query, so it is sanitized
  def get_where
    "where o.id in (#{@qs.join(',')})"
  end

  def get_max_limit
    500
  end

  def page_size
    get_limit
  end

  def get_obj_limit_query
    ''
  end

  def bytes_unit
    '1000000000000'
  end
end
