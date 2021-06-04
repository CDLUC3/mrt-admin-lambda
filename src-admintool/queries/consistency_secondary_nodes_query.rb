class ConsistencySecondaryNodeQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
  end

  def get_title
    "Collections with Non-standard Secondary Nodes (Not Glacier+Wasabi or SDSC+Wasabi)"
  end

  def get_sql
    %{
      select
        c.name as collection,
        count(icin.inv_node_id) as ncount,
        group_concat(number order by number) as nodes,
        case
          when (
            select
              aggregate_role
            from
              inv.inv_objects o
            where
              o.id = c.inv_object_id
          ) = 'MRT-service-level-agreement'
            then 'PASS'
          when c.name like 'Merritt %' then 'WARN'
          else 'FAIL'
        end as status
      from
        inv.inv_collections_inv_nodes icin
      inner join
        inv.inv_collections c
      on 
        c.id = icin.inv_collection_id
      inner join
        inv.inv_nodes n
      on
        n.id = icin.inv_node_id
      group by
        collection
      having
        nodes not in ('2001,6001', '2001,9501', '2002,6001', '2002,9502')
      ; 
    }
  end

  def get_headers(results)
    ['Collection', 'Sec Node Count', 'Sec Node List', 'Status']
  end

  def get_types(results)
    ['name', 'dataint', 'name','status']
  end
  
  def init_status
    :PASS
  end

end
