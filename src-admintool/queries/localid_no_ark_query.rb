class LocalidNoIdQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
  end

  def get_title
    "Local Ids with No Ark Query"
  end

  def get_sql
    %{
      SELECT 
        replace(loc.inv_owner_ark, '%2F', '/') as ownark, 
        own.name, 
        count(*),
        'INFO' as status 
      FROM 
        inv.inv_localids loc 
      LEFT JOIN 
        inv.inv_objects o ON o.ark = loc.inv_object_ark
      LEFT JOIN 
        inv.inv_owners own ON replace(loc.inv_owner_ark, '%2F', '/') = own.ark 
      WHERE 
        o.ark IS null
      group by 
        ownark, own.name
      ; 
    }
  end

  def get_headers(results)
    ['Owner Ark', 'Owner Name', 'Count', 'Status']
  end

  def get_types(results)
    ['owner', 'name', 'data', 'status']
  end
  
  def init_status
    :PASS
  end

end
