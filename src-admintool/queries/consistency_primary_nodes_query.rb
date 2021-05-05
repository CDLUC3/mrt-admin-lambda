class ConsistencyPrimaryNodeQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
  end

  def get_title
    "Primary Node Consistency"
  end

  def get_sql
    %{
      select
        n.number as nodenum,
        n.description as nodename,
        c.name as collection,
        count(inio.inv_object_id) as count
      from
        inv.inv_nodes n
      inner join
        inv.inv_nodes_inv_objects inio
      on 
        n.id = inio.inv_node_id
      and
        inio.role = 'primary'
      inner join 
        inv.inv_collections_inv_objects icio
      on 
        icio.inv_object_id = inio.inv_object_id
      inner join
        inv.inv_collections c
      on 
        c.id = icio.inv_collection_id
      where
        n.number not in (3041, 9501, 9502)
      group by
        nodenum,
        nodename,
        collection
      ; 
    }
  end

  def get_headers(results)
    ['Primary Node Num', 'Node Desc', 'Collection', 'Object Count']
  end

  def get_types(results)
    ['', 'name', 'name', 'dataint']
  end

  def get_group_col
    1
  end
end
