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
        aggregate_role,
        count(*)
      from
        inv.inv_objects 
      where
        aggregate_role != 'MRT-none'
      group by 
        aggregate_role
      ;
    }
  end

  def get_headers(results)
    ['Aggregate Role', 'Count']
  end

  def get_types(results)
    ['aggrole', 'data']
  end

  def get_alternative_queries
    [
      {
        label: "Admin Objects with Null Aggegate Role", 
        url: "path=admin_obj"
      }
    ]
  end

end
