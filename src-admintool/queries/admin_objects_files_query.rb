class AdminObjectsFilesQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
    @aggrole = get_param('aggrole', 'Null_Value')
    @aggrole = "n/a" if @aggrole == 'MRT-none' #too many values to return
    @where = @aggrole == 'Null_Value' ? "aggregate_role is null" : "aggregate_role = '#{@aggrole}'"
  end

  def get_title
    "Admin Objects with File Listing"
  end

  def get_sql
    %{
      select 
        o.id, 
        o.ark, 
        o.object_type, 
        o.role, 
        o.aggregate_role, 
        o.erc_what, 
        o.created,
        f.source,
        f.pathname,
        f.full_size
      from 
        inv.inv_objects o 
      inner join inv.inv_versions v
        on o.id = v.inv_object_id 
        and o.version_number = v.number
      inner join inv.inv_files f
        on o.id = f.inv_object_id
        and v.id = f.inv_version_id
      where 
        #{@where}
      order by 
        created desc,
        source,
        pathname
      ;
    }
  end

  def get_headers(results)
    ['Obj Id', 'Ark', 'Type', 'Role', 'Aggregate Role', 'Name', 'Created', 'Source', 'Path', 'File Size']
  end

  def get_types(results)
    ['objlist', 'ark', '', '', '', 'name', 'datetime', '', 'name', 'bytes']
  end

  def get_alternative_queries
    [
      {
        label: "Admin Object Counts by Aggegate Role", 
        url: "path=admin_obj_agg"
      },
      {
        label: "Admin Object List for #{@aggrole}", 
        url: "path=admin_obj&aggrole=#{@aggrole}"
      }
    ]
  end

end
