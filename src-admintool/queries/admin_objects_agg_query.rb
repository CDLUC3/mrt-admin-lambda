class AdminObjectsAggQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
  end

  def get_title
    "Admin Objects Aggregate"
  end

  def get_sql
    %{
      select
        ifnull(aggregate_role, 'Null_Value') as aggregate_role,
        count(*),
        case
          when aggregate_role is null and count(*) > 0 then 'INFO'
          else 'PASS'
        end as status
      from
        inv.inv_objects 
      where
        aggregate_role != 'MRT-none' 
      or
        aggregate_role is null
      group by 
        aggregate_role
      ;
    }
  end

  def get_headers(results)
    ['Aggregate Role', 'Count', 'Status']
  end

  def get_types(results)
    ['aggrole', 'data', 'status']
  end

end
