class AdminCollectionsQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
  end

  def get_title
    "Admin Collections Report"
  end

  def get_sql
    %{
      select 
        c.id,
        c.ark as collark,
        c.name,
        c.mnemonic,
        o.ark as objark,
        o.aggregate_role,
        o.created,
        case
          when c.inv_object_id is null then 'INFO'
          when c.ark != o.ark then 'INFO'
          when c.mnemonic is null then 'INFO'
          else 'PASS'
        end as status
      from 
        inv.inv_collections c
      left join inv.inv_objects o
        on c.inv_object_id = o.id
      where
        o.aggregate_role != 'MRT-collection' 
      or 
        o.aggregate_role is null 
      or 
        mnemonic is null
      or
        c.ark != o.ark
      order by 
        o.created desc
      ;
    }
  end

  def get_headers(results)
    ['Coll Id', 'Coll Ark', 'Coll Name', 'Mnemonic', 'Obj Ark', 'Aggregate Role', 'Created', 'Status']
  end

  def get_types(results)
    ['', 'ark', 'name', 'mnemonic', '', '', 'datetime', 'status']
  end

end
