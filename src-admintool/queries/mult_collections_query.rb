class MultipleCollectionsQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
  end

  def report_name
    "mult_coll"
  end

  def get_title
    "Object Counts in Multiple Collections"
  end

  def get_sql
    %{
      select 
        year(o.created) as year,
        count(*) as count,
        case
          when year(now()) - year(o.created) <= 1 then 'WARN'
          else 'SKIP'
        end as status 
      from
        inv.inv_objects o
      where o.id in (
        select
          inv_object_id
        from 
          inv.inv_collections_inv_objects
        group by
          inv_object_id
        having 
          count(*) > 1
      )
      and
        o.aggregate_role = 'MRT-none'
      group by
        year
      ; 
    }
  end

  def get_headers(results)
    ['Year Added', 'Object Count', 'Status']
  end

  def get_types(results)
    ['', 'dataint', 'status']
  end
  
  def init_status
    :PASS
  end

  def get_alternative_queries
    [
      {
        label: "Object List - Objects in Multiple Collections", 
        url: "path=object_mult_coll&limit=500"
      }
    ]
  end

end
