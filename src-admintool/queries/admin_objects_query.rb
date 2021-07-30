class AdminObjectsQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
    @aggrole = get_param('aggrole', '')
    @where = @aggrole.empty? ? "aggregate_role is null" : "aggregate_role = '#{@aggrole}'"
  end

  def get_title
    "Admin Objects"
  end

  def get_sql
    %{
      select 
        id, 
        ark, 
        object_type, 
        role, 
        aggregate_role, 
        erc_what, 
        created 
      from 
        inv.inv_objects 
      where 
        #{@where}
        and
          aggregate_role != 'MRT-none'
      order by 
        created desc
      ;
    }
  end

  def get_headers(results)
    ['Obj Id', 'Ark', 'Type', 'Role', 'Aggregate Role', 'Name', 'Created']
  end

  def get_types(results)
    ['objlist', 'ark', '', '', '', 'name', 'datetime']
  end

  def get_alternative_queries
    [
      {
        label: "Admin Object Counts by Aggegate Role", 
        url: "path=admin_obj_agg"
      }
    ]
  end

end
