# frozen_string_literal: true

# Query class - see config/reports.yml for description
class ObjectsFileCopiesNeededQuery < ObjectsQuery
  def initialize(query_factory, path, myparams)
    super
    @copies = CGI.unescape(get_param('copies', '2')).to_i
    @days = CGI.unescape(get_param('days', '2')).to_i
    subsql = %{
      select
        distinct age.inv_object_id
      #{sqlfrag_audit_files_copies(@copies)}
      where
        age.init_created < date_add(now(), INTERVAL -#{@days.to_i} DAY)
      and not exists (
        select 1
        from
          inv.inv_collections_inv_objects icio
        inner join inv.inv_collections c
          on c.id = icio.inv_collection_id
        where
          age.inv_object_id = icio.inv_object_id
        and
          c.mnemonic in ('oneshare_dataup', 'dataone_dash')
      )
      limit #{get_limit.to_i} offset #{get_offset.to_i};
    }
    stmt = @client.prepare(subsql)
    results = stmt.execute
    @ids = [-1]
    @qs = ['?']
    results.each do |r|
      @ids.push(r.values[0])
      @qs.push('?')
    end
  end

  def get_title
    "Objects with #{@copies} Copies - Older than #{@days} days (Limit #{get_limit.to_i})"
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

  def get_alternative_queries
    [
      {
        label: "Objects with #{@copies} Copies",
        url: "path=file_copies_needed&copies=#{@copies}&days=0&limit=500",
        class: 'objects'
      },
      {
        label: "Objects with #{@copies} Copies, older than 1 day",
        url: "path=file_copies_needed&copies=#{@copies}&days=1&limit=500",
        class: 'objects'
      },
      {
        label: "Objects with #{@copies} Copies, older than 2 days",
        url: "path=file_copies_needed&copies=#{@copies}&days=2&limit=500",
        class: 'objects'
      }
    ]
  end

  def page_size
    get_limit
  end

  def get_obj_limit_query
    ''
  end
end
