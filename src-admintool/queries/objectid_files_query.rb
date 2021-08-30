class ObjectIdFilesQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
    @id = myparams.fetch("id", 0).to_i
  end

  def get_title
    "Object File Listing for #{@id}"
  end

  def get_sql
    %{
      select 
        o.ark, 
        v.number,
        f.source,
        f.pathname,
        f.full_size,
        f.created
      from 
        inv.inv_objects o 
      inner join inv.inv_versions v
        on o.id = v.inv_object_id 
      inner join inv.inv_files f
        on o.id = f.inv_object_id
        and v.id = f.inv_version_id
      where 
        o.id = ?
      and
        f.billable_size = f.full_size
      order by 
        f.created desc,
        source,
        pathname
      ;
    }
  end

  def get_params
    [@id]
  end

  def get_headers(results)
    ['Ark', 'Version', 'Source', 'Path', 'File Size', 'Created']
  end

  def get_types(results)
    ['ark', '', '', 'name', 'bytes', 'datetime']
  end

end
