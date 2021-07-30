class AdminObjectsQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
    @aggrole = get_param('aggrole', 'Null_Value')
    @aggrole = "n/a" if @aggrole == 'MRT-none' #too many values to return
    @where = @aggrole == 'Null_Value' ? "aggregate_role is null" : "aggregate_role = '#{@aggrole}'"
  end

  def get_title
    "Admin Objects: #{@aggrole}"
  end

  def get_sql
    %{
      select 
        o.id, 
        o.ark, 
        ifnull(own.name,'No name') as owner,
        own.ark as ownerark,
        o.object_type, 
        o.role, 
        o.aggregate_role, 
        erc_what, 
        o.created,
        case
          when o.aggregate_role is null then 'INFO'
          when own.ark != 'ark:/13030/j2rn30xp' then 'INFO'
          else 'PASS'
        end as status 
      from 
        inv.inv_objects o
      inner join inv.inv_owners own
        on own.id = o.inv_owner_id
      where 
        #{@where}
      order by 
        created desc
      ;
    }
  end

  def get_headers(results)
    ['Obj Id', 'Ark', 'Owner', 'OwnerArk', 'Type', 'Role', 'Aggregate Role', 'Name', 'Created', 'Status']
  end

  def get_types(results)
    ['objlist', 'ark', '', '', '', '', '', 'name', 'datetime', 'status']
  end

  def get_alternative_queries
    [
      {
        label: "Admin Object Counts by Aggegate Role", 
        url: "path=admin_obj_agg"
      },
      {
        label: "Admin Object File List for #{@aggrole}", 
        url: "path=admin_obj_files&aggrole=#{@aggrole}"
      }
    ]
  end

end
